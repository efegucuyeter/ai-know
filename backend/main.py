from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import List

import crud
import schemas
from database import get_db, create_tables
from auth import authenticate_user, create_access_token, get_current_user, get_current_admin_user, ACCESS_TOKEN_EXPIRE_MINUTES
import ai

# Veritabanı tablolarını oluştur
create_tables()

app = FastAPI(title="Quiz App API", version="1.0.0")

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Geliştirme için, production'da spesifik domainler kullanın
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static dosyalar için
app.mount("/static", StaticFiles(directory="../web"), name="static")

# Auth endpoints
@app.post("/api/auth/register", response_model=schemas.User)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # Email kontrolü
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    
    # Username kontrolü
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(
            status_code=400,
            detail="Username already taken"
        )
    
    return crud.create_user(db=db, user=user)

@app.post("/api/auth/login", response_model=schemas.Token)
def login(user_credentials: schemas.UserLogin, db: Session = Depends(get_db)):
    user = authenticate_user(db, user_credentials.email, user_credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/api/auth/me", response_model=schemas.User)
def read_users_me(current_user: schemas.User = Depends(get_current_user)):
    return current_user

@app.put("/api/auth/me", response_model=schemas.User)
def update_user_profile(
    user_update: schemas.UserUpdate,
    db: Session = Depends(get_db),
    current_user: schemas.User = Depends(get_current_user)
):
    return crud.update_user(db=db, user_id=current_user.id, user_update=user_update)

@app.post("/api/auth/change-password")
def change_password(
    password_request: schemas.PasswordChangeRequest,
    db: Session = Depends(get_db),
    current_user: schemas.User = Depends(get_current_user)
):
    result = crud.change_user_password(
        db=db,
        user_id=current_user.id,
        current_password=password_request.current_password,
        new_password=password_request.new_password
    )
    
    if result is None:
        raise HTTPException(status_code=404, detail="User not found")
    elif result is False:
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    else:
        return {"message": "Password changed successfully"}

# Category endpoints
@app.get("/api/categories", response_model=List[schemas.CategoryWithCount])
def read_categories(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    categories = crud.get_categories_with_quiz_counts(db, skip=skip, limit=limit)
    
    # Convert to list and add flag category
    categories_list = []
    
    # Normal kategorileri ekle
    for cat in categories:
        category_with_count = schemas.CategoryWithCount(
            id=cat.id,
            name=cat.name,
            description=cat.description,
            image_url=cat.image_url,
            quiz_count=cat.quiz_count
        )
        categories_list.append(category_with_count)
    
    # Bayraklar kategorisini ekle (eğer zaten yoksa)
    if not any(cat.id == 999 for cat in categories_list):
        # Bayrak quiz sayısını hesapla (şu anda 1 tane var)
        flag_category = schemas.CategoryWithCount(
            id=999,
            name="Bayraklar",
            description="Dünya ülkelerinin bayraklarını tanıma quizleri",
            image_url="https://flagcdn.com/w320/tr.png",
            quiz_count=1  # Flag quiz
        )
        categories_list.insert(0, flag_category)
    
    return categories_list

@app.post("/api/categories", response_model=schemas.Category)
def create_category(
    category: schemas.CategoryCreate,
    db: Session = Depends(get_db),
    current_user: schemas.User = Depends(get_current_user)
):
    return crud.create_category(db=db, category=category)

# Quiz endpoints
@app.get("/api/quizzes")
def read_quizzes(
    skip: int = 0,
    limit: int = 100,
    category_id: int = None,
    db: Session = Depends(get_db)
):
    quiz_summaries = crud.get_quiz_summaries(db, skip=skip, limit=limit, category_id=category_id)
    
    # Quiz summary formatını düzenle
    formatted_quizzes = []
    for quiz in quiz_summaries:
        formatted_quiz = {
            "id": quiz.id,
            "title": quiz.title,
            "description": quiz.description,
            "difficulty": quiz.difficulty,
            "image_url": quiz.image_url,
            "category": {
                "id": quiz.category_id,
                "name": quiz.category_name
            },
            "question_count": quiz.question_count,
            "creator_username": quiz.creator_username
        }
        formatted_quizzes.append(formatted_quiz)
    
    # Bayrak Quiz'ini her zaman en başa ekle (eğer kategori filtresi yoksa veya bayrak kategorisi seçiliyse)
    if category_id is None or category_id == 999:
        flag_quiz = {
            "id": "flag_quiz",
            "title": "🏳️ Dünya Bayrakları Quiz",
            "description": "10 soruluk bayrak tanıma testi. Her doğru cevap 10 puan değerinde.",
            "difficulty": "Orta",
            "image_url": "https://flagcdn.com/w320/tr.png",
            "category": {
                "id": 999,
                "name": "Bayraklar"
            },
            "question_count": 10,
            "creator_username": "Ahmet Yılmaz"
        }
        formatted_quizzes.insert(0, flag_quiz)
    
    return formatted_quizzes

@app.get("/api/quizzes/{quiz_id}", response_model=schemas.Quiz)
def read_quiz(quiz_id: int, db: Session = Depends(get_db)):
    db_quiz = crud.get_quiz_with_questions(db, quiz_id=quiz_id)
    if db_quiz is None:
        raise HTTPException(status_code=404, detail="Quiz not found")
    return db_quiz

@app.post("/api/quizzes", response_model=schemas.Quiz)
def create_quiz(
    quiz: schemas.QuizCreate,
    db: Session = Depends(get_db),
    current_user: schemas.User = Depends(get_current_user)
):
    return crud.create_quiz(db=db, quiz=quiz, creator_id=current_user.id)

# Quiz attempt endpoints
@app.post("/api/quizzes/{quiz_id}/attempt", response_model=schemas.QuizResult)
def submit_quiz_attempt(
    quiz_id: int,
    attempt: schemas.QuizAttemptCreate,
    db: Session = Depends(get_db),
    current_user: schemas.User = Depends(get_current_user)
):
    # Quiz ID'yi attempt'e ekle
    attempt.quiz_id = quiz_id
    
    db_attempt = crud.create_quiz_attempt(db=db, attempt=attempt, user_id=current_user.id)
    if db_attempt is None:
        raise HTTPException(status_code=404, detail="Quiz not found")
    
    # Sonucu hesapla
    percentage = (db_attempt.correct_answers / db_attempt.total_questions) * 100 if db_attempt.total_questions > 0 else 0
    
    return schemas.QuizResult(
        score=db_attempt.score,
        total_questions=db_attempt.total_questions,
        correct_answers=db_attempt.correct_answers,
        time_taken=db_attempt.time_taken,
        percentage=percentage
    )

@app.get("/api/user/attempts", response_model=List[schemas.QuizAttempt])
def read_user_attempts(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: schemas.User = Depends(get_current_user)
):
    return crud.get_user_attempts(db, user_id=current_user.id, skip=skip, limit=limit)

# Leaderboard endpoint
@app.get("/api/leaderboard", response_model=schemas.PaginatedLeaderboard)
def read_leaderboard(page: int = 1, limit: int = 10, db: Session = Depends(get_db)):
    return crud.get_leaderboard_paginated(db, page=page, limit=limit)

# Statistics endpoint
@app.get("/api/statistics", response_model=schemas.AppStatistics)
def get_statistics(db: Session = Depends(get_db)):
    return crud.get_app_statistics(db)

# AI Question Generation endpoint
@app.post("/api/ai/generate-questions", response_model=schemas.AIQuestionResponse)
def generate_ai_questions(
    request: schemas.AIQuestionRequest,
    current_user: schemas.User = Depends(get_current_user)
):
    return ai.generate_ai_questions(
        category=request.category,
        difficulty=request.difficulty,
        question_count=request.question_count,
        topic=request.topic,
        language=getattr(request, 'language', 'tr')  # Default to Turkish if not provided
    )

# Flag Quiz endpoints
@app.get("/api/flag-quiz")
def get_flag_quiz():
    """Get the flag quiz"""
    return {
        "id": "flag_quiz",
        "title": "Bayrak Quiz",
        "description": "10 soruluk bayrak quiz'i. Her doğru cevap 10 puan değerinde.",
        "difficulty": "Orta",
        "image_url": "https://flagcdn.com/w320/tr.png",
        "category": {
            "id": 999,
            "name": "Bayraklar"
        },
        "question_count": 10,
        "creator_username": "System",
        "time_limit": 300
    }

@app.post("/api/flag-quiz/start")
def start_flag_quiz(current_user: schemas.User = Depends(get_current_user)):
    """Start a new flag quiz session"""
    import random
    
    countries = [
        {"code": "AF", "name": "Afghanistan"},
        {"code": "AL", "name": "Albania"},
        {"code": "DZ", "name": "Algeria"},
        {"code": "AR", "name": "Argentina"},
        {"code": "AM", "name": "Armenia"},
        {"code": "AU", "name": "Australia"},
        {"code": "AT", "name": "Austria"},
        {"code": "AZ", "name": "Azerbaijan"},
        {"code": "BS", "name": "Bahamas"},
        {"code": "BH", "name": "Bahrain"},
        {"code": "BD", "name": "Bangladesh"},
        {"code": "BB", "name": "Barbados"},
        {"code": "BY", "name": "Belarus"},
        {"code": "BE", "name": "Belgium"},
        {"code": "BZ", "name": "Belize"},
        {"code": "BJ", "name": "Benin"},
        {"code": "BT", "name": "Bhutan"},
        {"code": "BO", "name": "Bolivia"},
        {"code": "BA", "name": "Bosnia and Herzegovina"},
        {"code": "BW", "name": "Botswana"},
        {"code": "BR", "name": "Brazil"},
        {"code": "BN", "name": "Brunei"},
        {"code": "BG", "name": "Bulgaria"},
        {"code": "BF", "name": "Burkina Faso"},
        {"code": "BI", "name": "Burundi"},
        {"code": "KH", "name": "Cambodia"},
        {"code": "CM", "name": "Cameroon"},
        {"code": "CA", "name": "Canada"},
        {"code": "CV", "name": "Cape Verde"},
        {"code": "CF", "name": "Central African Republic"},
        {"code": "TD", "name": "Chad"},
        {"code": "CL", "name": "Chile"},
        {"code": "CN", "name": "China"},
        {"code": "CO", "name": "Colombia"},
        {"code": "KM", "name": "Comoros"},
        {"code": "CG", "name": "Congo"},
        {"code": "CR", "name": "Costa Rica"},
        {"code": "HR", "name": "Croatia"},
        {"code": "CU", "name": "Cuba"},
        {"code": "CY", "name": "Cyprus"},
        {"code": "CZ", "name": "Czech Republic"},
        {"code": "DK", "name": "Denmark"},
        {"code": "DJ", "name": "Djibouti"},
        {"code": "DM", "name": "Dominica"},
        {"code": "DO", "name": "Dominican Republic"},
        {"code": "EC", "name": "Ecuador"},
        {"code": "EG", "name": "Egypt"},
        {"code": "SV", "name": "El Salvador"},
        {"code": "GQ", "name": "Equatorial Guinea"},
        {"code": "ER", "name": "Eritrea"},
        {"code": "EE", "name": "Estonia"},
        {"code": "ET", "name": "Ethiopia"},
        {"code": "FJ", "name": "Fiji"},
        {"code": "FI", "name": "Finland"},
        {"code": "FR", "name": "France"},
        {"code": "GA", "name": "Gabon"},
        {"code": "GM", "name": "Gambia"},
        {"code": "GE", "name": "Georgia"},
        {"code": "DE", "name": "Germany"},
        {"code": "GH", "name": "Ghana"},
        {"code": "GR", "name": "Greece"},
        {"code": "GD", "name": "Grenada"},
        {"code": "GT", "name": "Guatemala"},
        {"code": "GN", "name": "Guinea"},
        {"code": "GW", "name": "Guinea-Bissau"},
        {"code": "GY", "name": "Guyana"},
        {"code": "HT", "name": "Haiti"},
        {"code": "HN", "name": "Honduras"},
        {"code": "HU", "name": "Hungary"},
        {"code": "IS", "name": "Iceland"},
        {"code": "IN", "name": "India"},
        {"code": "ID", "name": "Indonesia"},
        {"code": "IR", "name": "Iran"},
        {"code": "IQ", "name": "Iraq"},
        {"code": "IE", "name": "Ireland"},
        {"code": "IL", "name": "Israel"},
        {"code": "IT", "name": "Italy"},
        {"code": "JM", "name": "Jamaica"},
        {"code": "JP", "name": "Japan"},
        {"code": "JO", "name": "Jordan"},
        {"code": "KZ", "name": "Kazakhstan"},
        {"code": "KE", "name": "Kenya"},
        {"code": "KI", "name": "Kiribati"},
        {"code": "KP", "name": "North Korea"},
        {"code": "KR", "name": "South Korea"},
        {"code": "KW", "name": "Kuwait"},
        {"code": "KG", "name": "Kyrgyzstan"},
        {"code": "LA", "name": "Laos"},
        {"code": "LV", "name": "Latvia"},
        {"code": "LB", "name": "Lebanon"},
        {"code": "LS", "name": "Lesotho"},
        {"code": "LR", "name": "Liberia"},
        {"code": "LY", "name": "Libya"},
        {"code": "LI", "name": "Liechtenstein"},
        {"code": "LT", "name": "Lithuania"},
        {"code": "LU", "name": "Luxembourg"},
        {"code": "MG", "name": "Madagascar"},
        {"code": "MW", "name": "Malawi"},
        {"code": "MY", "name": "Malaysia"},
        {"code": "MV", "name": "Maldives"},
        {"code": "ML", "name": "Mali"},
        {"code": "MT", "name": "Malta"},
        {"code": "MH", "name": "Marshall Islands"},
        {"code": "MR", "name": "Mauritania"},
        {"code": "MU", "name": "Mauritius"},
        {"code": "MX", "name": "Mexico"},
        {"code": "FM", "name": "Micronesia"},
        {"code": "MD", "name": "Moldova"},
        {"code": "MC", "name": "Monaco"},
        {"code": "MN", "name": "Mongolia"},
        {"code": "ME", "name": "Montenegro"},
        {"code": "MA", "name": "Morocco"},
        {"code": "MZ", "name": "Mozambique"},
        {"code": "MM", "name": "Myanmar"},
        {"code": "NA", "name": "Namibia"},
        {"code": "NR", "name": "Nauru"},
        {"code": "NP", "name": "Nepal"},
        {"code": "NL", "name": "Netherlands"},
        {"code": "NZ", "name": "New Zealand"},
        {"code": "NI", "name": "Nicaragua"},
        {"code": "NE", "name": "Niger"},
        {"code": "NG", "name": "Nigeria"},
        {"code": "NO", "name": "Norway"},
        {"code": "OM", "name": "Oman"},
        {"code": "PK", "name": "Pakistan"},
        {"code": "PW", "name": "Palau"},
        {"code": "PA", "name": "Panama"},
        {"code": "PG", "name": "Papua New Guinea"},
        {"code": "PY", "name": "Paraguay"},
        {"code": "PE", "name": "Peru"},
        {"code": "PH", "name": "Philippines"},
        {"code": "PL", "name": "Poland"},
        {"code": "PT", "name": "Portugal"},
        {"code": "QA", "name": "Qatar"},
        {"code": "RO", "name": "Romania"},
        {"code": "RU", "name": "Russia"},
        {"code": "RW", "name": "Rwanda"},
        {"code": "WS", "name": "Samoa"},
        {"code": "SM", "name": "San Marino"},
        {"code": "ST", "name": "Sao Tome and Principe"},
        {"code": "SA", "name": "Saudi Arabia"},
        {"code": "SN", "name": "Senegal"},
        {"code": "RS", "name": "Serbia"},
        {"code": "SC", "name": "Seychelles"},
        {"code": "SL", "name": "Sierra Leone"},
        {"code": "SG", "name": "Singapore"},
        {"code": "SK", "name": "Slovakia"},
        {"code": "SI", "name": "Slovenia"},
        {"code": "SB", "name": "Solomon Islands"},
        {"code": "SO", "name": "Somalia"},
        {"code": "ZA", "name": "South Africa"},
        {"code": "SS", "name": "South Sudan"},
        {"code": "ES", "name": "Spain"},
        {"code": "LK", "name": "Sri Lanka"},
        {"code": "SD", "name": "Sudan"},
        {"code": "SR", "name": "Suriname"},
        {"code": "SE", "name": "Sweden"},
        {"code": "CH", "name": "Switzerland"},
        {"code": "SY", "name": "Syria"},
        {"code": "TW", "name": "Taiwan"},
        {"code": "TJ", "name": "Tajikistan"},
        {"code": "TZ", "name": "Tanzania"},
        {"code": "TH", "name": "Thailand"},
        {"code": "TL", "name": "Timor-Leste"},
        {"code": "TG", "name": "Togo"},
        {"code": "TO", "name": "Tonga"},
        {"code": "TT", "name": "Trinidad and Tobago"},
        {"code": "TN", "name": "Tunisia"},
        {"code": "TR", "name": "Turkey"},
        {"code": "TM", "name": "Turkmenistan"},
        {"code": "TV", "name": "Tuvalu"},
        {"code": "UG", "name": "Uganda"},
        {"code": "UA", "name": "Ukraine"},
        {"code": "AE", "name": "United Arab Emirates"},
        {"code": "GB", "name": "United Kingdom"},
        {"code": "US", "name": "United States"},
        {"code": "UY", "name": "Uruguay"},
        {"code": "UZ", "name": "Uzbekistan"},
        {"code": "VU", "name": "Vanuatu"},
        {"code": "VE", "name": "Venezuela"},
        {"code": "VN", "name": "Vietnam"},
        {"code": "YE", "name": "Yemen"},
        {"code": "ZM", "name": "Zambia"},
        {"code": "ZW", "name": "Zimbabwe"}
    ]
    
    # 10 rastgele ülke seç
    selected_countries = random.sample(countries, 10)
    
    questions = []
    for i, correct_country in enumerate(selected_countries):
        # Her soru için 4 seçenek oluştur (1 doğru + 3 yanlış)
        other_countries = [c for c in countries if c["code"] != correct_country["code"]]
        wrong_options = random.sample(other_countries, 3)
        
        options = [correct_country] + wrong_options
        random.shuffle(options)
        
        questions.append({
            "question_id": i + 1,
            "flag_url": f"https://flagcdn.com/w320/{correct_country['code'].lower()}.png",
            "correct_answer": correct_country["name"],
            "options": [country["name"] for country in options],
            "correct_country_code": correct_country["code"]
        })
    
    return {
        "quiz_id": f"flag_quiz_{current_user.id}_{random.randint(1000, 9999)}",
        "questions": questions,
        "total_questions": 10,
        "time_limit": 300  # 5 dakika (30 saniye * 10 soru)
    }

@app.post("/api/flag-quiz/submit")
def submit_flag_quiz(
    quiz_data: dict,
    current_user: schemas.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit flag quiz results"""
    answers = quiz_data.get("answers", [])
    time_taken = quiz_data.get("time_taken", 0)
    
    correct_count = 0
    total_score = 0
    
    for answer in answers:
        if answer.get("is_correct", False):
            correct_count += 1
            total_score += 10  # Her doğru cevap 10 puan
    
    # Kullanıcı istatistiklerini güncelle
    crud.update_user_stats(db, current_user.id, total_score)
    
    return {
        "score": total_score,
        "correct_answers": correct_count,
        "total_questions": len(answers),
        "time_taken": time_taken,
        "percentage": (correct_count / len(answers)) * 100 if answers else 0
    }

# Admin endpoints
@app.get("/api/admin/users", response_model=schemas.PaginatedUsers)
def get_all_users_admin(
    page: int = 1,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_admin: schemas.User = Depends(get_current_admin_user)
):
    return crud.get_all_users_paginated(db, page=page, limit=limit)

@app.put("/api/admin/users/{user_id}", response_model=schemas.User)
def update_user_admin(
    user_id: int,
    user_update: schemas.AdminUserUpdate,
    db: Session = Depends(get_db),
    current_admin: schemas.User = Depends(get_current_admin_user)
):
    updated_user = crud.admin_update_user(db, user_id=user_id, user_update=user_update)
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user

@app.delete("/api/admin/users/{user_id}")
def delete_user_admin(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: schemas.User = Depends(get_current_admin_user)
):
    if user_id == current_admin.id:
        raise HTTPException(status_code=400, detail="Cannot delete your own account")
    
    success = crud.admin_delete_user(db, user_id=user_id)
    if not success:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted successfully"}

@app.get("/api/admin/quizzes", response_model=schemas.PaginatedQuizzes)
def get_all_quizzes_admin(
    page: int = 1,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_admin: schemas.User = Depends(get_current_admin_user)
):
    return crud.get_all_quizzes_admin_paginated(db, page=page, limit=limit)

@app.put("/api/admin/quizzes/{quiz_id}")
def update_quiz_admin(
    quiz_id: int,
    quiz_update: schemas.AdminQuizUpdate,
    db: Session = Depends(get_db),
    current_admin: schemas.User = Depends(get_current_admin_user)
):
    updated_quiz = crud.admin_update_quiz(db, quiz_id=quiz_id, quiz_update=quiz_update)
    if not updated_quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    return updated_quiz

@app.delete("/api/admin/quizzes/{quiz_id}")
def delete_quiz_admin(
    quiz_id: int,
    db: Session = Depends(get_db),
    current_admin: schemas.User = Depends(get_current_admin_user)
):
    success = crud.admin_delete_quiz(db, quiz_id=quiz_id)
    if not success:
        raise HTTPException(status_code=404, detail="Quiz not found")
    return {"message": "Quiz deleted successfully"}

@app.get("/api/admin/statistics", response_model=schemas.AdminStats)
def get_admin_statistics(
    db: Session = Depends(get_db),
    current_admin: schemas.User = Depends(get_current_admin_user)
):
    return crud.get_admin_statistics(db)

# Health check
@app.get("/api/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 