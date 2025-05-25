from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

# User Schemas
class UserBase(BaseModel):
    email: str
    username: str

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class User(UserBase):
    id: int
    avatar_url: Optional[str] = None
    created_at: datetime
    is_active: bool
    is_admin: bool = False
    total_score: int
    quizzes_completed: int
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    avatar_url: Optional[str] = None

# Category Schemas
class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None

class CategoryCreate(CategoryBase):
    pass

class Category(CategoryBase):
    id: int
    
    class Config:
        from_attributes = True

# Question Option Schemas
class QuestionOptionBase(BaseModel):
    option_text: str
    is_correct: bool
    order_index: int

class QuestionOptionCreate(QuestionOptionBase):
    pass

class QuestionOption(QuestionOptionBase):
    id: int
    question_id: int
    
    class Config:
        from_attributes = True

# Question Schemas
class QuestionBase(BaseModel):
    question_text: str
    question_type: str = "multiple_choice"
    points: int = 10
    order_index: int

class QuestionCreate(QuestionBase):
    options: List[QuestionOptionCreate]

class Question(QuestionBase):
    id: int
    quiz_id: int
    options: List[QuestionOption] = []
    
    class Config:
        from_attributes = True

# Quiz Schemas
class QuizBase(BaseModel):
    title: str
    description: Optional[str] = None
    category_id: int
    difficulty: str
    image_url: Optional[str] = None
    time_limit: int = 300

class QuizCreate(QuizBase):
    questions: List[QuestionCreate]

class Quiz(QuizBase):
    id: int
    creator_id: int
    created_at: datetime
    is_active: bool
    questions: List[Question] = []
    category: Optional[Category] = None
    
    class Config:
        from_attributes = True

class QuizSummary(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    difficulty: str
    image_url: Optional[str] = None
    category: Optional[Category] = None
    question_count: int
    creator_username: str
    
    class Config:
        from_attributes = True

# Quiz Attempt Schemas
class UserAnswerCreate(BaseModel):
    question_id: int
    selected_option_id: int

class QuizAttemptCreate(BaseModel):
    quiz_id: int
    answers: List[UserAnswerCreate]
    time_taken: int

class UserAnswer(BaseModel):
    id: int
    question_id: int
    selected_option_id: int
    is_correct: bool
    
    class Config:
        from_attributes = True

class QuizAttempt(BaseModel):
    id: int
    user_id: int
    quiz_id: int
    score: int
    total_questions: int
    correct_answers: int
    time_taken: int
    completed_at: datetime
    answers: List[UserAnswer] = []
    
    class Config:
        from_attributes = True

class QuizResult(BaseModel):
    score: int
    total_questions: int
    correct_answers: int
    time_taken: int
    percentage: float

# Leaderboard Schemas
class LeaderboardEntry(BaseModel):
    username: str
    avatar_url: Optional[str] = None
    total_score: int
    quizzes_completed: int
    rank: int

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class AppStatistics(BaseModel):
    total_users: int
    total_quizzes: int
    total_attempts: int
    total_categories: int
    latest_user: Optional[str] = None

# AI Question Generation Schemas
class AIQuestionRequest(BaseModel):
    category: str
    difficulty: str  # Kolay, Orta, Zor
    question_count: int
    topic: Optional[str] = None

class AIGeneratedQuestion(BaseModel):
    question: str
    options: dict  # {"A": "option1", "B": "option2", "C": "option3", "D": "option4"}
    correct_answer: str  # A, B, C, or D

class AIQuestionResponse(BaseModel):
    questions: List[AIGeneratedQuestion]
    success: bool
    message: Optional[str] = None

# Admin Schemas
class AdminUserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    is_active: Optional[bool] = None
    is_admin: Optional[bool] = None

class AdminQuizUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    difficulty: Optional[str] = None
    is_active: Optional[bool] = None
    category_id: Optional[int] = None

class AdminStats(BaseModel):
    total_users: int
    total_admins: int
    total_quizzes: int
    total_attempts: int
    total_categories: int
    active_users: int
    inactive_users: int
    active_quizzes: int
    inactive_quizzes: int

# Pagination Schemas
class PaginationInfo(BaseModel):
    current_page: int
    total_pages: int
    total_items: int
    items_per_page: int
    has_next: bool
    has_prev: bool

class PaginatedUsers(BaseModel):
    users: List[User]
    pagination: PaginationInfo

class PaginatedQuizzes(BaseModel):
    quizzes: List[dict]
    pagination: PaginationInfo

class PaginatedLeaderboard(BaseModel):
    leaderboard: List[LeaderboardEntry]
    pagination: PaginationInfo 