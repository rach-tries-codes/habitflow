import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'features/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HabitFlowApp());
}

class HabitFlowApp extends StatelessWidget {
  const HabitFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNav(),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    Scaffold(body: Center(child: Text('Journal 📓'))),
    Scaffold(body: Center(child: Text('Stats 📊'))),
    Scaffold(body: Center(child: Text('Profile 👤'))),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF182818)
              : const Color(0xFFF4F2EB),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF3A6040).withOpacity(0.2)
                  : const Color(0xFFAACC90).withOpacity(0.3),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: isDark ? AppTheme.sageLight : AppTheme.moss,
          unselectedItemColor: isDark
              ? const Color(0xFF4A7050)
              : AppTheme.textLight,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Text('🏠', style: TextStyle(fontSize: 20)), label: 'Home'),
            BottomNavigationBarItem(icon: Text('📓', style: TextStyle(fontSize: 20)), label: 'Journal'),
            BottomNavigationBarItem(icon: Text('📊', style: TextStyle(fontSize: 20)), label: 'Stats'),
            BottomNavigationBarItem(icon: Text('👤', style: TextStyle(fontSize: 20)), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}