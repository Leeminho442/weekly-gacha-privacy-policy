import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/gacha_provider.dart';
import 'screens/gacha_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/intro_screen.dart';
import 'services/auth_service.dart';
import 'services/gacha_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 🔧 카드 재고 강제 초기화 (앱 시작 시 한 번만 실행)
  try {
    final gachaService = GachaService();
    await gachaService.forceInitializeStock();
    debugPrint('✅ 카드 재고 초기화 완료 (70장)');
  } catch (e) {
    debugPrint('⚠️ 카드 재고 초기화 실패: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '위클리 갓챠',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// 인증 게이트 - 로그인 여부에 따라 화면 분기
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        // 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.purple,
              ),
            ),
          );
        }

        // 로그인 여부 확인
        final isLoggedIn = snapshot.data ?? false;

        if (isLoggedIn) {
          // 로그인된 경우 메인 화면으로 (Provider와 함께)
          return ChangeNotifierProvider(
            create: (context) => GachaProvider(),
            child: const MainScreen(),
          );
        } else {
          // 로그인 안 된 경우 인트로 화면으로
          return const IntroScreen();
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const GachaScreen(),
    const CollectionScreen(),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabChanged,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.collections),
              label: '컬렉션',
            ),
          ],
        ),
      ),
    );
  }
}
