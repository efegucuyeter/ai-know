from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Text, ForeignKey, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime

SQLALCHEMY_DATABASE_URL = "sqlite:///./quiz_app.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    avatar_url = Column(String, default="https://placehold.co/120x120")
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    total_score = Column(Integer, default=0)
    quizzes_completed = Column(Integer, default=0)
    
    # İlişkiler
    created_quizzes = relationship("Quiz", back_populates="creator")
    quiz_attempts = relationship("QuizAttempt", back_populates="user")

class Category(Base):
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)
    image_url = Column(String)
    
    # İlişkiler
    quizzes = relationship("Quiz", back_populates="category")

class Quiz(Base):
    __tablename__ = "quizzes"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(Text)
    category_id = Column(Integer, ForeignKey("categories.id"))
    creator_id = Column(Integer, ForeignKey("users.id"))
    difficulty = Column(String)  # Kolay, Orta, Zor
    image_url = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    time_limit = Column(Integer, default=300)  # saniye cinsinden
    
    # İlişkiler
    category = relationship("Category", back_populates="quizzes")
    creator = relationship("User", back_populates="created_quizzes")
    questions = relationship("Question", back_populates="quiz")
    attempts = relationship("QuizAttempt", back_populates="quiz")

class Question(Base):
    __tablename__ = "questions"
    
    id = Column(Integer, primary_key=True, index=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id"))
    question_text = Column(Text)
    question_type = Column(String, default="multiple_choice")  # multiple_choice, true_false
    points = Column(Integer, default=10)
    order_index = Column(Integer)
    
    # İlişkiler
    quiz = relationship("Quiz", back_populates="questions")
    options = relationship("QuestionOption", back_populates="question")

class QuestionOption(Base):
    __tablename__ = "question_options"
    
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("questions.id"))
    option_text = Column(Text)
    is_correct = Column(Boolean, default=False)
    order_index = Column(Integer)
    
    # İlişkiler
    question = relationship("Question", back_populates="options")

class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    quiz_id = Column(Integer, ForeignKey("quizzes.id"))
    score = Column(Integer, default=0)
    total_questions = Column(Integer)
    correct_answers = Column(Integer, default=0)
    time_taken = Column(Integer)  # saniye cinsinden
    completed_at = Column(DateTime, default=datetime.utcnow)
    
    # İlişkiler
    user = relationship("User", back_populates="quiz_attempts")
    quiz = relationship("Quiz", back_populates="attempts")
    answers = relationship("UserAnswer", back_populates="attempt")

class UserAnswer(Base):
    __tablename__ = "user_answers"
    
    id = Column(Integer, primary_key=True, index=True)
    attempt_id = Column(Integer, ForeignKey("quiz_attempts.id"))
    question_id = Column(Integer, ForeignKey("questions.id"))
    selected_option_id = Column(Integer, ForeignKey("question_options.id"))
    is_correct = Column(Boolean)
    
    # İlişkiler
    attempt = relationship("QuizAttempt", back_populates="answers")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_tables():
    Base.metadata.create_all(bind=engine) 