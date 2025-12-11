import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math' as math;
import '../providers/gacha_provider.dart';
import '../services/season_service.dart';
import '../services/admin_service.dart';
import '../services/admob_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import 'card_pack_opening_screen.dart';
import 'admin_dashboard_screen.dart';
import 'coupon_screen.dart';
import 'invite_screen.dart';
import 'intro_screen.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> with TickerProviderStateMixin {
  int _logoTapCount = 0;
  DateTime? _lastTapTime;
  static const Duration _tapTimeWindow = Duration(seconds: 3);
  static const int _requiredTaps = 5;
  
  // 스크롤 관련
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;
  
  // 보상형 광고 관련
  int _dailyAdCount = 0;
  static const int _maxDailyAds = 5;
  String? _lastAdDate;
  
  // 🎨 카드 배경 애니메이션 관련
  late AnimationController _cardAnimationController;
  late List<Animation<double>> _cardAnimations;
  static const int _cardCount = 8;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // 🎨 카드 배경 애니메이션 초기화
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _cardAnimations = List.generate(_cardCount, (index) {
      return Tween<double>(begin: -0.2, end: 1.2).animate(
        CurvedAnimation(
          parent: _cardAnimationController,
          curve: Interval(
            index * 0.1,
            0.8 + index * 0.1,
            curve: Curves.linear,
          ),
        ),
      );
    });
    
    // 화면 로드 후 스크롤 가능 여부 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
      _loadAdCount();
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _cardAnimationController.dispose(); // 🎨 애니메이션 컨트롤러 정리
    super.dispose();
  }
  
  void _scrollListener() {
    // 스크롤 위치 감지
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      setState(() {
        // 하단에서 50px 이상 떨어져 있으면 표시기 표시
        _showScrollIndicator = maxScroll - currentScroll > 50;
      });
    }
  }
  
  void _checkScrollable() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      setState(() {
        _showScrollIndicator = maxScroll > 0;
      });
    }
  }
  
  // 광고 시청 횟수 로드
  Future<void> _loadAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final savedDate = prefs.getString('last_ad_date') ?? '';
    
    if (savedDate == today) {
      setState(() {
        _dailyAdCount = prefs.getInt('daily_ad_count') ?? 0;
        _lastAdDate = savedDate;
      });
    } else {
      // 날짜가 바뀌면 초기화
      setState(() {
        _dailyAdCount = 0;
        _lastAdDate = today;
      });
      await prefs.setString('last_ad_date', today);
      await prefs.setInt('daily_ad_count', 0);
    }
  }
  
  // 광고 시청 횟수 증가
  Future<void> _incrementAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    
    setState(() {
      _dailyAdCount++;
      _lastAdDate = today;
    });
    
    await prefs.setString('last_ad_date', today);
    await prefs.setInt('daily_ad_count', _dailyAdCount);
  }

  Future<String> _getSeasonInfo() async {
    try {
      final seasonService = SeasonService();
      final season = await seasonService.getCurrentSeason();
      return 'Season ${season.seasonNumber} - D-${season.daysRemaining}';
    } catch (e) {
      return 'Season 1';
    }
  }

  void _onLogoTap() {
    final now = DateTime.now();
    
    if (_lastTapTime == null || now.difference(_lastTapTime!) > _tapTimeWindow) {
      // 타이머 초과, 카운트 리셋
      _logoTapCount = 1;
    } else {
      // 타이머 내 탭, 카운트 증가
      _logoTapCount++;
    }
    
    _lastTapTime = now;
    
    if (_logoTapCount >= _requiredTaps) {
      // 5번 탭 완료, 관리자 로그인 모달 표시
      _logoTapCount = 0;
      _showAdminPasswordDialog();
    }
  }

  void _showAdminPasswordDialog() {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            const Text('관리자 인증'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '관리자 비밀번호를 입력하세요',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '비밀번호',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              
              if (password == 'gigawifihomeax') {
                // 비밀번호 일치 - 관리자 로그인 처리
                final adminService = AdminService();
                await adminService.login(password);
                
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                }
              } else {
                // 비밀번호 불일치
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('잘못된 비밀번호입니다'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showProbabilityInfo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.purple.shade700, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    '등급별 확률 정보',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildProbabilityRow('노말', '70.0%', Colors.grey),
              const SizedBox(height: 12),
              _buildProbabilityRow('레어', '20.0%', Colors.blue),
              const SizedBox(height: 12),
              _buildProbabilityRow('슈퍼레어', '7.0%', Colors.purple),
              const SizedBox(height: 12),
              _buildProbabilityRow('울트라레어', '2.5%', Colors.orange),
              const SizedBox(height: 12),
              _buildProbabilityRow('시크릿', '0.5%', Colors.pink),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '총 확률: 100%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildProbabilityRow(String label, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade200,
              Colors.purple.shade200,
              Colors.blue.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<GachaProvider>(
            builder: (context, gachaProvider, child) {
              // 로딩 중일 때 로딩 인디케이터 표시
              if (gachaProvider.isLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        '데이터 로딩 중...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 로그아웃 버튼 (왼쪽)
                                  IconButton(
                                    icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                                    onPressed: () async {
                                      final shouldLogout = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('로그아웃'),
                                          content: const Text('정말 로그아웃하시겠습니까?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      
                                      if (shouldLogout == true && context.mounted) {
                                        try {
                                          // AuthService를 사용하여 로그아웃 (Google Sign In 포함)
                                          final authService = AuthService();
                                          await authService.logout();
                                          
                                          if (context.mounted) {
                                            // IntroScreen으로 직접 이동
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(builder: (context) => const IntroScreen()),
                                              (route) => false,
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('로그아웃 실패: $e')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _onLogoTap,
                                      child: Text(
                                        '위클리 갓챠',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10.0,
                                              color: Colors.purple,
                                              offset: const Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 우측 버튼들
                                  Row(
                                    children: [
                                      // 음소거 토글 버튼
                                      Container(
                                        width: 40,
                                        height: 40,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            AudioService().bgmEnabled || AudioService().sfxEnabled
                                                ? Icons.volume_up
                                                : Icons.volume_off,
                                            color: Colors.purple.shade700,
                                            size: 24,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            setState(() {
                                              // 둘 다 켜져있거나 하나라도 켜져있으면 모두 끄기
                                              final shouldMute = AudioService().bgmEnabled || AudioService().sfxEnabled;
                                              AudioService().toggleBGM(!shouldMute);
                                              AudioService().toggleSFX(!shouldMute);
                                            });
                                          },
                                          tooltip: '음소거',
                                        ),
                                      ),
                                      // 확률 정보 버튼
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.help_outline,
                                            color: Colors.purple.shade700,
                                            size: 24,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: _showProbabilityInfo,
                                          tooltip: '확률 정보',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Season Info
                              FutureBuilder<String>(
                                future: _getSeasonInfo(),
                                builder: (context, snapshot) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16, color: Colors.purple.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          snapshot.data ?? 'Loading...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.purple.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.favorite, color: Colors.pink),
                                        const SizedBox(width: 8),
                                        Text(
                                          '일일 무료: ${gachaProvider.dailyPulls}/3',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (gachaProvider.bonusTickets > 0) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.card_giftcard,
                                              color: Colors.orange, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            '보너스: ${gachaProvider.bonusTickets}개',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  '컬렉션: ${gachaProvider.totalCards}/${gachaProvider.totalPossibleCards}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center - 가챠 뽑기 버튼 (메인)
                        Expanded(
                          child: Stack(
                            children: [
                              // 🎨 배경 애니메이션 - 움직이는 카드 뒷면들
                              AnimatedBuilder(
                                animation: _cardAnimationController,
                                builder: (context, child) {
                                  return Stack(
                                    children: List.generate(_cardCount, (index) {
                                      final animation = _cardAnimations[index];
                                      final progress = animation.value;
                                      
                                      // 다양한 각도와 위치
                                      final angle = (index * 45.0) * 3.14159 / 180;
                                      final offsetX = (index % 3 - 1) * 100.0;
                                      
                                      return Positioned(
                                        left: MediaQuery.of(context).size.width * 0.5 + offsetX - 40,
                                        top: MediaQuery.of(context).size.height * progress,
                                        child: Transform.rotate(
                                          angle: angle,
                                          child: Opacity(
                                            opacity: (progress > 0.1 && progress < 0.9) ? 0.15 : 0.0,
                                            child: Container(
                                              width: 80,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade900,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.amber.shade300,
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.purple.withValues(alpha: 0.3),
                                                    blurRadius: 15,
                                                    spreadRadius: 3,
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.auto_awesome,
                                                  color: Colors.amber.shade200,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                              
                              // 메인 버튼 (앞에 배치)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // 가챠 뽑기 메인 버튼
                                    GestureDetector(
                                      onTap: gachaProvider.totalPulls > 0
                                          ? () => _performGacha(context, gachaProvider)
                                          : null,
                                      child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: gachaProvider.totalPulls > 0
                                            ? [
                                                Colors.pink.shade300,
                                                Colors.purple.shade400,
                                                Colors.deepPurple.shade500,
                                              ]
                                            : [
                                                Colors.grey.shade300,
                                                Colors.grey.shade400,
                                                Colors.grey.shade500,
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: gachaProvider.totalPulls > 0
                                          ? [
                                              BoxShadow(
                                                color: Colors.purple.withValues(alpha: 0.6),
                                                blurRadius: 40,
                                                spreadRadius: 15,
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.grey.withValues(alpha: 0.3),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.card_giftcard,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '가챠 뽑기',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 10,
                                                color: Colors.black.withValues(alpha: 0.5),
                                                offset: const Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          gachaProvider.totalPulls > 0 ? '탭해서 뽑기!' : '티켓 없음',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                // Sparkles
                                if (gachaProvider.totalPulls > 0)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.star, color: Colors.yellow, size: 30),
                                      SizedBox(width: 10),
                                      Icon(Icons.star, color: Colors.pink, size: 40),
                                      SizedBox(width: 10),
                                      Icon(Icons.star, color: Colors.yellow, size: 30),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                            ], // Stack 닫기 - 배경 애니메이션 + 메인 버튼
                          ),
                        ),

                        // Bottom - Pull Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 30, 30, 200), // 배너 광고 위에 버튼이 보이도록 충분한 여백 확대
                          child: Column(
                            children: [
                              // Coupon & Invite Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const CouponScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.confirmation_number, size: 20),
                                      label: const Text(
                                        '쿠폰',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const InviteScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.people, size: 20),
                                      label: const Text(
                                        '친구초대',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Rewarded Ad Button (항상 표시, 하루 5회 제한)
                              ElevatedButton.icon(
                                onPressed: _dailyAdCount < _maxDailyAds
                                    ? () => _showRewardedAd(context, gachaProvider)
                                    : null,
                                icon: const Icon(Icons.play_circle_filled, size: 20),
                                label: Text(
                                  '광고 보고 티켓 받기 ($_dailyAdCount/$_maxDailyAds)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _dailyAdCount < _maxDailyAds
                                      ? Colors.green.shade600
                                      : Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  ),
                  
                  // 스크롤 표시기 (하단 중앙 - 배너 위로 이동)
                  if (_showScrollIndicator)
                    Positioned(
                      bottom: 80, // 배너(50) + 여백(20) + 10
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _showScrollIndicator ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: GestureDetector(
                            onTap: () {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // 하단 고정 배너 (Sticky Banner)
                  // 배너 광고 (하단)
                  if (!kIsWeb) Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBannerAdWidget(),
                  ),
                  
                  // 버전 정보 (광고 위)
                  Positioned(
                    bottom: kIsWeb ? 10 : 70, // 광고가 있으면 70px 위, 없으면 10px 위
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'v2.8.0',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _performGacha(BuildContext context, GachaProvider gachaProvider) async {
    try {
      final pulledCard = await gachaProvider.pullGacha();

      if (pulledCard != null && context.mounted) {
        // 카드팩 개봉 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardPackOpeningScreen(card: pulledCard),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
  
  // 보상형 광고 시청 (실제 AdMob 연동)
  Future<void> _showRewardedAd(BuildContext context, GachaProvider gachaProvider) async {
    // Web 플랫폼에서는 광고 미지원 - 가짜 광고 시뮬레이션
    if (kIsWeb) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Colors.green.shade600,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '광고 시청 중...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '잠시만 기다려주세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
    
    // 3초 후 광고 시청 완료 처리
    Future.delayed(const Duration(seconds: 3), () async {
      if (context.mounted) {
        Navigator.pop(context); // 광고 시청 모달 닫기
        
        // 광고 시청 횟수 증가
        await _incrementAdCount();
        
        // 보너스 티켓 1회 지급
        await gachaProvider.addBonusTickets(1);
        
        // 성공 알림
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '광고 시청 완료! 티켓 1회가 지급되었습니다. (오늘 $_dailyAdCount/$_maxDailyAds)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    });
      return; // Web 플랫폼 처리 종료
    }
    
    // Android/iOS: 실제 AdMob 보상형 광고 표시
    final adMobService = AdMobService();
    
    if (!adMobService.isRewardedAdReady) {
      // 광고 준비 안됨
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '광고를 불러오는 중입니다. 잠시 후 다시 시도해주세요.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    // 보상형 광고 표시
    await adMobService.showRewardedAd(
      onUserEarnedReward: () async {
        // 광고 시청 횟수 증가
        await _incrementAdCount();
        // 보상 지급
        await gachaProvider.addBonusTickets(1);
      },
      onAdDismissed: () {
        // 광고 닫힘 처리
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '광고 시청 완료! 티켓 1회가 지급되었습니다. (오늘 $_dailyAdCount/$_maxDailyAds)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
    );
  }
  
  /// 오디오 토글 버튼 빌드
  Widget _buildAudioToggle({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.purple.shade600,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.purple.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 배너 광고 위젯 빌드
  Widget _buildBannerAdWidget() {
    return const BannerAdWidget();
  }
}

/// 배너 광고를 표시하는 별도 StatefulWidget
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  @override
  void initState() {
    super.initState();
    // 1초마다 광고 로드 상태 체크 (최대 10번)
    _checkAdLoadingStatus();
  }

  void _checkAdLoadingStatus() {
    int checkCount = 0;
    const maxChecks = 10;
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      checkCount++;
      
      if (mounted) {
        setState(() {}); // UI 업데이트
      }
      
      final adMobService = AdMobService();
      // 광고가 로드되었거나 최대 체크 횟수 도달하면 중단
      return !adMobService.isBannerAdReady && checkCount < maxChecks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adMobService = AdMobService();
    
    if (!adMobService.isBannerAdReady || adMobService.bannerAd == null) {
      // 광고 로딩 중 또는 실패
      return Container(
        height: 60,
        color: Colors.grey.shade900,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '광고 로딩 중...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 광고 로드 완료
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 5),
      color: Colors.grey.shade900,
      child: Center(
        child: SizedBox(
          width: adMobService.bannerAd!.size.width.toDouble(),
          height: adMobService.bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: adMobService.bannerAd!),
        ),
      ),
    );
  }
}
