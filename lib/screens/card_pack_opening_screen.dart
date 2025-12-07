import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'result_screen.dart';

class CardPackOpeningScreen extends StatefulWidget {
  final OwnedCard card;

  const CardPackOpeningScreen({super.key, required this.card});

  @override
  State<CardPackOpeningScreen> createState() => _CardPackOpeningScreenState();
}

class _CardPackOpeningScreenState extends State<CardPackOpeningScreen>
    with TickerProviderStateMixin {
  late AnimationController _packController;
  late AnimationController _tearController;
  late AnimationController _revealController;
  late AnimationController _glowController;
  late AnimationController _shakeController;
  
  late Animation<double> _packScaleAnimation;
  late Animation<double> _packRotationAnimation;
  late Animation<double> _tearAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _shakeAnimation;
  
  bool _packOpened = false;
  bool _showHint = false;
  bool _cardRevealed = false;
  
  @override
  void initState() {
    super.initState();
    
    // 팩 등장 애니메이션
    _packController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _packScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _packController, curve: Curves.elasticOut),
    );
    
    _packRotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _packController, curve: Curves.easeInOut),
    );
    
    // 찢기 애니메이션
    _tearController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _tearAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tearController, curve: Curves.easeInOut),
    );
    
    // 카드 공개 애니메이션
    _revealController = AnimationController(
      duration: Duration(milliseconds: _getRevealDuration()),
      vsync: this,
    );
    
    // 빛나는 효과
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // 진동 효과 (Secret 전용)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.02, 0.0),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.02, 0.0),
          end: const Offset(-0.02, 0.0),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.02, 0.0),
          end: Offset.zero,
        ),
        weight: 1,
      ),
    ]).animate(_shakeController);
    
    _startSequence();
  }
  
  void _startSequence() async {
    // 1. 팩 등장
    await _packController.forward();
    
    // 2. 등급에 따른 전조 증상
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showHint = true);
    
    // 3. 고등급은 더 오래 뜸 들임
    await Future.delayed(Duration(milliseconds: _getHintDuration()));
    
    // 4. Secret은 진동
    if (widget.card.rarity == CardRarity.secret) {
      for (int i = 0; i < 5; i++) {
        await _shakeController.forward();
        _shakeController.reset();
      }
    }
  }
  
  int _getRevealDuration() {
    switch (widget.card.rarity) {
      case CardRarity.normal:
        return 800;
      case CardRarity.rare:
        return 1000;
      case CardRarity.superRare:
        return 1200;
      case CardRarity.ultraRare:
        return 1500;
      case CardRarity.secret:
        return 2000;
    }
  }
  
  int _getHintDuration() {
    switch (widget.card.rarity) {
      case CardRarity.normal:
        return 500;
      case CardRarity.rare:
        return 800;
      case CardRarity.superRare:
        return 1200;
      case CardRarity.ultraRare:
        return 1800;
      case CardRarity.secret:
        return 2500;
    }
  }
  
  Color _getGlowColor() {
    switch (widget.card.rarity) {
      case CardRarity.normal:
        return Colors.grey;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.superRare:
        return Colors.purple;
      case CardRarity.ultraRare:
        return Colors.amber;
      case CardRarity.secret:
        return Colors.pink;
    }
  }
  
  @override
  void dispose() {
    _packController.dispose();
    _tearController.dispose();
    _revealController.dispose();
    _glowController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  
  void _onPackTap() async {
    if (_packOpened || _cardRevealed) return;
    
    setState(() => _packOpened = true);
    
    // 찢기 애니메이션
    await _tearController.forward();
    
    // 카드 공개
    setState(() => _cardRevealed = true);
    await _revealController.forward();
    
    // 잠시 후 결과 화면으로
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(card: widget.card),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onPackTap,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < -500) {
            _onPackTap();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 효과
            _buildBackground(),
            
            // 카드팩 또는 카드
            if (!_cardRevealed)
              _buildCardPack()
            else
              _buildRevealedCard(),
            
            // 터치 힌트
            if (!_packOpened && _showHint)
              _buildTouchHint(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBackground() {
    if (!_cardRevealed) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Colors.grey.shade900,
              Colors.black,
            ],
          ),
        ),
      );
    }
    
    // 등급별 배경
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: _getBackgroundColors(),
        ),
      ),
      child: _buildParticles(),
    );
  }
  
  List<Color> _getBackgroundColors() {
    switch (widget.card.rarity) {
      case CardRarity.normal:
        return [Colors.grey.shade800, Colors.black];
      case CardRarity.rare:
        return [Colors.blue.shade900, Colors.black];
      case CardRarity.superRare:
        return [Colors.purple.shade900, Colors.black];
      case CardRarity.ultraRare:
        return [Colors.amber.shade900, Colors.black];
      case CardRarity.secret:
        return [
          Colors.pink.shade900,
          Colors.purple.shade900,
          Colors.black,
        ];
    }
  }
  
  Widget _buildParticles() {
    if (widget.card.rarity == CardRarity.normal) {
      return const SizedBox();
    }
    
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(
            animationValue: _revealController.value,
            rarity: widget.card.rarity,
          ),
        );
      },
    );
  }
  
  Widget _buildCardPack() {
    return Center(
      child: SlideTransition(
        position: _shakeAnimation,
        child: AnimatedBuilder(
          animation: Listenable.merge([_packController, _tearController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _packScaleAnimation.value * (1 - _tearAnimation.value * 0.5),
              child: Transform.rotate(
                angle: _packRotationAnimation.value * sin(_packController.value * pi * 2),
                child: Opacity(
                  opacity: 1 - _tearAnimation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 후광 효과
                      if (_showHint)
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 300 + _glowAnimation.value * 50,
                              height: 420 + _glowAnimation.value * 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getGlowColor().withValues(alpha: _glowAnimation.value * 0.8),
                                    blurRadius: 60 * _glowAnimation.value,
                                    spreadRadius: 20 * _glowAnimation.value,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      
                      // 카드팩
                      Container(
                        width: 280,
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple.shade400,
                              Colors.pink.shade400,
                              Colors.blue.shade400,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 반짝이는 효과
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Positioned(
                                  left: _glowAnimation.value * 50,
                                  top: _glowAnimation.value * 100,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.3 * _glowAnimation.value),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            // 로고/텍스트
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.card_giftcard,
                                    size: 80,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Weekly Gacha',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black.withValues(alpha: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 찢어지는 효과
                            if (_tearAnimation.value > 0)
                              CustomPaint(
                                painter: TearEffectPainter(_tearAnimation.value),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildRevealedCard() {
    return Center(
      child: AnimatedBuilder(
        animation: _revealController,
        builder: (context, child) {
          return Transform.scale(
            scale: _revealController.value,
            child: Opacity(
              opacity: _revealController.value,
              child: Container(
                width: 280,
                height: 420,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getGlowColor().withValues(alpha: 0.8),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    widget.card.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTouchHint() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _glowAnimation.value * 0.8,
            child: Column(
              children: [
                Icon(
                  Icons.touch_app,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  '터치하거나 위로 슬라이드하여 개봉',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 파티클 효과 페인터
class ParticlesPainter extends CustomPainter {
  final double animationValue;
  final CardRarity rarity;
  
  ParticlesPainter({required this.animationValue, required this.rarity});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    final particleCount = _getParticleCount();
    final colors = _getParticleColors();
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      final distance = animationValue * size.width * 0.8;
      final x = size.width / 2 + cos(angle) * distance;
      final y = size.height / 2 + sin(angle) * distance;
      
      paint.color = colors[i % colors.length].withValues(
        alpha: (1 - animationValue) * 0.8,
      );
      
      canvas.drawCircle(
        Offset(x, y),
        8 * (1 - animationValue),
        paint,
      );
    }
  }
  
  int _getParticleCount() {
    switch (rarity) {
      case CardRarity.normal:
        return 0;
      case CardRarity.rare:
        return 20;
      case CardRarity.superRare:
        return 30;
      case CardRarity.ultraRare:
        return 40;
      case CardRarity.secret:
        return 60;
    }
  }
  
  List<Color> _getParticleColors() {
    switch (rarity) {
      case CardRarity.normal:
        return [Colors.white];
      case CardRarity.rare:
        return [Colors.blue, Colors.cyan];
      case CardRarity.superRare:
        return [Colors.purple, Colors.pink];
      case CardRarity.ultraRare:
        return [Colors.amber, Colors.orange];
      case CardRarity.secret:
        return [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.purple,
          Colors.pink,
        ];
    }
  }
  
  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

// 찢어지는 효과 페인터
class TearEffectPainter extends CustomPainter {
  final double progress;
  
  TearEffectPainter(this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // 중앙에서 찢어지는 효과
    final tearWidth = size.width * progress;
    
    path.moveTo(size.width / 2 - tearWidth / 2, 0);
    
    // 지그재그 찢어짐
    for (double y = 0; y < size.height; y += 20) {
      final zigzag = sin(y / 20) * 10 * progress;
      path.lineTo(size.width / 2 + zigzag, y);
    }
    
    path.lineTo(size.width / 2 + tearWidth / 2, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(TearEffectPainter oldDelegate) => true;
}
