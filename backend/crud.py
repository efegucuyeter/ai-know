from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from database import User, Category, Quiz, Question, QuestionOption, QuizAttempt, UserAnswer
import schemas
from auth import get_password_hash
from typing import List
import math

def create_pagination_info(page: int, limit: int, total_items: int) -> schemas.PaginationInfo:
    total_pages = math.ceil(total_items / limit) if total_items > 0 else 1
    has_next = page < total_pages
    has_prev = page > 1
    
    return schemas.PaginationInfo(
        current_page=page,
        total_pages=total_pages,
        total_items=total_items,
        items_per_page=limit,
        has_next=has_next,
        has_prev=has_prev
    )

# User CRUD
def get_user(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def get_user_by_username(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user_stats(db: Session, user_id: int, score: int):
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.total_score += score
        user.quizzes_completed += 1
        db.commit()
        db.refresh(user)
    return user

def update_user(db: Session, user_id: int, user_update: schemas.UserUpdate):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return None
    
    update_data = user_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    return user

# Category CRUD
def get_categories(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Category).offset(skip).limit(limit).all()

def get_category(db: Session, category_id: int):
    return db.query(Category).filter(Category.id == category_id).first()

def create_category(db: Session, category: schemas.CategoryCreate):
    db_category = Category(**category.dict())
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

# Quiz CRUD
def get_quizzes(db: Session, skip: int = 0, limit: int = 100, category_id: int = None):
    query = db.query(Quiz).filter(Quiz.is_active == True)
    if category_id:
        query = query.filter(Quiz.category_id == category_id)
    return query.offset(skip).limit(limit).all()

def get_quiz(db: Session, quiz_id: int):
    return db.query(Quiz).filter(Quiz.id == quiz_id).first()

def get_quiz_with_questions(db: Session, quiz_id: int):
    return db.query(Quiz).filter(Quiz.id == quiz_id).first()

def create_quiz(db: Session, quiz: schemas.QuizCreate, creator_id: int):
    # Quiz oluştur
    db_quiz = Quiz(
        title=quiz.title,
        description=quiz.description,
        category_id=quiz.category_id,
        creator_id=creator_id,
        difficulty=quiz.difficulty,
        image_url=quiz.image_url,
        time_limit=quiz.time_limit
    )
    db.add(db_quiz)
    db.commit()
    db.refresh(db_quiz)
    
    # Soruları ekle
    for question_data in quiz.questions:
        db_question = Question(
            quiz_id=db_quiz.id,
            question_text=question_data.question_text,
            question_type=question_data.question_type,
            points=question_data.points,
            order_index=question_data.order_index
        )
        db.add(db_question)
        db.commit()
        db.refresh(db_question)
        
        # Seçenekleri ekle
        for option_data in question_data.options:
            db_option = QuestionOption(
                question_id=db_question.id,
                option_text=option_data.option_text,
                is_correct=option_data.is_correct,
                order_index=option_data.order_index
            )
            db.add(db_option)
    
    db.commit()
    return db_quiz

def get_quiz_summaries(db: Session, skip: int = 0, limit: int = 100, category_id: int = None):
    query = db.query(
        Quiz.id,
        Quiz.title,
        Quiz.description,
        Quiz.difficulty,
        Quiz.image_url,
        Category.name.label('category_name'),
        Category.id.label('category_id'),
        User.username.label('creator_username'),
        func.count(Question.id).label('question_count')
    ).join(Category).join(User).outerjoin(Question).filter(Quiz.is_active == True)
    
    if category_id:
        query = query.filter(Quiz.category_id == category_id)
    
    query = query.group_by(Quiz.id)
    return query.offset(skip).limit(limit).all()

# Quiz Attempt CRUD
def create_quiz_attempt(db: Session, attempt: schemas.QuizAttemptCreate, user_id: int):
    # Quiz bilgilerini al
    quiz = get_quiz_with_questions(db, attempt.quiz_id)
    if not quiz:
        return None
    
    # Cevapları kontrol et ve puanla
    correct_answers = 0
    total_score = 0
    
    # Quiz attempt oluştur
    db_attempt = QuizAttempt(
        user_id=user_id,
        quiz_id=attempt.quiz_id,
        total_questions=len(quiz.questions),
        time_taken=attempt.time_taken
    )
    db.add(db_attempt)
    db.commit()
    db.refresh(db_attempt)
    
    # Cevapları kaydet ve puanla
    for answer in attempt.answers:
        question = db.query(Question).filter(Question.id == answer.question_id).first()
        if not question:
            continue
            
        correct_option = db.query(QuestionOption).filter(
            QuestionOption.question_id == answer.question_id,
            QuestionOption.is_correct == True
        ).first()
        
        is_correct = correct_option and correct_option.id == answer.selected_option_id
        
        if is_correct:
            correct_answers += 1
            total_score += question.points
        
        db_answer = UserAnswer(
            attempt_id=db_attempt.id,
            question_id=answer.question_id,
            selected_option_id=answer.selected_option_id,
            is_correct=is_correct
        )
        db.add(db_answer)
    
    # Attempt'i güncelle
    db_attempt.correct_answers = correct_answers
    db_attempt.score = total_score
    
    db.commit()
    db.refresh(db_attempt)
    
    # Kullanıcı istatistiklerini güncelle
    update_user_stats(db, user_id, total_score)
    
    return db_attempt

def get_user_attempts(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(QuizAttempt).filter(QuizAttempt.user_id == user_id).offset(skip).limit(limit).all()

def get_leaderboard_paginated(db: Session, page: int = 1, limit: int = 10):
    skip = (page - 1) * limit
    total_items = db.query(User).filter(User.is_active == True).count()
    
    users = db.query(User).filter(User.is_active == True).order_by(desc(User.total_score)).offset(skip).limit(limit).all()
    
    leaderboard = []
    for i, user in enumerate(users, skip + 1):  # skip + 1 for correct ranking
        leaderboard.append(schemas.LeaderboardEntry(
            username=user.username,
            avatar_url=user.avatar_url,
            total_score=user.total_score,
            quizzes_completed=user.quizzes_completed,
            rank=i
        ))
    
    pagination = create_pagination_info(page, limit, total_items)
    
    return schemas.PaginatedLeaderboard(
        leaderboard=leaderboard,
        pagination=pagination
    )

def get_leaderboard(db: Session, limit: int = 10):
    users = db.query(User).filter(User.is_active == True).order_by(desc(User.total_score)).limit(limit).all()
    leaderboard = []
    for i, user in enumerate(users, 1):
        leaderboard.append(schemas.LeaderboardEntry(
            username=user.username,
            avatar_url=user.avatar_url,
            total_score=user.total_score,
            quizzes_completed=user.quizzes_completed,
            rank=i
        ))
    return leaderboard

def get_app_statistics(db: Session):
    total_users = db.query(User).filter(User.is_active == True).count()
    total_quizzes = db.query(Quiz).filter(Quiz.is_active == True).count()
    total_attempts = db.query(QuizAttempt).count()
    total_categories = db.query(Category).count()
    
    # En son kayıt olan kullanıcı
    latest_user = db.query(User).filter(User.is_active == True).order_by(desc(User.created_at)).first()
    latest_username = f"{latest_user.username} ({latest_user.email})" if latest_user else None
    
    return schemas.AppStatistics(
        total_users=total_users,
        total_quizzes=total_quizzes,
        total_attempts=total_attempts,
        total_categories=total_categories,
        latest_user=latest_username
    )

# Admin CRUD Functions
def get_all_users_paginated(db: Session, page: int = 1, limit: int = 10):
    skip = (page - 1) * limit
    total_items = db.query(User).count()
    users = db.query(User).offset(skip).limit(limit).all()
    
    pagination = create_pagination_info(page, limit, total_items)
    
    return schemas.PaginatedUsers(
        users=users,
        pagination=pagination
    )

def get_all_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(User).offset(skip).limit(limit).all()

def admin_update_user(db: Session, user_id: int, user_update: schemas.AdminUserUpdate):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return None
    
    update_data = user_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    return user

def admin_delete_user(db: Session, user_id: int):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return False
    
    # Kullanıcının quiz attempt'lerini sil
    db.query(UserAnswer).filter(UserAnswer.attempt_id.in_(
        db.query(QuizAttempt.id).filter(QuizAttempt.user_id == user_id)
    )).delete(synchronize_session=False)
    
    db.query(QuizAttempt).filter(QuizAttempt.user_id == user_id).delete()
    
    # Kullanıcının oluşturduğu quizleri pasif yap
    db.query(Quiz).filter(Quiz.creator_id == user_id).update({"is_active": False})
    
    # Kullanıcıyı sil
    db.delete(user)
    db.commit()
    return True

def get_all_quizzes_admin_paginated(db: Session, page: int = 1, limit: int = 10):
    skip = (page - 1) * limit
    total_items = db.query(Quiz).count()
    
    query = db.query(
        Quiz.id,
        Quiz.title,
        Quiz.description,
        Quiz.difficulty,
        Quiz.image_url,
        Quiz.is_active,
        Quiz.created_at,
        Category.name.label('category_name'),
        Category.id.label('category_id'),
        User.username.label('creator_username'),
        func.count(Question.id).label('question_count')
    ).join(Category).join(User).outerjoin(Question)
    
    query = query.group_by(Quiz.id)
    quizzes = query.offset(skip).limit(limit).all()
    
    # Quiz formatını düzenle
    formatted_quizzes = []
    for quiz in quizzes:
        formatted_quiz = {
            "id": quiz.id,
            "title": quiz.title,
            "description": quiz.description,
            "difficulty": quiz.difficulty,
            "image_url": quiz.image_url,
            "is_active": quiz.is_active,
            "created_at": quiz.created_at,
            "category": {
                "id": quiz.category_id,
                "name": quiz.category_name
            },
            "question_count": quiz.question_count,
            "creator_username": quiz.creator_username
        }
        formatted_quizzes.append(formatted_quiz)
    
    pagination = create_pagination_info(page, limit, total_items)
    
    return schemas.PaginatedQuizzes(
        quizzes=formatted_quizzes,
        pagination=pagination
    )

def get_all_quizzes_admin(db: Session, skip: int = 0, limit: int = 100):
    query = db.query(
        Quiz.id,
        Quiz.title,
        Quiz.description,
        Quiz.difficulty,
        Quiz.image_url,
        Quiz.is_active,
        Quiz.created_at,
        Category.name.label('category_name'),
        Category.id.label('category_id'),
        User.username.label('creator_username'),
        func.count(Question.id).label('question_count')
    ).join(Category).join(User).outerjoin(Question)
    
    query = query.group_by(Quiz.id)
    return query.offset(skip).limit(limit).all()

def admin_update_quiz(db: Session, quiz_id: int, quiz_update: schemas.AdminQuizUpdate):
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        return None
    
    update_data = quiz_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(quiz, field, value)
    
    db.commit()
    db.refresh(quiz)
    return quiz

def admin_delete_quiz(db: Session, quiz_id: int):
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        return False
    
    # Quiz ile ilgili tüm verileri sil
    # Önce user answers'ları sil
    db.query(UserAnswer).filter(UserAnswer.attempt_id.in_(
        db.query(QuizAttempt.id).filter(QuizAttempt.quiz_id == quiz_id)
    )).delete(synchronize_session=False)
    
    # Quiz attempts'ları sil
    db.query(QuizAttempt).filter(QuizAttempt.quiz_id == quiz_id).delete()
    
    # Question options'ları sil
    db.query(QuestionOption).filter(QuestionOption.question_id.in_(
        db.query(Question.id).filter(Question.quiz_id == quiz_id)
    )).delete(synchronize_session=False)
    
    # Questions'ları sil
    db.query(Question).filter(Question.quiz_id == quiz_id).delete()
    
    # Quiz'i sil
    db.delete(quiz)
    db.commit()
    return True

def get_admin_statistics(db: Session):
    total_users = db.query(User).count()
    total_admins = db.query(User).filter(User.is_admin == True).count()
    total_quizzes = db.query(Quiz).count()
    total_attempts = db.query(QuizAttempt).count()
    total_categories = db.query(Category).count()
    active_users = db.query(User).filter(User.is_active == True).count()
    inactive_users = db.query(User).filter(User.is_active == False).count()
    active_quizzes = db.query(Quiz).filter(Quiz.is_active == True).count()
    inactive_quizzes = db.query(Quiz).filter(Quiz.is_active == False).count()
    
    return schemas.AdminStats(
        total_users=total_users,
        total_admins=total_admins,
        total_quizzes=total_quizzes,
        total_attempts=total_attempts,
        total_categories=total_categories,
        active_users=active_users,
        inactive_users=inactive_users,
        active_quizzes=active_quizzes,
        inactive_quizzes=inactive_quizzes
    ) 