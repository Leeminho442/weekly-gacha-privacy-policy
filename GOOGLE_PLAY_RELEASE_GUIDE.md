# 📱 Weekly Gacha - Google Play Store 출시 가이드

## 🎯 빌드 완료 상태

### ✅ 완료된 항목
- [x] Release AAB 빌드 (Google Play 업로드용)
- [x] Release APK 빌드 (테스트용)
- [x] 앱 서명 keystore 생성 및 설정
- [x] Firebase 인증 (Google Sign-In) 통합
- [x] Google AdMob 광고 통합
- [x] 앱 아이콘 설정

---

## 📦 빌드 파일 정보

### 1. **AAB 파일** (Google Play Console 업로드용)
- **파일 경로**: `build/app/outputs/bundle/release/app-release.aab`
- **파일 크기**: 77MB
- **용도**: Google Play Console에 업로드하는 공식 배포 파일

### 2. **APK 파일** (테스트용)
- **파일 경로**: `build/app/outputs/flutter-apk/app-release.apk`
- **파일 크기**: 87MB
- **용도**: 실제 기기에서 테스트할 때 사용

---

## 🔐 Keystore 정보 (매우 중요!)

### **절대 잃어버리지 마세요!**

```
📋 Keystore 상세 정보:
- 파일명: WeeklyGacha_KEYSTORE.jks
- 백업 위치: /home/user/release_backup/WeeklyGacha_KEYSTORE.jks
- Store Password: weeklygacha2024
- Key Password: weeklygacha2024
- Key Alias: weeklygacha

🔑 SHA 지문 (Firebase/Google Services 연동시 필요):
- SHA1: D0:44:6B:FB:20:05:2C:5B:74:30:D1:48:7A:84:3D:F3:37:21:0A:6D
- SHA256: 5D:72:E3:D3:BB:25:B8:76:67:56:36:00:C9:6C:6F:50:11:25:9A:AD:9A:11:FE:A4:54:29:A9:CF:52:62:26:61

⏰ 유효기간: 2053년까지 (27년)
```

**⚠️ 중요 경고:**
- 이 keystore를 잃어버리면 앱 업데이트를 할 수 없습니다!
- 반드시 안전한 곳에 여러 개 백업해두세요!
- 비밀번호도 함께 보관하세요!

---

## 📱 앱 정보

### 기본 정보
- **앱 이름**: Weekly Gacha
- **패키지명**: com.mycompany.weeklygacha
- **버전**: 2.7.1 (빌드 번호: 8)
- **카테고리**: 엔터테인먼트 / 수집

### 앱 설명 (제안)

**한줄 소개:**
"매주 바뀌는 무료 디지털 포토카드 가챠 앱"

**상세 설명:**
```
🎴 Weekly Gacha - 매주 새로운 카드를 수집하세요!

Weekly Gacha는 매주 새로운 테마의 디지털 포토카드를 무료로 뽑을 수 있는 수집 앱입니다.

✨ 주요 기능:
• 매주 새로운 테마의 카드 등장
• 무료 가챠 시스템
• 나만의 카드 컬렉션 구축
• 친구들과 카드 공유
• Google 계정으로 간편 로그인
• 클라우드 동기화로 어디서나 컬렉션 확인

🎮 게임 방식:
1. 매주 월요일 새로운 테마 카드 공개
2. 무료 가챠로 랜덤 카드 획득
3. 희귀도별 카드 수집 (일반/레어/슈퍼레어)
4. 컬렉션 완성도 확인

🎁 특별 혜택:
• 매일 무료 가챠 티켓 제공
• 출석 보상으로 추가 티켓 획득
• 쿠폰 시스템으로 특별 카드 획득

지금 바로 Weekly Gacha를 다운로드하고 
나만의 특별한 카드 컬렉션을 시작하세요!
```

---

## 🖼️ Google Play Console 등록 필수 자료

### 1. **스크린샷** (필수)
Play Console에 최소 2개 이상의 스크린샷이 필요합니다:

**필요한 스크린샷:**
- [ ] 메인 화면 (가챠 화면)
- [ ] 카드 컬렉션 화면
- [ ] 카드 상세 화면
- [ ] 로그인 화면
- [ ] 쿠폰/이벤트 화면

**스크린샷 요구사항:**
- 최소 크기: 320px
- 최대 크기: 3840px
- 종횡비: 16:9 또는 9:16 권장
- 파일 형식: PNG 또는 JPG

**스크린샷 촬영 방법:**
1. 실제 기기나 에뮬레이터에서 APK 설치
2. 각 주요 화면을 캡처
3. 필요시 텍스트/설명 추가 (선택사항)

### 2. **앱 아이콘**
- [x] 이미 설정되어 있음 (Android 리소스에 포함)
- 512x512 PNG 형식 (Google Play Console용)

### 3. **프로모션 그래픽** (권장)
- 크기: 1024 x 500 픽셀
- 앱 소개 이미지 (Featured Graphic)

---

## 🔒 개인정보처리방침 & 서비스 약관

### **필수 작성 항목**

Google Play Console에서 요구하는 필수 항목:

#### 1. **개인정보처리방침** (Privacy Policy)
앱이 수집하는 정보:
- Google 계정 정보 (이메일, 이름, 프로필 사진)
- Firebase 인증 데이터
- 게임 진행 데이터 (카드 컬렉션, 가챠 기록)
- 광고 ID (AdMob)

**개인정보처리방침 URL이 필요합니다!**
- 웹사이트나 GitHub Pages에 호스팅
- 또는 Google Sites로 무료 생성 가능

