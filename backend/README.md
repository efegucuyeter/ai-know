# Quiz App Backend

FastAPI tabanlı quiz uygulaması backend'i.

## Özellikler

- Kullanıcı kayıt/giriş sistemi (JWT token tabanlı)
- Quiz oluşturma ve yönetimi
- Kategori sistemi
- Quiz çözme ve puanlama
- Liderlik tablosu
- SQLite veritabanı

## Kurulum

1. Gerekli paketleri yükleyin:
```bash
pip install -r requirements.txt
```

2. Veritabanını oluşturun ve örnek verileri ekleyin:
```bash
python seed_data.py
```

3. Sunucuyu başlatın:
```bash
python main.py
```

Sunucu http://localhost:8000 adresinde çalışacaktır.

## API Endpoints

### Authentication
- `POST /api/auth/register` - Kullanıcı kaydı
- `POST /api/auth/login` - Kullanıcı girişi
- `GET /api/auth/me` - Mevcut kullanıcı bilgileri

### Categories
- `GET /api/categories` - Kategorileri listele
- `POST /api/categories` - Yeni kategori oluştur

### Quizzes
- `GET /api/quizzes` - Quizleri listele
- `GET /api/quizzes/{quiz_id}` - Quiz detayları
- `POST /api/quizzes` - Yeni quiz oluştur
- `POST /api/quizzes/{quiz_id}/attempt` - Quiz çöz

### User
- `GET /api/user/attempts` - Kullanıcının quiz geçmişi

### Leaderboard
- `GET /api/leaderboard` - Liderlik tablosu

## Test Kullanıcısı

Email: test@example.com
Şifre: test123

## API Dokümantasyonu

Sunucu çalıştıktan sonra http://localhost:8000/docs adresinden Swagger UI'ya erişebilirsiniz. 