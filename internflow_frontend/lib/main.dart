import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/login_page.dart';
import 'views/student_dashboard.dart';
import 'views/academician_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  print("URL: ${dotenv.env['SUPABASE_URL']}");
  print("KEY: ${dotenv.env['SUPABASE_KEY']}");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InternFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A0F0F),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ========== AUTH GATE ==========

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        // Session yok, login'e
        setState(() {
          _userRole = null;
          _isLoading = false;
        });
        return;
      }

      final userId = session.user.id;
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('user_id', userId)
          .single();

      setState(() {
        _userRole = userResponse['role'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      
      debugPrint('Auth kontrol hatası: $e');
      setState(() {
        _userRole = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F7FB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6A0F0F)),
              SizedBox(height: 16),
              Text(
                'InternFlow',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A0F0F),
                ),
              ),
            ],
          ),
        ),
      );
    }

    
    if (_userRole == 'student') {
      return const StudentDashboardPage();
    } else if (_userRole == 'academician') {
      return const AcademicianDashboardPage();
    } else {
      // Session yok veya role bulunamadı
      return const LoginPage();
    }
  }
}