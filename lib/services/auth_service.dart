import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum LoginProvider {
  none,
  google,
  kakao,
}

class AuthService {
  static const String _loginProviderKey = 'login_provider';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // ✅ CRITICAL: Use Web client ID (Type 3) for serverClientId
    serverClientId: '664327874488-kibd36jqh1e5fse8b3250u6geeebj2ef.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 싱글톤 패턴
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 현재 사용자
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  
  // 로그인 여부 확인
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // 구글 로그인 (웹/모바일 분기 처리)
  Future<UserCredential?> loginWithGoogle() async {
    try {
      UserCredential userCredential;
      
      if (kIsWeb) {
        // 웹 환경: Firebase Auth 팝업 사용
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });
        
        // 팝업으로 Google 로그인
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // 모바일 환경: GoogleSignIn 패키지 사용
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          // 사용자가 로그인 취소
          return null;
        }

        // Google 인증 정보 가져오기
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Firebase 인증 자격증명 생성
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Firebase에 로그인
        userCredential = await _auth.signInWithCredential(credential);
      }
      
      // 로그인 제공자 저장
      await _saveLoginProvider(LoginProvider.google);
      
      // Firestore에 사용자 정보 저장/업데이트
      await _updateUserInFirestore(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      print('Google login error: $e');
      rethrow;
    }
  }

  // 통합 로그인 메서드 (기존 코드 호환성 유지)
  Future<UserCredential?> login(LoginProvider provider) async {
    switch (provider) {
      case LoginProvider.google:
        return await loginWithGoogle();
      case LoginProvider.kakao:
        // 카카오 로그인은 나중에 구현
        throw UnimplementedError('카카오 로그인은 아직 구현되지 않았습니다.');
      default:
        return null;
    }
  }

  // Firestore에 사용자 정보 저장/업데이트
  Future<void> _updateUserInFirestore(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // 문서가 존재하는지 확인
    final docSnapshot = await userRef.get();
    
    if (docSnapshot.exists) {
      // 기존 사용자 - 로그인 시간만 업데이트
      await userRef.update(userData);
    } else {
      // 신규 사용자 - 전체 정보 생성
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['dailyPulls'] = 3;
      userData['bonusTickets'] = 0;
      userData['lastResetDate'] = FieldValue.serverTimestamp();
      await userRef.set(userData);
    }
  }

  // 로그아웃
  Future<void> logout() async {
    try {
      // Google Sign Out
      await _googleSignIn.signOut();
      
      // Firebase Sign Out
      await _auth.signOut();
      
      // SharedPreferences 정리
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginProviderKey);
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }

  // 사용자 정보 가져오기
  Future<Map<String, String?>> getUserInfo() async {
    final user = _auth.currentUser;
    
    if (user == null) {
      return {
        'userId': null,
        'userName': null,
        'email': null,
        'photoURL': null,
        'provider': null,
      };
    }
    
    final provider = await getLoginProvider();
    
    return {
      'userId': user.uid,
      'userName': user.displayName ?? 'User',
      'email': user.email,
      'photoURL': user.photoURL,
      'provider': provider.name,
    };
  }

  // 로그인 제공자 가져오기
  Future<LoginProvider> getLoginProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString(_loginProviderKey);
    
    if (providerName == null) return LoginProvider.none;
    
    return LoginProvider.values.firstWhere(
      (e) => e.name == providerName,
      orElse: () => LoginProvider.none,
    );
  }
  
  // 로그인 제공자 저장
  Future<void> _saveLoginProvider(LoginProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginProviderKey, provider.name);
  }

  // 사용자 데이터 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
