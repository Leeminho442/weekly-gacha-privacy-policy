import 'package:flutter/material.dart';
import '../services/ai_card_generation_service.dart';

/// 🎴 AI 카드 생성 마법사
/// 
/// 진화 시스템, 테마별 생성, 고급 커스터마이징 지원
class AICardWizardScreen extends StatefulWidget {
  const AICardWizardScreen({super.key});

  @override
  State<AICardWizardScreen> createState() => _AICardWizardScreenState();
}

class _AICardWizardScreenState extends State<AICardWizardScreen> {
  final AICardGenerationService _aiService = AICardGenerationService();
  
  // 현재 단계 (1: 모드 선택, 2: 테마 선택, 3: 스타일 선택, 4: 확인 및 생성)
  int _currentStep = 1;
  
  // 선택된 옵션들
  GenerationMode? _selectedMode;
  String? _selectedThemeKey;
  CardStyle? _selectedStyle;
  String? _customTheme;
  
  // 진화 시스템용 커스텀 크리처 이름
  final List<TextEditingController> _creatureControllers = [];
  bool _useCustomCreatureNames = false;
  
  @override
  void initState() {
    super.initState();
    // 20개 크리처 이름 입력 컨트롤러 초기화
    for (int i = 0; i < 20; i++) {
      _creatureControllers.add(TextEditingController());
    }
  }
  
  @override
  void dispose() {
    for (var controller in _creatureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('🎴 AI 카드 생성 마법사'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 진행 단계 표시
          _buildProgressIndicator(),
          
          // 현재 단계 콘텐츠
          Expanded(
            child: _buildCurrentStepContent(),
          ),
          
          // 하단 네비게이션 버튼
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  /// 진행 단계 표시
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepDot(1, '모드'),
          _buildStepLine(1),
          _buildStepDot(2, '테마'),
          _buildStepLine(2),
          _buildStepDot(3, '스타일'),
          _buildStepLine(3),
          _buildStepDot(4, '확인'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.deepPurple
                : isCompleted
                    ? Colors.green
                    : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.deepPurple : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? Colors.green : Colors.grey.shade300,
    );
  }

  /// 현재 단계 콘텐츠
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildModeSelectionStep();
      case 2:
        return _buildThemeSelectionStep();
      case 3:
        return _buildStyleSelectionStep();
      case 4:
        return _buildConfirmationStep();
      default:
        return const Center(child: Text('알 수 없는 단계'));
    }
  }

  /// 단계 1: 생성 모드 선택
  Widget _buildModeSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '어떤 방식으로 카드를 생성하시겠습니까?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '70장의 카드 생성 방식을 선택하세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          
          // 진화 시스템
          _buildModeCard(
            mode: GenerationMode.evolution,
            icon: Icons.trending_up,
            title: '🔥 진화 시스템 (추천)',
            subtitle: '20마리 캐릭터 × 5단계 진화',
            description: '포켓몬스터처럼 캐릭터가 진화하는 시스템\n'
                'Normal → Rare → Super Rare → Ultra Rare → Secret',
            color: Colors.orange,
            examples: [
              '꼬마 퉁퉁퉁사우르스 (1단계)',
              '퉁퉁퉁사우르스 (2단계)',
              '강화 퉁퉁퉁사우르스 (3단계)',
              '궁극 퉁퉁퉁사우르스 (4단계)',
              '신성 퉁퉁퉁사우르스 (5단계)',
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 테마별 생성
          _buildModeCard(
            mode: GenerationMode.thematic,
            icon: Icons.palette,
            title: '🎨 테마별 생성',
            subtitle: '70장 독립적인 카드',
            description: '하나의 테마로 70장의 독립적인 카드 생성\n'
                '각 카드는 독립적이며 진화 관계 없음',
            color: Colors.blue,
            examples: [
              '귀여운 동물 70마리',
              '해괴한 생명체 70종',
              '사이버펑크 아이템 70개',
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 하이브리드
          _buildModeCard(
            mode: GenerationMode.hybrid,
            icon: Icons.merge,
            title: '⚡ 하이브리드',
            subtitle: '진화 10마리 + 독립 20장',
            description: '진화 시스템과 독립 카드 혼합\n'
                '10마리 진화(50장) + 20장 독립 카드',
            color: Colors.purple,
            examples: [
              '진화: 10마리 × 5단계 = 50장',
              '독립: 테마별 20장',
            ],
          ),
        ],
      ),
    );
  }

