import requests
import json
import re
from typing import List, Dict, Any
import schemas

API_KEY = "API"

def generate_ai_questions(category: str, difficulty: str, question_count: int, topic: str = None, language: str = "tr") -> schemas.AIQuestionResponse:
    """
    AI ile soru oluşturur - Türkçe ve İngilizce destekli
    """
    
    # Zorluk seviyesini İngilizce'ye çevir
    difficulty_map = {
        "Kolay": "easy",
        "Orta": "medium", 
        "Zor": "hard"
    }
    
    difficulty_en = difficulty_map.get(difficulty, "medium")
    
    # Dil bazlı prompt oluştur
    if language == "en":
        # İngilizce prompt
        topic_text = f" about {topic}" if topic else ""
        prompt = (
            f"Generate {question_count} {difficulty_en} level {category}{topic_text} questions in English. "
            f"Each question should follow the JSON format below. "
            f"Return only JSON format, no explanations or solutions needed. "
            f"Each question must have 4 options: A, B, C, D. "
            f"The correct answer key should be 'correct_answer' and must be only A, B, C or D. "
            f"The entire response should only contain the following JSON structure:\n\n"
            f"[\n"
            f"  {{\n"
            f"    \"question\": \"question text?\",\n"
            f"    \"options\": {{\n"
            f"      \"A\": \"option text\",\n"
            f"      \"B\": \"option text\",\n"
            f"      \"C\": \"option text\",\n"
            f"      \"D\": \"option text\"\n"
            f"    }},\n"
            f"    \"correct_answer\": \"B\"\n"
            f"  }},\n"
            f"  ... (continuing questions in the same structure)\n"
            f"]"
        )
    else:
        # Türkçe prompt (mevcut)
        topic_text = f" konusunda {topic}" if topic else ""
        prompt = (
            f"{question_count} tane {difficulty} seviye {category}{topic_text} sorusu üret. "
            f"Her biri aşağıdaki JSON formatında olsun. "
            f"Sorular sadece json olarak dönmeli, açıklama veya çözüm istemiyorum. "
            f"Her soruda A, B, C, D olmak üzere 4 seçenek yer almalı. "
            f"Doğru cevabın anahtar adı 'correct_answer' olmalı ve sadece A, B, C ya da D şeklinde yazılmalı. "
            f"Yanıtın tamamı sadece aşağıdaki JSON yapısını içermelidir:\n\n"
            f"[\n"
            f"  {{\n"
            f"    \"question\": \"soru?\",\n"
            f"    \"options\": {{\n"
            f"      \"A\": \"cevap\",\n"
            f"      \"B\": \"cevap\",\n"
            f"      \"C\": \"cevap\",\n"
            f"      \"D\": \"cevap\"\n"
            f"    }},\n"
            f"    \"correct_answer\": \"B\"\n"
            f"  }},\n"
            f"  ... (devam eden sorularda aynı yapıda olacak)\n"
            f"]"
        )

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "",
        "X-Title": "EfeG_AI_SoruUretici"
    }

    data = {
        "model": "deepseek/deepseek-prover-v2:free",
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    }
    
    try:
        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            data=json.dumps(data),
            timeout=30
        )

        if response.status_code == 200:
            result = response.json()
            ai_response = result['choices'][0]['message']['content']
            
            # JSON'u parse et
            questions = parse_ai_response(ai_response)
            
            if questions:
                return schemas.AIQuestionResponse(
                    questions=questions,
                    success=True,
                    message="Sorular başarıyla oluşturuldu"
                )
            else:
                return schemas.AIQuestionResponse(
                    questions=[],
                    success=False,
                    message="AI yanıtı parse edilemedi"
                )
        else:
            return schemas.AIQuestionResponse(
                questions=[],
                success=False,
                message=f"AI API hatası: {response.status_code}"
            )
            
    except Exception as e:
        return schemas.AIQuestionResponse(
            questions=[],
            success=False,
            message=f"Hata oluştu: {str(e)}"
        )

def parse_ai_response(ai_response: str) -> List[schemas.AIGeneratedQuestion]:
    """
    AI yanıtını parse eder ve soru listesi döndürür
    """
    try:
        # JSON kısmını bul
        json_match = re.search(r'\[.*\]', ai_response, re.DOTALL)
        if not json_match:
            return []
        
        json_str = json_match.group()
        questions_data = json.loads(json_str)
        
        questions = []
        for q_data in questions_data:
            if all(key in q_data for key in ['question', 'options', 'correct_answer']):
                question = schemas.AIGeneratedQuestion(
                    question=q_data['question'],
                    options=q_data['options'],
                    correct_answer=q_data['correct_answer']
                )
                questions.append(question)
        
        return questions
        
    except Exception as e:
        print(f"Parse hatası: {e}")
        return [] 