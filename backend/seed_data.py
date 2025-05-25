from sqlalchemy.orm import Session
from database import SessionLocal, create_tables
import crud
import schemas

def seed_database():
    create_tables()
    db = SessionLocal()
    
    try:
        # Kategoriler oluştur
        categories = [
            {"name": "Coding", "description": "Programlama ve yazılım geliştirme", "image_url": "https://placehold.co/400x320/2563eb/ffffff?text=Coding"},
            {"name": "Genel Kültür", "description": "Genel kültür ve bilgi yarışması", "image_url": "https://placehold.co/400x320/7c3aed/ffffff?text=Genel+Kültür"},
            {"name": "Bayraklar", "description": "Dünya ülkelerinin bayrakları", "image_url": "https://placehold.co/400x320/dc2626/ffffff?text=Bayraklar"},
            {"name": "İngilizce", "description": "İngilizce dil bilgisi ve kelimeler", "image_url": "https://placehold.co/400x320/059669/ffffff?text=İngilizce"},
            {"name": "Almanca", "description": "Almanca dil bilgisi ve kelimeler", "image_url": "https://placehold.co/400x320/ea580c/ffffff?text=Almanca"},
            {"name": "Dünya Tarihi", "description": "Dünya tarihinden önemli olaylar", "image_url": "https://placehold.co/400x320/7c2d12/ffffff?text=Dünya+Tarihi"},
            {"name": "Futbol", "description": "Futbol bilgisi ve spor", "image_url": "https://placehold.co/400x320/16a34a/ffffff?text=Futbol"},
            {"name": "Müzik", "description": "Müzik bilgisi ve sanatçılar", "image_url": "https://placehold.co/400x320/c026d3/ffffff?text=Müzik"}
        ]
        
        created_categories = []
        for cat_data in categories:
            existing_cat = db.query(crud.Category).filter(crud.Category.name == cat_data["name"]).first()
            if not existing_cat:
                category = schemas.CategoryCreate(**cat_data)
                created_cat = crud.create_category(db, category)
                created_categories.append(created_cat)
                print(f"Kategori oluşturuldu: {created_cat.name}")
            else:
                created_categories.append(existing_cat)
        
        # Test kullanıcısı oluştur (Admin)
        test_user_email = "test@example.com"
        existing_user = crud.get_user_by_email(db, test_user_email)
        if not existing_user:
            test_user = schemas.UserCreate(
                email=test_user_email,
                username="testuser",
                password="test123"
            )
            created_user = crud.create_user(db, test_user)
            # Admin yap
            created_user.is_admin = True
            db.commit()
            print(f"Test kullanıcısı (Admin) oluşturuldu: {created_user.username}")
        else:
            # Mevcut kullanıcıyı admin yap
            existing_user.is_admin = True
            db.commit()
            created_user = existing_user
            print(f"Mevcut kullanıcı admin yapıldı: {created_user.username}")
        
        # Örnek quizler oluştur
        sample_quizzes = [
            {
                "title": "Python Temelleri",
                "description": "Python programlama dili temel kavramları",
                "category_id": created_categories[0].id,  # Coding
                "difficulty": "Kolay",
                "image_url": "https://placehold.co/400x320/2563eb/ffffff?text=Python",
                "time_limit": 300,
                "questions": [
                    {
                        "question_text": "Python'da yorum satırı nasıl yazılır?",
                        "question_type": "multiple_choice",
                        "points": 10,
                        "order_index": 1,
                        "options": [
                            {"option_text": "// yorum", "is_correct": False, "order_index": 1},
                            {"option_text": "# yorum", "is_correct": True, "order_index": 2},
                            {"option_text": "/* yorum */", "is_correct": False, "order_index": 3},
                            {"option_text": "-- yorum", "is_correct": False, "order_index": 4}
                        ]
                    },
                    {
                        "question_text": "Python'da liste oluşturmak için hangi sembol kullanılır?",
                        "question_type": "multiple_choice",
                        "points": 10,
                        "order_index": 2,
                        "options": [
                            {"option_text": "{}", "is_correct": False, "order_index": 1},
                            {"option_text": "[]", "is_correct": True, "order_index": 2},
                            {"option_text": "()", "is_correct": False, "order_index": 3},
                            {"option_text": "<>", "is_correct": False, "order_index": 4}
                        ]
                    }
                ]
            },
            {
                "title": "Dünya Bayrakları",
                "description": "Ülkelerin bayraklarını tanıyın",
                "category_id": created_categories[2].id,  # Bayraklar
                "difficulty": "Orta",
                "image_url": "https://placehold.co/400x320/dc2626/ffffff?text=Bayraklar",
                "time_limit": 600,
                "questions": [
                    {
                        "question_text": "Hangi ülkenin bayrağında kırmızı ve beyaz çizgiler vardır?",
                        "question_type": "multiple_choice",
                        "points": 10,
                        "order_index": 1,
                        "options": [
                            {"option_text": "Fransa", "is_correct": False, "order_index": 1},
                            {"option_text": "Amerika", "is_correct": True, "order_index": 2},
                            {"option_text": "İngiltere", "is_correct": False, "order_index": 3},
                            {"option_text": "Almanya", "is_correct": False, "order_index": 4}
                        ]
                    },
                    {
                        "question_text": "Hangi ülkenin bayrağında ay yıldız bulunur?",
                        "question_type": "multiple_choice",
                        "points": 10,
                        "order_index": 2,
                        "options": [
                            {"option_text": "Türkiye", "is_correct": True, "order_index": 1},
                            {"option_text": "Yunanistan", "is_correct": False, "order_index": 2},
                            {"option_text": "İtalya", "is_correct": False, "order_index": 3},
                            {"option_text": "İspanya", "is_correct": False, "order_index": 4}
                        ]
                    }
                ]
            },
            {
                "title": "Futbol Bilgisi",
                "description": "Futbol dünyasından sorular",
                "category_id": created_categories[6].id,  # Futbol
                "difficulty": "Kolay",
                "image_url": "https://placehold.co/400x320/16a34a/ffffff?text=Futbol",
                "time_limit": 400,
                "questions": [
                    {
                        "question_text": "Bir futbol takımında kaç oyuncu sahada bulunur?",
                        "question_type": "multiple_choice",
                        "points": 10,
                        "order_index": 1,
                        "options": [
                            {"option_text": "10", "is_correct": False, "order_index": 1},
                            {"option_text": "11", "is_correct": True, "order_index": 2},
                            {"option_text": "12", "is_correct": False, "order_index": 3},
                            {"option_text": "9", "is_correct": False, "order_index": 4}
                        ]
                    },
                    {
                        "question_text": "Dünya Kupası kaç yılda bir düzenlenir?",
                        "question_type": "multiple_choice",
                        "points": 10,
                        "order_index": 2,
                        "options": [
                            {"option_text": "2 yıl", "is_correct": False, "order_index": 1},
                            {"option_text": "4 yıl", "is_correct": True, "order_index": 2},
                            {"option_text": "3 yıl", "is_correct": False, "order_index": 3},
                            {"option_text": "5 yıl", "is_correct": False, "order_index": 4}
                        ]
                    }
                ]
            },
            {
                "title": "Temel İngilizce",
                "description": "İngilizce kelimeler ve gramer",
                "category_id": created_categories[3].id,  # İngilizce
                "difficulty": "Kolay",
                "image_url": "https://placehold.co/400x320/059669/ffffff?text=English",
                "time_limit": 400,
                "questions": [
                    {
                        "question_text": "'Hello' kelimesinin Türkçe karşılığı nedir?",
                        "question_type": "multiple_choice",
                        "points": 10,
                        "order_index": 1,
                        "options": [
                            {"option_text": "Merhaba", "is_correct": True, "order_index": 1},
                            {"option_text": "Güle güle", "is_correct": False, "order_index": 2},
                            {"option_text": "Teşekkürler", "is_correct": False, "order_index": 3},
                            {"option_text": "Özür dilerim", "is_correct": False, "order_index": 4}
                        ]
                    },
                    {
                        "question_text": "'Cat' kelimesinin Türkçe karşılığı nedir?",
                        "question_type": "multiple_choice",
                        "points": 10,
                        "order_index": 2,
                        "options": [
                            {"option_text": "Köpek", "is_correct": False, "order_index": 1},
                            {"option_text": "Kedi", "is_correct": True, "order_index": 2},
                            {"option_text": "Kuş", "is_correct": False, "order_index": 3},
                            {"option_text": "Balık", "is_correct": False, "order_index": 4}
                        ]
                    }
                ]
            }
        ]
        
        for quiz_data in sample_quizzes:
            existing_quiz = db.query(crud.Quiz).filter(crud.Quiz.title == quiz_data["title"]).first()
            if not existing_quiz:
                quiz = schemas.QuizCreate(**quiz_data)
                created_quiz = crud.create_quiz(db, quiz, created_user.id)
                print(f"Quiz oluşturuldu: {created_quiz.title}")
        
        print("Veritabanı başarıyla dolduruldu!")
        
    except Exception as e:
        print(f"Hata oluştu: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_database() 