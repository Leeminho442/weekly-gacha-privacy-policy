# 🚀 Weekly Gacha - Google Play Store 출시 체크리스트

**버전**: v2.8.5 (Build 22)  
**마지막 업데이트**: 2024년 12월 11일

---

## ✅ 1. APK/AAB 빌드 파일

### 현재 상태: ✅ 완료

**APK 파일 (테스트용)**
- ✅ 파일 위치: `build/app/outputs/flutter-apk/app-release.apk`
- ✅ 파일 크기: 87MB
- ✅ 서명: 원본 keystore로 서명 완료
- ✅ 버전: v2.8.5 (Build 22)

**AAB 파일 필요 (Google Play Console 업로드용)**
- ⏳ 생성 필요: `flutter build appbundle --release`

---

## ✅ 2. Keystore 정보

### 현재 상태: ✅ 완료

```
📋 Keystore 정보:
파일명: release-key.jks
위치: /home/user/flutter_app/android/release-key.jks
백업 위치: /home/user/uploaded_files/WeeklyGacha_KEYSTORE (1).jks

🔐 인증 정보:
Store Password: weeklygacha2024
Key Password: weeklygacha2024
Key Alias: weeklygacha

🔑 SHA 지문:
SHA1: D0:44:6B:FB:20:05:2C:5B:74:30:D1:48:7A:84:3D:F3:37:21:0A:6D
SHA256: 5D:72:E3:D3:BB:25:B8:76:67:56:36:00:C9:6C:6F:50:11:25:9A:AD:9A:11:FE:A4:54:29:A9:CF:52:62:26:61

⏰ 유효기간: 2053년까지
```

**⚠️ 중요**: Keystore를 안전하게 백업하고 비밀번호를 보관하세요!

---

## ✅ 3. 개인정보방침

### 현재 상태: ✅ 완료

- ✅ GitHub 저장소: https://github.com/Leeminho442/weekly-gacha-privacy-policy
- ✅ 공개 URL: https://leeminho442.github.io/weekly-gacha-privacy-policy/
- ✅ 마지막 업데이트: 2024년 12월 10일
- ✅ 준수 사항:
  - Google Play Store 요구사항 ✅
  - GDPR (유럽) ✅
  - CCPA (캘리포니아) ✅
  - COPPA (아동 보호법) ✅

**개인정보방침 내용 확인:**
- ✅ 수집하는 정보 명시 (Google 계정, 기기 정보, 광고 ID)
- ✅ 정보 사용 목적 명시
- ✅ 제3자 서비스 공개 (Firebase, AdMob)
- ✅ 사용자 권리 명시
- ✅ 데이터 보안 조치 설명
- ✅ 연락처 정보 포함

**❗수정 필요**:
- ⚠️ 이메일 주소 업데이트 필요: `[Your Email Address]` → 실제 이메일
- ⚠️ 개발자 이름 확인: "Weekly Gacha Team"

---

## 📋 4. Google Play Console 필수 항목

### A. 앱 기본 정보

**✅ 완료된 항목:**
- ✅ 앱 이름: Weekly Gacha
- ✅ 패키지명: com.mycompany.weeklygacha
- ✅ 카테고리: 엔터테인먼트

**📝 작성 필요:**
- ⏳ 짧은 설명 (80자 이내)
- ⏳ 전체 설명 (4000자 이내)
- ⏳ 개발자 이름
- ⏳ 개발자 이메일
- ⏳ 개발자 웹사이트 (선택사항)

**권장 짧은 설명:**
```
매주 새로운 테마의 디지털 포토카드를 무료로 수집하는 가챠 앱
```

**권장 전체 설명:**
```
🎴 Weekly Gacha - 매주 새로운 카드를 수집하세요!

Weekly Gacha는 매주 새로운 테마의 디지털 포토카드를 무료로 뽑을 수 있는 수집 앱입니다.

✨ 주요 기능:
• 매주 새로운 테마의 카드 등장
• 무료 가챠 시스템
• 나만의 카드 컬렉션 구축
• 친구 초대 시스템 (보너스 티켓 지급)
• Google 계정으로 간편 로그인
• 클라우드 동기화로 어디서나 컬렉션 확인

🎮 게임 방식:
1. 매주 월요일 새로운 테마 카드 공개
2. 무료 가챠로 랜덤 카드 획득
3. 희귀도별 카드 수집 (일반/레어/슈퍼레어/전설)
4. 컬렉션 완성도 확인

🎁 특별 혜택:
• 매일 무료 가챠 티켓 제공
• 출석 보상으로 추가 티켓 획득
• 쿠폰 시스템으로 특별 카드 획득
• 친구 초대로 보너스 티켓 받기

💎 프리미엄 기능 (선택사항):
• 광고 시청으로 추가 티켓 획득
• AI 카드 생성 기능 (직접 카드 디자인)

지금 바로 Weekly Gacha를 다운로드하고 
나만의 특별한 카드 컬렉션을 시작하세요!
```

---

### B. 그래픽 자료 (매우 중요!)

