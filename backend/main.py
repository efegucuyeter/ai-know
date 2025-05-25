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

# Category endpoints
@app.get("/api/categories", response_model=List[schemas.Category])
def read_categories(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    categories = crud.get_categories(db, skip=skip, limit=limit)
    return categories

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
        topic=request.topic
    )

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