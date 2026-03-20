import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase'i dahil ettik!

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF6A0F0F); 

  // Controller ismini genel bir isimle değiştirdik çünkü hem numara hem isim alabilir
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false; // Yüklenme animasyonu için

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // SEKME DEĞİŞTİĞİNDE EKRANI YENİLE (Kutu yazısını değiştirmek için)
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

  // 🚀 ASIL SİHİRLİ GİRİŞ FONKSİYONU 
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
      // 1. KULLANICIYA ÇAKTIRMADAN MAİL FORMATINA ÇEVİRME
      final String loginEmail = identifier.contains('@') 
          ? identifier 
          : '$identifier@internflow.edu.tr';

      // 2. SUPABASE AUTH İLE GİRİŞ
      final AuthResponse authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: loginEmail,
        password: password,
      );

      if (authResponse.user == null) throw Exception("Kullanıcı doğrulanamadı.");

      // 3. KENDİ TABLOMUZDAN ROLÜ KONTROL ETME
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

      // 4. ÇAPRAZ SEKME GÜVENLİK KONTROLÜ (Mükemmel özellik)
      if (isStudentTab && role != 'student') {
        await Supabase.instance.client.auth.signOut();
        throw Exception("Bu giriş alanı sadece öğrencilere özeldir! ❌");
      } else if (!isStudentTab && role != 'academician') {
        await Supabase.instance.client.auth.signOut();
        throw Exception("Bu giriş alanı sadece akademisyenlere özeldir! ❌");
      }

      // 5. HER ŞEY KUSURSUZSA...
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giriş Başarılı! Hoş geldin. 🚀"), backgroundColor: Colors.green),
      );

      // TODO: İleride burada Öğrenci veya Akademisyen Ana Sayfasına yönlendirme yapacağız.

    } on AuthException catch (_) {
      // Supabase şifre veya e-posta yanlış derse buraya düşer
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hatalı numara veya şifre! ❌"), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sekmeye göre kutucuğun içindeki yazıyı belirliyoruz
    final String inputLabel = _tabController.index == 0 
        ? "Okul Numarası" 
        : "Kullanıcı Adı (Örn: haldun)";
    
    final IconData inputIcon = _tabController.index == 0 
        ? Icons.numbers 
        : Icons.person_outline;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 80),
              // Logo Alanı
              const Icon(Icons.school, size: 100, color: Colors.white), 
              const Text(
                "InternFlow",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.03,
                  shadows: [Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)],
                ),
              ),
              const Text(
                "Akıllı Staj Yönetim Sistemi",
                style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 40),
              
              // Login Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 20,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        // TabLayout Kısmı
                        TabBar(
                          controller: _tabController,
                          labelColor: primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: primaryColor,
                          indicatorWeight: 3,
                          tabs: const [Tab(text: "Öğrenci"), Tab(text: "Akademisyen")],
                        ),
                        const SizedBox(height: 24),
                        
                        // Dinamik Input Alanı
                        TextField(
                          controller: _identifierController, 
                          decoration: InputDecoration(
                            labelText: inputLabel,
                            prefixIcon: Icon(inputIcon),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Şifre Input
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Şifre",
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                        ),
                        
                        // Beni Hatırla & Şifremi Unuttum
                        Row(
                          children: [
                            Checkbox(value: true, activeColor: primaryColor, onChanged: (v) {}),
                            const Text("Beni Hatırla", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: Text("Şifremi Unuttum", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // GİRİŞ YAP BUTONU
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login, // Yükleniyorsa butonu kilitle
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 6,
                            ),
                            child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}