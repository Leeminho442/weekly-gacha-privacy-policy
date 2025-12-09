import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart';
import '../main.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoggingIn = false;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    
    // 애니메이션 설정
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(LoginProvider provider) async {
    if (_isLoggingIn) return;
    
    setState(() {
      _isLoggingIn = true;
    });
    
    // 🎵 사용자 인터랙션으로 즉시 BGM 시작 (웹 정책 준수)
    // await 없이 즉시 실행하여 브라우저 차단 방지
    _audioService.playBGM('main');
    
    // 🔊 버튼 클릭 효과음
    _audioService.playSFX('button_click');
    
    // 짧은 지연으로 오디오 시작 보장
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // 실제 Firebase 로그인 처리
      final authService = AuthService();
      final userCredential = await authService.login(provider);
      
      if (userCredential == null) {
        // 로그인 취소
        if (mounted) {
          setState(() {
            _isLoggingIn = false;
          });
        }
        return;
      }

      // 🔊 로그인 성공 효과음
      _audioService.playSFX('success');
      
      // 로그인 성공 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider == LoginProvider.google
                        ? '구글 로그인 성공! ${userCredential.user?.displayName ?? ""}님 환영합니다.'
                        : '카카오 로그인 성공!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // 메인 화면으로 이동 (AuthGate를 통해)
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          // AuthGate로 다시 라우팅하여 Provider와 함께 MainScreen 로드
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const AuthGate(),
            ),
            (route) => false, // 모든 이전 라우트 제거
          );
        }
      }
    } catch (e) {
      print('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade900,
              Colors.purple.shade600,
              Colors.pink.shade500,
              Colors.orange.shade400,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 배경 장식 - 반짝이는 별들
              ...List.generate(20, (index) {
                return Positioned(
                  left: (index * 37) % MediaQuery.of(context).size.width,
                  top: (index * 53) % MediaQuery.of(context).size.height,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Icon(
                      Icons.star,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 20 + (index % 3) * 10,
                    ),
                  ),
                );
              }),
              
              // 메인 컨텐츠
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 앱 아이콘
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.card_giftcard,
                              size: 60,
                              color: Colors.purple.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // 앱 타이틀
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Text(
                              'Weekly Gacha',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.bangers(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(3, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // 서브 타이틀
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '매주 새로운 한정판 카드를 수집하세요!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        
                        // 특징 설명
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              _buildFeatureItem(
                                Icons.calendar_today,
                                '매주 갱신되는\n신규 시즌',
                              ),
                              const SizedBox(height: 16),
                              _buildFeatureItem(
                                Icons.auto_awesome,
                                '희귀한 카드\n컬렉션',
                              ),
                              const SizedBox(height: 16),
                              _buildFeatureItem(
                                Icons.people,
                                '친구 초대로\n보너스 획득',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),
                        
                        // 로그인 버튼들
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                // 구글 로그인 버튼
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoggingIn
                                        ? null
                                        : () => _handleLogin(LoginProvider.google),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      shadowColor: Colors.black.withValues(alpha: 0.3),
                                    ),
                                    child: _isLoggingIn
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.purple,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.g_mobiledata,
                                                size: 32,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '구글로 시작하기',
                                                style: GoogleFonts.notoSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // 하단 안내 문구
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            '로그인하면 서비스 약관 및 개인정보 처리방침에\n동의하는 것으로 간주됩니다',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