**❌ 필수 생성 항목:**

**1. 앱 아이콘**
- ✅ 완료: 512x512 PNG (투명 배경 없음)
- 위치: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

**2. 스크린샷** (최소 2개, 최대 8개)
- ⏳ 필요: 휴대전화 스크린샷 (최소 2개)
  - 권장 크기: 1080x1920 (9:16 비율)
  - 권장 화면:
    1. 메인 화면 (가챠 화면)
    2. 컬렉션 화면
    3. 카드 상세 화면
    4. 친구 초대 화면

**3. 기능 그래픽** (필수)
- ⏳ 필요: 1024x500 PNG
- Play Store 상단에 표시되는 배너 이미지
- 앱의 핵심 기능을 시각적으로 표현

**4. 홍보 동영상** (선택사항, 권장)
- ⏳ 권장: YouTube 동영상 링크
- 30초~2분 길이
- 앱 사용 방법 및 주요 기능 소개

---

### C. 콘텐츠 등급 설정

**⏳ 작성 필요:**

Google Play의 콘텐츠 등급 설문지 작성:

**Weekly Gacha 예상 답변:**
- 폭력성: 없음
- 선정성: 없음
- 약물: 없음
- 도박: ⚠️ **가챠 시스템 관련 확인 필요**
  - 랜덤 보상: 있음 (가챠)
  - 실제 화폐 사용: 없음 (무료 앱)
  - 결론: "시뮬레이션된 도박" 항목 확인

**예상 등급**: 전체 이용가 또는 만 3세 이상

---

### D. 개인정보 보호 및 보안

**✅ 완료된 항목:**
- ✅ 개인정보처리방침 URL 제공
- ✅ 데이터 수집 항목 명시

**⏳ Google Play Console에서 작성 필요:**

**데이터 보안 섹션 답변:**

1. **앱에서 사용자 데이터를 수집하거나 공유하나요?**
   - ✅ 예

2. **수집하는 데이터 유형:**
   - ✅ 개인 정보: 이름, 이메일 주소
   - ✅ 기기 ID: 광고 ID
   - ✅ 앱 활동: 앱 상호작용

3. **데이터 수집 목적:**
   - ✅ 앱 기능
   - ✅ 분석
   - ✅ 광고 또는 마케팅

4. **데이터 공유:**
   - ✅ 예 (Firebase, AdMob)

5. **보안 관행:**
   - ✅ 전송 중 데이터 암호화
   - ✅ 사용자가 데이터 삭제 요청 가능

---

### E. 앱 액세스 권한

**✅ 현재 앱에서 사용하는 권한:**
- ✅ 인터넷 액세스 (INTERNET)
- ✅ 네트워크 상태 확인 (ACCESS_NETWORK_STATE)

**⏳ Google Play Console에서 설명 필요:**
각 권한에 대한 사용 이유를 명확히 설명해야 합니다.

**권한 설명 예시:**
```
INTERNET: Firebase 클라우드 동기화 및 광고 표시
ACCESS_NETWORK_STATE: 네트워크 연결 상태 확인하여 오프라인 모드 지원
```

---

### F. 광고 관련 정보

**✅ 완료:**
- ✅ Google AdMob 통합
- ✅ 개인정보방침에 광고 관련 내용 포함

**⏳ Google Play Console에서 선언 필요:**
- ⏳ "앱에 광고가 포함되어 있습니다" 체크
- ⏳ 광고 SDK: Google AdMob

---

## 🔥 5. Firebase 설정 확인

### 현재 상태: ✅ 완료

**✅ 완료된 항목:**
- ✅ Firebase 프로젝트 생성
- ✅ google-services.json 파일 추가
- ✅ Firebase Authentication (Google Sign-In)
- ✅ Cloud Firestore 데이터베이스
- ✅ Firebase Storage

**⏳ SHA 지문 등록 확인 필요:**
1. Firebase Console → 프로젝트 설정 → 내 앱
2. Android 앱 선택
3. SHA 인증서 지문 추가:
   - SHA-1: `D0:44:6B:FB:20:05:2C:5B:74:30:D1:48:7A:84:3D:F3:37:21:0A:6D`
   - SHA-256: `5D:72:E3:D3:BB:25:B8:76:67:56:36:00:C9:6C:6F:50:11:25:9A:AD:9A:11:FE:A4:54:29:A9:CF:52:62:26:61`

---

## 🎨 6. 앱 아이콘 및 브랜딩

### 현재 상태: ✅ 완료

- ✅ 앱 아이콘 설정 완료
- ✅ Adaptive icon 지원
- ✅ 다양한 해상도 아이콘 생성

---

## 📱 7. 테스트 및 품질 보증

### 테스트 체크리스트

**⏳ 출시 전 테스트 필요:**

**기능 테스트:**
- ⏳ 회원가입/로그인 (Google Sign-In)
- ⏳ 가챠 뽑기 기능
- ⏳ 컬렉션 조회
- ⏳ 쿠폰 사용
- ⏳ 친구 초대 기능
- ⏳ 광고 시청 (보상형 광고)
- ⏳ 계정 삭제