#### 2. **서비스 약관** (Terms of Service)
- 앱 사용 규칙
- 계정 정책
- 환불 정책 (해당시)

---

## 📤 Google Play Console 업로드 단계

### Step 1: Google Play Console 접속
1. [Google Play Console](https://play.google.com/console) 접속
2. 개발자 계정으로 로그인
3. "앱 만들기" 클릭

### Step 2: 앱 기본 정보 입력
- **앱 이름**: Weekly Gacha
- **기본 언어**: 한국어
- **앱 유형**: 앱
- **무료/유료**: 무료

### Step 3: 앱 콘텐츠 설정
1. **앱 카테고리**: 엔터테인먼트
2. **콘텐츠 등급**: 모든 연령 (또는 PEGI 3 이상)
3. **개인정보처리방침 URL**: (준비 필요)

### Step 4: AAB 파일 업로드
1. "프로덕션" → "출시 만들기" 선택
2. **app-release.aab** 파일 업로드
3. 출시 노트 작성:
   ```
   v2.7.1 - 첫 출시
   • 매주 새로운 카드 테마
   • 무료 가챠 시스템
   • Google 로그인 지원
   • 클라우드 동기화
   ```

### Step 5: 스토어 등록정보 작성
1. 앱 이름, 설명, 스크린샷 업로드
2. 아이콘 업로드 (512x512)
3. 카테고리 및 태그 설정

### Step 6: 가격 및 배포 설정
1. 국가/지역 선택 (한국, 전 세계 등)
2. 무료 앱으로 설정
3. 콘텐츠 등급 완성

### Step 7: 검토 제출
1. 모든 필수 항목 완성 확인
2. "검토 제출" 클릭
3. Google 검토 대기 (보통 1-3일 소요)

---

## 🚀 출시 전 체크리스트

### 필수 항목
- [x] AAB 파일 빌드 완료
- [x] APK 파일 빌드 완료 (테스트용)
- [x] Keystore 안전하게 백업
- [x] Firebase 설정 완료
- [x] AdMob 설정 완료
- [ ] 스크린샷 준비 (최소 2개)
- [ ] 개인정보처리방침 URL 준비
- [ ] 앱 설명 작성
- [ ] 콘텐츠 등급 완료

### 선택 항목
- [ ] 프로모션 그래픽 (1024x500)
- [ ] 앱 프리뷰 동영상
- [ ] 서비스 약관 문서
- [ ] 웹사이트 URL

---

## 🔧 Firebase SHA 지문 등록

Google Sign-In이 제대로 작동하려면 Firebase Console에 SHA 지문을 등록해야 합니다:

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. Weekly Gacha 프로젝트 선택
3. 프로젝트 설정 → 앱 설정
4. "SHA 인증서 지문 추가" 클릭
5. 아래 지문 등록:
   ```
   SHA1: D0:44:6B:FB:20:05:2C:5B:74:30:D1:48:7A:84:3D:F3:37:21:0A:6D
   SHA256: 5D:72:E3:D3:BB:25:B8:76:67:56:36:00:C9:6C:6F:50:11:25:9A:AD:9A:11:FE:A4:54:29:A9:CF:52:62:26:61
   ```
6. google-services.json 다시 다운로드 (필요시)

---

## 💡 추가 권장 사항

### 1. **베타 테스트** (권장)
정식 출시 전에 베타 테스트를 진행하세요:
- Play Console에서 "비공개 테스트" 또는 "공개 테스트" 트랙 생성
- 소수의 사용자에게 먼저 배포
- 피드백 수집 후 정식 출시

### 2. **앱 업데이트 계획**
- 매주 새로운 카드 테마 추가
- 사용자 피드백 반영
- 버그 수정 및 성능 개선
- 버전 번호 규칙: Major.Minor.Patch+Build

### 3. **마케팅 전략**
- SNS 홍보 (Instagram, Twitter 등)
- 카드 디자인 미리보기 공개
- 출시 이벤트 (특별 쿠폰 배포)
- 인플루언서 협업

---

## 📞 문제 해결

### Q: Google Sign-In이 작동하지 않아요
A: Firebase Console에 SHA 지문이 올바르게 등록되었는지 확인하세요.

### Q: 앱 업데이트는 어떻게 하나요?
A: 
1. `pubspec.yaml`에서 version 업데이트 (예: 2.7.2+9)
2. 같은 keystore로 새 AAB 빌드
3. Play Console에서 새 버전 업로드

### Q: Keystore를 잃어버렸어요
A: 
- Play Console의 "App Signing by Google Play" 사용시 복구 가능
- 그렇지 않으면 새 앱으로 재출시 필요

---

## ✅ 최종 요약

**현재 완료된 작업:**
1. ✅ Release AAB/APK 빌드 완료
2. ✅ Keystore 생성 및 백업
3. ✅ Firebase 인증 설정
4. ✅ AdMob 광고 통합

**다음 단계:**
1. 📸 스크린샷 촬영 (최소 2개)
2. 📝 개인정보처리방침 작성 및 호스팅
3. 🔑 Firebase Console에 SHA 지문 등록
4. 📤 Google Play Console에 AAB 업로드
5. 🎯 검토 제출 및 출시 대기

---

**🎉 거의 다 왔습니다! 조금만 더 힘내세요!**

출시 과정에서 궁금한 점이 있으시면 언제든지 문의하세요.

---

*생성일: 2025-12-10*
*버전: 2.7.1+8*
