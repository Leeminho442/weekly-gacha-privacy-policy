# 🔒 Firebase Admin SDK 보안 가이드

## ⚠️ **중요: Firebase Admin SDK 키 보안**

### **Firebase Admin SDK란?**
- **서버 측** Firebase 전체 제어 권한
- Firestore, Storage, Auth 등 **모든 데이터 접근 가능**
- **사용자 인증 없이** 모든 작업 가능

### **위험성**
```
❌ Admin SDK 키가 노출되면:
✗ Firestore 전체 데이터 읽기/쓰기/삭제
✗ Storage 모든 파일 접근/삭제
✗ 사용자 인증 정보 조작
✗ Firebase 프로젝트 완전 제어
✗ 과금 폭탄 가능
```

**절대 하면 안 되는 것:**
- ❌ GitHub에 커밋
- ❌ 공개 저장소에 업로드
- ❌ 클라이언트 앱에 포함
- ❌ 브라우저에서 노출

---

## ✅ **안전한 AI 카드 생성 방법**

### **권장: Option 1 - Flutter 앱에서 직접 생성 (Admin SDK 불필요)**

Flutter 앱은 이미 **사용자 인증 + Firebase Security Rules**로 보호되어 있습니다.

#### **장점**
- ✅ Admin SDK 키 불필요
- ✅ Firebase Security Rules로 보호
- ✅ 사용자 인증 기반 접근 제어
- ✅ 클라이언트 측에서 안전하게 작동

#### **구현 방법**

**1. Flutter 앱에서 직접 AI 생성**

`lib/services/ai_image_generator.dart`는 이미 준비되어 있습니다:

```dart
// ✅ 이미 구현된 메서드
Future<String> _generateCardImage(...) async {
  // Genspark AI 호출 (Admin SDK 불필요)
  // Firebase Storage 업로드 (현재 사용자 인증 사용)
  // Firestore 저장 (Security Rules 적용)
}
```

**2. Firebase Security Rules 설정**

**Firestore Rules** (관리자만 카드 생성 가능):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 관리자 확인 함수
    function isAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // 카드 생성: 관리자만
    match /seasons/{seasonId}/cards/{cardId} {
      allow read: if true;  // 모든 사용자 읽기 가능
      allow write: if isAdmin();  // 관리자만 쓰기
    }
    
    // 관리자 목록
    match /admins/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false;  // 콘솔에서만 수정
    }
  }
}
```

**Storage Rules** (관리자만 업로드):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 카드 이미지: 관리자만 업로드, 모두 읽기
    match /seasons/{seasonId}/cards/{cardImage} {
      allow read: if true;
      allow write: if request.auth != null && 
                     firestore.get(/databases/(default)/documents/admins/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

**3. 관리자 등록 (Firebase Console)**

```javascript
// Firestore에 수동으로 추가
admins/
  └── {YOUR_USER_ID}
      └── isAdmin: true
```

**4. Flutter 앱에서 실행**

이미 구현되어 있으므로 **바로 사용 가능**:
1. 관리자 로그인 (로고 5번 탭)
2. "AI 카드 생성 마법사" 클릭
3. 5단계 진행
4. 생성 시작!

---

### **Option 2 - Backend 스크립트 (로컬에서만 사용)**

Backend Python 스크립트를 **로컬 개발 환경**에서만 사용:

#### **안전한 사용 방법**

**1. .gitignore 설정**

```bash
# .gitignore에 추가 (이미 되어있는지 확인)
cd /home/user/flutter_app

# Admin SDK 키 제외
echo "*firebase-admin-sdk*.json" >> .gitignore
echo "*serviceAccountKey*.json" >> .gitignore
echo "scripts/ai_generation/.env" >> .gitignore
```

**2. 환경 변수 사용**

```bash
# .env 파일 생성 (Git 추적 안 함)
cat > scripts/ai_generation/.env << 'EOF'
FIREBASE_ADMIN_KEY_PATH=/opt/flutter/firebase-admin-sdk.json
FIREBASE_STORAGE_BUCKET=weeklygacha-24683.firebasestorage.app
EOF

# .gitignore에 추가
echo "scripts/ai_generation/.env" >> .gitignore
```

**3. 스크립트 수정 (환경 변수 사용)**

```python
import os
from dotenv import load_dotenv

load_dotenv()

class AICardGenerator:
    def __init__(self):
        # 환경 변수에서 로드
        key_path = os.getenv('FIREBASE_ADMIN_KEY_PATH', '/opt/flutter/firebase-admin-sdk.json')
        
        if not os.path.exists(key_path):
            raise FileNotFoundError(f"Admin SDK key not found: {key_path}")
