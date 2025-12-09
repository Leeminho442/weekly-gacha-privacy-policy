# 🎴 AI Card Generation Scripts

Weekly Gacha 카드를 Genspark AI로 자동 생성하는 스크립트입니다.

## 📋 필수 요구사항

### 1. Firebase Admin SDK Key
```bash
# Firebase Admin SDK 키 파일 위치
/opt/flutter/firebase-admin-sdk.json
```

**다운로드 방법:**
1. Firebase Console: https://console.firebase.google.com/
2. Project Settings → Service Accounts
3. "Generate new private key" 클릭
4. 다운로드한 JSON 파일을 `/opt/flutter/` 에 업로드

### 2. Python 패키지
```bash
pip install firebase-admin==7.1.0
```

## 🚀 사용 방법

### 기본 실행 (대화형 모드)
```bash
cd /home/user/flutter_app/scripts/ai_generation
python3 generate_cards_with_ai.py
```

### 고급 사용 (Python 코드에서 직접 호출)
```python
from generate_cards_with_ai import AICardGenerator, GenerationMode, CardStyle

generator = AICardGenerator()

result = generator.generate_full_season(
    mode=GenerationMode.EVOLUTION,
    theme='진화하는 몬스터',
    style=CardStyle.CUTE
)

print(f"Generated: {result['generated']}/70 cards")
print(f"Season ID: {result['season_id']}")
```

## 📊 생성 모드

### 1. Evolution Mode (진화 시스템)
- 20마리 생명체 × 5단계 진화 = 100장 → 70장 필터링
- 희귀도 분배: Normal 20, Rare 20, SR 20, UR 9, Secret 1
- 각 생명체가 5단계로 진화

### 2. Thematic Mode (테마 기반)
- 70장 독립 카드
- 테마에 맞는 유니크한 카드 생성
- 같은 희귀도 분배

### 3. Hybrid Mode (하이브리드)
- 35장 진화형 + 35장 독립 카드
- 다양성과 진화 시스템의 균형

## 🎨 아트 스타일

- **Cute**: 귀여운 스타일, 파스텔 컬러
- **Cyberpunk**: 사이버펑크, 네온 효과
- **Cartoon**: 카툰/만화 스타일
- **Fantasy**: 판타지 아트
- **Pixel Art**: 16비트 픽셀 아트
- **Realistic**: 사실적인 스타일

## 💰 예상 비용

| 해상도 | 모델 | 단가 | 70장 비용 | 연간 비용 (주간) |
|--------|------|------|-----------|------------------|
| 512×512 | recraft-v3 | $0.02 | **$1.40** | $72.80 |
| 1024×1024 | flux-2-pro | $0.04 | **$2.80** | $145.60 |
| 2048×2048 | gemini-imagen4 | $0.08 | **$5.60** | $291.20 |

**권장**: 1024×1024 (Flux-2 Pro) - 품질과 비용의 균형

## ⏱️ 예상 소요 시간

- **70장 생성**: 약 30-40분
- **단일 카드**: 약 20-30초
- **Firebase 업로드**: 카드당 1-2초

## 🔧 중요: 실제 AI 통합 방법

현재 스크립트는 **시뮬레이션 모드**로 placeholder 이미지를 생성합니다.

### 실제 Genspark AI 통합

`generate_cards_with_ai.py` 파일의 `generate_single_card_image()` 메서드를 수정:

```python
def generate_single_card_image(self, card_concept: Dict, style: str) -> Optional[str]:
    """단일 카드 이미지 생성"""
    
    prompt = self.build_image_prompt(
        card_name=card_concept['name'],
        description=card_concept['description'],
        rarity=card_concept['rarity'],
        style=style
    )
    
    # ✅ 실제 Genspark AI 호출 (아래 방법 중 선택)
    
    # 방법 1: Genspark Python SDK 사용
    from genspark import ImageGeneration
    
    result = ImageGeneration.create(
        prompt=prompt,
        model='recraft-v3',
        aspect_ratio='1:1',
        quality='high'
    )
    
    return result.image_url
    
    # 방법 2: REST API 직접 호출
    import requests
    
    response = requests.post(
        'https://api.genspark.ai/v1/images/generate',
        headers={'Authorization': 'Bearer YOUR_API_KEY'},
        json={
            'model': 'recraft-v3',
            'prompt': prompt,
            'aspect_ratio': '1:1'
        }
    )
    
    return response.json()['image_url']
```

## 📁 파일 구조

```
scripts/ai_generation/
├── generate_cards_with_ai.py    # 메인 생성 스크립트
├── README.md                     # 사용 가이드 (이 파일)
└── examples/                     # 예제 스크립트 (추가 예정)
```

## 🔥 Firebase 구조

생성된 카드는 다음 경로에 저장됩니다:

```
Firestore:
  seasons/
    └── 2025_S1_v1/
        └── cards/
            ├── card_0
            ├── card_1
            └── ... (70 cards)

Storage:
  seasons/
    └── 2025_S1_v1/
        └── cards/
            ├── card_0.png
            ├── card_1.png
            └── ... (70 images)
```

## 🧪 테스트 모드

시뮬레이션 모드에서 테스트:

```bash
# 1초 지연으로 빠른 테스트 (placeholder 이미지)
python3 generate_cards_with_ai.py
```

## ⚠️ 주의사항

1. **Firebase 요금**: Storage 및 Firestore 사용량 확인
2. **AI 크레딧**: Genspark 크레딧 잔액 확인
3. **생성 시간**: 70장 생성에 30-40분 소요
4. **네트워크**: 안정적인 인터넷 연결 필요
5. **에러 처리**: 실패한 카드는 자동 재시도 없음 (수동 재생성)

## 🆘 문제 해결

### Firebase 연결 실패
```bash
# Firebase key 경로 확인
ls -la /opt/flutter/firebase-admin-sdk.json

# 권한 확인
chmod 644 /opt/flutter/firebase-admin-sdk.json
```

### AI 생성 실패
- Genspark 크레딧 확인
- API 키 유효성 확인
- 네트워크 연결 확인
- 프롬프트 길이 확인 (최대 2000자)

### Storage 업로드 실패
- Firebase Storage 규칙 확인
- 파일 크기 제한 확인 (최대 5MB)
- 네트워크 속도 확인

## 📞 지원

- **Firebase Console**: https://console.firebase.google.com/project/weeklygacha-24683
- **Genspark Dashboard**: https://www.genspark.ai/
- **GitHub Issues**: (저장소 링크)

---

**마지막 업데이트**: 2025-01-22  
**버전**: 1.0.0  
**작성자**: Weekly Gacha Development Team
