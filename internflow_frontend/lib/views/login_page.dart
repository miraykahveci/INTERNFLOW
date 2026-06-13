import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_dashboard.dart';
import 'academician_dashboard.dart';
import 'email_verification_page.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF6A0F0F);

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _identifierController.clear();
        _passwordController.clear();
      });
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      
      final String loginEmail = identifier.contains('@')
          ? identifier
          : '$identifier@internflow.edu.tr';

      
      final AuthResponse authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: loginEmail,
        password: password,
      );

      if (authResponse.user == null) throw Exception("Kullanıcı doğrulanamadı.");

      
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('user_id', authResponse.user!.id)
          .maybeSingle();

      if (userResponse == null) {
        await Supabase.instance.client.auth.signOut();
        throw Exception("Kullanıcı profili bulunamadı.");
      }

      final String role = userResponse['role'];
      final bool isStudentTab = _tabController.index == 0;

      
      if (isStudentTab && role != 'student') {
        await Supabase.instance.client.auth.signOut();
        throw Exception("Bu giriş alanı sadece öğrencilere özeldir! ❌");
      } else if (!isStudentTab && role != 'academician') {
        await Supabase.instance.client.auth.signOut();
        throw Exception("Bu giriş alanı sadece akademisyenlere özeldir! ❌");
      }

      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Giriş Başarılı! Hoş geldin. 🚀"),
          backgroundColor: Colors.green,
        ),
      );

      if (role == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentDashboardPage(),
          ),
        );
        } else if (role == 'academician') {
          Navigator.pushReplacement(
           context,
           MaterialPageRoute(
              builder: (context) => const AcademicianDashboardPage(),
          ),
        );
      }
      
        
      

    } on AuthException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hatalı numara veya şifre! ❌"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _buildWebLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  // ========== WEB LAYOUT ==========
  Widget _buildWebLayout() {
    return Row(
      children: [
        
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, const Color(0xFF4A0A0A)],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.school, color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'InternFlow',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Yapay Zeka Destekli Staj Takip Sistemi',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 48),
                    
                    _buildFeatureItem(Icons.assignment, 'Staj başvuru ve onay yönetimi'),
                    _buildFeatureItem(Icons.cloud_upload, 'Dijital belge yükleme ve takip'),
                    _buildFeatureItem(Icons.auto_awesome, 'AI destekli staj defteri analizi'),
                    _buildFeatureItem(Icons.timeline, 'Gerçek zamanlı süreç takibi'),
                    const SizedBox(height: 48),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'İstanbul Rumeli Üniversitesi | Bilgisayar Mühendisliği',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
 
        
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFFF8F9FA),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: SizedBox(
                  width: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş Geldiniz',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Devam etmek için giriş yapın',
                        style: TextStyle(color: Color(0xFF757575), fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      _buildLoginForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
 
  // ========== MOBİL LAYOUT ==========
  Widget _buildMobileLayout() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 80),
            Image.asset(
              'assets/images/app_logo.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, color: Colors.white, size: 64),
            ),
            const Text(
              "InternFlow",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.03,
                shadows: [
                  Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
                ],
              ),
            ),
            const Text(
              "Akıllı Staj Yönetim Sistemi",
              style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 20,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _buildLoginForm(),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
 
  // ========== ORTAK LOGIN FORMU ==========
  Widget _buildLoginForm() {
    final String inputLabel =
        _tabController.index == 0 ? "Okul Numarası" : "Kullanıcı Adı";
    final IconData inputIcon =
        _tabController.index == 0 ? Icons.numbers : Icons.person_outline;
 
    return Column(
      children: [
        
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF757575),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: "Öğrenci"),
              Tab(text: "Akademisyen"),
            ],
          ),
        ),
        const SizedBox(height: 24),
 
        
        TextField(
          controller: _identifierController,
          decoration: InputDecoration(
            labelText: inputLabel,
            prefixIcon: Icon(inputIcon, color: const Color(0xFF757575)),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
 
        
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Şifre",
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF757575)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF757575),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
 
        
     Row(
  children: [
    Checkbox(
      value: _rememberMe,
      activeColor: primaryColor,
      onChanged: (v) => setState(() => _rememberMe = v ?? false),
    ),
    const Text("Beni Hatırla", style: TextStyle(color: Colors.grey, fontSize: 13)),
    const Spacer(),
    TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama için staj komisyonuyla iletişime geçiniz.'),
            backgroundColor: Color(0xFF546E7A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Text(
        "Şifremi Unuttum",
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ),
  ],
),
const SizedBox(height: 4),

// MAIL DOĞRULAMA 
Align(
  alignment: Alignment.centerRight,
  child: TextButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
      );
    },
    icon: Icon(Icons.mark_email_read_outlined, size: 14, color: primaryColor.withValues(alpha: 0.7)),
    label: Text(
      "Mail adresimi doğrula",
      style: TextStyle(
        color: primaryColor.withValues(alpha: 0.7),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
        decorationColor: primaryColor.withValues(alpha: 0.4),
      ),
    ),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      minimumSize: const Size(0, 24),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  ),
),


        const SizedBox(height: 12),
 
        
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Giriş Yap",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 16),
 
        
        const Text(
          'InternFlow v1.0.0',
          style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 11),
        ),
      ],
    );
  }
 
  // ========== ÖZELLİK LİSTESİ (WEB SOL PANEL) ==========
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 14),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
 