```

**4. 로컬에서만 실행**

```bash
# 로컬 개발 환경에서만 사용
python3 scripts/ai_generation/generate_cards_with_ai.py
```

---

### **Option 3 - 서버리스 함수 (프로덕션 권장)**

**Firebase Cloud Functions** 사용:

#### **장점**
- ✅ Admin SDK를 서버에서만 사용
- ✅ 클라이언트에 키 노출 없음
- ✅ HTTP 트리거로 안전하게 호출
- ✅ 자동 스케일링

#### **구현 예시**

**Firebase Functions (Node.js):**

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.generateAICards = functions.https.onCall(async (data, context) => {
  // 관리자 권한 확인
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
  }
  
  const adminDoc = await admin.firestore()
    .collection('admins')
    .doc(context.auth.uid)
    .get();
  
  if (!adminDoc.exists || !adminDoc.data().isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Not admin');
  }
  
  // AI 카드 생성 로직
  const { mode, theme, style } = data;
  
  // 1. AI 이미지 생성 (Genspark API 호출)
  // 2. Storage 업로드
  // 3. Firestore 저장
  
  return { success: true, cardCount: 70 };
});
```

**Flutter에서 호출:**

```dart
final callable = FirebaseFunctions.instance.httpsCallable('generateAICards');

try {
  final result = await callable.call({
    'mode': 'evolution',
    'theme': '진화하는 몬스터',
    'style': 'cute',
  });
  
  print('✅ ${result.data['cardCount']} cards generated!');
} catch (e) {
  print('❌ Error: $e');
}
```

---

## 🎯 **최종 권장사항**

### **개발/테스트 단계**
→ **Option 1 (Flutter 앱 직접 생성)** 권장
- ✅ 가장 간단
- ✅ Admin SDK 불필요
- ✅ Security Rules로 보호

### **프로덕션 단계**
→ **Option 3 (Cloud Functions)** 권장
- ✅ 가장 안전
- ✅ 스케일링 자동
- ✅ 비용 효율적

### **로컬 테스트**
→ **Option 2 (Backend 스크립트)** 사용 가능
- ⚠️ 절대 GitHub에 업로드하지 말 것
- ⚠️ .gitignore 필수
- ⚠️ 로컬 환경에서만 사용

---

## 📋 **보안 체크리스트**

### **Admin SDK 키 관련**
- [ ] .gitignore에 `*firebase-admin-sdk*.json` 추가
- [ ] GitHub에 키 파일 업로드되지 않았는지 확인
- [ ] 환경 변수 사용 (.env 파일)
- [ ] .env 파일도 .gitignore에 추가

### **Firebase Security Rules**
- [ ] Firestore Rules: 관리자만 쓰기
- [ ] Storage Rules: 관리자만 업로드
- [ ] 관리자 목록 Firestore에 등록

### **클라이언트 앱**
- [ ] API 키는 public (정상)
- [ ] Admin SDK 키는 포함하지 않음
- [ ] 사용자 인증 기반 접근 제어

---

## 🔍 **현재 프로젝트 확인**

```bash
# Admin SDK 키가 Git에 포함되었는지 확인
cd /home/user/flutter_app
git ls-files | grep -i "firebase-admin\|serviceAccount"

# 결과가 없으면 안전 ✅
# 결과가 있으면 즉시 제거 필요 ❌
```

**만약 이미 커밋되었다면:**

```bash
# Git 히스토리에서 완전 제거
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch *firebase-admin-sdk*.json" \
  --prune-empty --tag-name-filter cat -- --all

# 강제 푸시
git push origin --force --all
```

---

## 💡 **요약**

**가장 안전하고 간단한 방법:**

1. **Admin SDK 키 사용하지 않기** (Option 1)
   - Flutter 앱에서 직접 생성
   - Firebase Security Rules로 보호
   - 이미 구현되어 있음

2. **테스트가 필요하다면**
   - 로컬에서만 Backend 스크립트 사용
   - .gitignore 설정 필수
   - GitHub에 절대 업로드하지 않기

3. **프로덕션에서는**
   - Firebase Cloud Functions 사용
   - 서버에서 Admin SDK 사용
   - 클라이언트는 HTTP 호출만

---

**결론: Admin SDK 키는 업로드하지 않아도 됩니다!**  
Flutter 앱에서 이미 안전하게 작동 가능한 구조입니다. 🔒✅