**호환성 테스트:**
- ⏳ Android 5.0 (API 21) 이상 기기
- ⏳ 다양한 화면 크기 (휴대폰, 태블릿)
- ⏳ 온라인/오프라인 모드

**성능 테스트:**
- ⏳ 앱 시작 시간
- ⏳ 메모리 사용량
- ⏳ 배터리 소모
- ⏳ 네트워크 사용량

---

## 📝 8. 법적 요구사항

### 현재 상태: ⚠️ 확인 필요

**✅ 완료:**
- ✅ 개인정보처리방침 작성

**⏳ 확인 필요:**
- ⏳ 이용약관 (선택사항이지만 권장)
- ⏳ 저작권 정보
- ⏳ 오픈소스 라이선스 (Flutter 및 패키지)

**오픈소스 라이선스 확인:**
```bash
flutter pub licenses > licenses.txt
```

---

## 🚀 9. 출시 전 최종 체크리스트

### AAB 파일 생성 및 업로드

**⏳ 필수 작업:**

1. **AAB 파일 빌드**
```bash
flutter build appbundle --release
```

2. **Google Play Console 접속**
   - https://play.google.com/console

3. **새 앱 등록**
   - 앱 이름: Weekly Gacha
   - 기본 언어: 한국어
   - 앱/게임: 게임
   - 무료/유료: 무료

4. **AAB 파일 업로드**
   - 프로덕션 → 릴리스 만들기
   - AAB 파일 업로드: `build/app/outputs/bundle/release/app-release.aab`

5. **스토어 등록정보 작성**
   - 앱 이름
   - 짧은 설명
   - 전체 설명
   - 스크린샷 (최소 2개)
   - 기능 그래픽
   - 앱 아이콘

6. **콘텐츠 등급 설정**
   - 설문지 작성
   - 등급 확인

7. **개인정보 보호 설정**
   - 개인정보처리방침 URL: https://leeminho442.github.io/weekly-gacha-privacy-policy/
   - 데이터 보안 섹션 작성

8. **가격 및 배포 설정**
   - 국가 선택
   - 가격 설정 (무료)

9. **검토 제출**
   - 모든 항목 완료 확인
   - 검토 요청

---

## ⚠️ 중요 주의사항

### 1. Keystore 관리
- ✅ **절대 잃어버리지 마세요!**
- ✅ 여러 곳에 백업
- ✅ 비밀번호 안전하게 보관

### 2. 개인정보방침
- ⚠️ 이메일 주소 업데이트 필요
- ✅ URL 접근 가능한지 확인
- ✅ 내용이 앱 기능과 일치하는지 확인

### 3. 그래픽 자료
- ⏳ 스크린샷 최소 2개 필수
- ⏳ 기능 그래픽 필수
- ✅ 고해상도 이미지 사용

### 4. 테스트
- ⏳ 실제 기기에서 APK 테스트
- ⏳ 모든 기능 동작 확인
- ⏳ 크래시 없는지 확인

### 5. 광고
- ✅ AdMob 설정 완료
- ⏳ 광고 정책 준수 확인
- ⏳ 아동 대상 광고 설정 확인

---

## 📞 도움이 필요한 경우

**Google Play Console 도움말:**
- https://support.google.com/googleplay/android-developer

**Firebase 문서:**
- https://firebase.google.com/docs

**Flutter 문서:**
- https://docs.flutter.dev

---

## 🎯 다음 단계

### 즉시 해야 할 작업:

1. **AAB 파일 빌드**
   ```bash
   cd /home/user/flutter_app
   flutter build appbundle --release
   ```

2. **스크린샷 준비**
   - 앱 실행 후 주요 화면 캡처
   - 1080x1920 해상도로 준비

3. **기능 그래픽 제작**
   - 1024x500 크기
   - 앱의 핵심 기능 표현

4. **개인정보방침 이메일 업데이트**
   - README.md 파일에서 `[Your Email Address]` 수정

5. **Google Play Console 계정 생성**
   - https://play.google.com/console
   - 일회성 등록비 $25 결제

---

## ✅ 최종 체크리스트

출시 전 모든 항목을 확인하세요:

- [ ] AAB 파일 빌드 완료
- [ ] Keystore 백업 완료
- [ ] 개인정보방침 URL 확인
- [ ] 스크린샷 준비 (최소 2개)
- [ ] 기능 그래픽 준비 (1024x500)
- [ ] 앱 설명 작성
- [ ] 개발자 이메일 설정
- [ ] 콘텐츠 등급 설정
- [ ] 데이터 보안 섹션 작성
- [ ] 실제 기기 테스트 완료
- [ ] Firebase SHA 지문 등록
- [ ] Google Play Console 계정 생성
- [ ] 모든 기능 정상 동작 확인

---

**📅 예상 심사 기간**: 3-7일  
**🎉 출시 준비 거의 완료!**

---

*마지막 업데이트: 2024년 12월 11일*  
*버전: v2.8.5*