  /// 모드 카드 위젯
  Widget _buildModeCard({
    required GenerationMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required List<String> examples,
  }) {
    final isSelected = _selectedMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ...examples.map((example) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, size: 16, color: color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          example,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 단계 2: 테마 선택
  Widget _buildThemeSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '어떤 테마의 카드를 만드시겠습니까?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '원하는 테마를 선택하거나 직접 입력하세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          
          // 프리셋 테마들
          ...AICardGenerationService.themePresets.entries.map((entry) {
            if (entry.key == 'custom') return const SizedBox.shrink();
            
            final preset = entry.value;
            return Column(
              children: [
                _buildThemeCard(
                  themeKey: entry.key,
                  emoji: _getThemeEmoji(entry.key),
                  title: preset['name'] as String,
                  description: preset['description'] as String,
                  examples: List<String>.from(preset['examples'] as List),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
          
          // 커스텀 테마 입력
          _buildCustomThemeCard(),
        ],
      ),
    );
  }

  String _getThemeEmoji(String key) {
    switch (key) {
      case 'pokemon_style':
        return '🔥';
      case 'weird_creatures':
        return '👾';
      case 'cute_animals':
        return '🐱';
      case 'cute_dinosaurs':
        return '🦖';
      case 'cyberpunk_city':
        return '🌃';
      default:
        return '🎴';
    }
  }

  Widget _buildThemeCard({
    required String themeKey,
    required String emoji,
    required String title,
    required String description,
    required List<String> examples,
  }) {
    final isSelected = _selectedThemeKey == themeKey;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedThemeKey = themeKey;
          _customTheme = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.deepPurple : Colors.black87,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.deepPurple, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: examples.map((example) => Chip(
                    label: Text(example),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomThemeCard() {
    final isSelected = _selectedThemeKey == 'custom';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedThemeKey = 'custom';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '커스텀 테마',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.deepPurple : Colors.black87,
                        ),
                      ),
                      Text(
                        '원하는 테마를 직접 입력하세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.deepPurple, size: 28),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _customTheme = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: '예: 우주 탐험, 한국 전통, 기계 동물 등...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 단계 3: 스타일 선택
  Widget _buildStyleSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '카드의 아트 스타일을 선택하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI가 선택한 스타일로 이미지를 생성합니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildStyleCard(
            style: CardStyle.cute,
            emoji: '🥰',
            title: '귀여운 스타일 (추천)',
            description: '카와이 스타일, 치비, 파스텔 톤',
            color: Colors.pink,
          ),
          const SizedBox(height: 16),
          
          _buildStyleCard(
            style: CardStyle.cyberpunk,
            emoji: '🌃',
            title: '사이버펑크 (현재 스타일)',
            description: '네온, 홀로그램, 미래적',
            color: Colors.cyan,
          ),
          const SizedBox(height: 16),
          
          _buildStyleCard(
            style: CardStyle.cartoon,
            emoji: '🎨',
            title: '카툰/만화 스타일',
            description: '생동감, 과장된 표현',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          
          _buildStyleCard(
            style: CardStyle.fantasy,
            emoji: '✨',
            title: '판타지 스타일',
            description: '마법적, 신비로운, 몽환적',
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          
          _buildStyleCard(
            style: CardStyle.realistic,
            emoji: '📸',
            title: '사실적 스타일',
            description: '포토리얼, 디테일, 현실감',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          
          _buildStyleCard(
            style: CardStyle.pixelArt,
            emoji: '🎮',
            title: '픽셀 아트',
            description: '레트로, 16비트, 게임 스타일',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard({
    required CardStyle style,
    required String emoji,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedStyle == style;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStyle = style;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  /// 단계 4: 확인 및 생성
  Widget _buildConfirmationStep() {
    // 비용 계산
    const costPerCard = 0.04; // 고품질 기준
    const totalCost = 70 * costPerCard;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '설정을 확인하고 생성을 시작하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI가 70장의 카드를 자동으로 생성합니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          
          // 설정 요약 카드
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('생성 모드', _getModeName()),
                const Divider(height: 24),
                _buildSummaryRow('선택 테마', _getThemeName()),
                const Divider(height: 24),
                _buildSummaryRow('아트 스타일', _getStyleName()),
                const Divider(height: 24),
                _buildSummaryRow('생성 카드 수', '70장'),
                const Divider(height: 24),
                _buildSummaryRow('예상 비용', '\$${totalCost.toStringAsFixed(2)} (~₩${(totalCost * 1320).toStringAsFixed(0)})'),
                const Divider(height: 24),
                _buildSummaryRow('예상 소요 시간', '30-40분'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 경고 메시지
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '생성 시작 시 크레딧이 차감됩니다. 진행하시겠습니까?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 생성 시작 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _startGeneration,
              icon: const Icon(Icons.auto_awesome, size: 24),
              label: const Text(
                '🎴 AI 카드 생성 시작',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getModeName() {
    switch (_selectedMode) {
      case GenerationMode.evolution:
        return '진화 시스템';
      case GenerationMode.thematic:
        return '테마별 생성';
      case GenerationMode.hybrid:
        return '하이브리드';
      default:
        return '미선택';
    }
  }

  String _getThemeName() {
    if (_selectedThemeKey == 'custom') {
      return _customTheme ?? '미입력';
    }
    return AICardGenerationService.themePresets[_selectedThemeKey]?['name'] ?? '미선택';
  }

  String _getStyleName() {
    switch (_selectedStyle) {
      case CardStyle.cute:
        return '귀여운 스타일';
      case CardStyle.cyberpunk:
        return '사이버펑크';
      case CardStyle.cartoon:
        return '카툰/만화';
      case CardStyle.fantasy:
        return '판타지';
      case CardStyle.realistic:
        return '사실적';
      case CardStyle.pixelArt:
        return '픽셀 아트';
      default:
        return '미선택';
    }
  }

  /// 하단 네비게이션 바
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('이전'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (_currentStep > 1) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _canProceed() ? () {
                if (_currentStep < 4) {
                  setState(() {
                    _currentStep++;
                  });
                }
              } : null,
              icon: Icon(_currentStep == 4 ? Icons.check : Icons.arrow_forward),
              label: Text(_currentStep == 4 ? '완료' : '다음'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 1:
        return _selectedMode != null;
      case 2:
        if (_selectedThemeKey == 'custom') {
          return _customTheme != null && _customTheme!.trim().isNotEmpty;
        }
        return _selectedThemeKey != null;
      case 3:
        return _selectedStyle != null;
      case 4:
        return true;
      default:
        return false;
    }
  }

  /// AI 카드 생성 시작
  void _startGeneration() {
    // TODO: 실제 AI 생성 로직 구현
    // 1. image_generation tool 호출
    // 2. Firebase Storage에 업로드
    // 3. Firestore에 카드 데이터 저장
    // 4. 진행 상황 표시
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎴 카드 생성 중...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'AI가 70장의 카드를 생성하고 있습니다.\n'
              '약 30-40분 소요됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
    
    // TODO: 실제 구현 시 여기서 AI 생성 호출
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 AI 카드 생성 기능은 현재 구현 중입니다'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
