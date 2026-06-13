import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSending = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  String? _sentToEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Geçerli bir e-posta adresi giriniz', isError: true);
      return;
    }

    setState(() => _isSending = true);
    try {
    
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );

      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _sentToEmail = email;
      });
      _showSnack('Doğrulama kodu $email adresine gönderildi 📧');
    } catch (e) {
      _showSnack('Kod gönderilemedi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _sentToEmail;
    final code = _otpController.text.trim();

    if (email == null) {
      _showSnack('Önce kodu gönderin', isError: true);
      return;
    }
    if (code.length != 8) {
      _showSnack('8 haneli kodu giriniz', isError: true);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );

      if (response.user != null) {
        if (!mounted) return;
        _showSnack('E-posta başarıyla doğrulandı! ✅');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnack('Doğrulama başarısız. Kodu kontrol edin.', isError: true);
      }
    } catch (e) {
      _showSnack('Doğrulama hatası: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        title: const Text(
          'E-posta Doğrulama',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEF2)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero icon
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColor, primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Güvenlik Kodu ile Doğrulama',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? '$_sentToEmail adresine gönderilen 8 haneli kodu giriniz'
                      : 'E-posta adresinizi girin, size 8 haneli güvenlik kodu gönderelim',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
                ),
                const SizedBox(height: 36),

                // Email field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFEEEEF2)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailController,
                    enabled: !_codeSent,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14, color: textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'ornek@okul.edu.tr',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.email_outlined, color: textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Send code button
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: (_isSending || _codeSent) ? null : _sendOtp,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 18, color: Colors.white),
                    label: Text(
                      _isSending
                          ? 'Gönderiliyor...'
                          : _codeSent
                              ? 'Kod Gönderildi ✓'
                              : 'Kod Gönder',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: _codeSent
                          ? const Color(0xFF16A34A)
                          : primaryColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      elevation: 8,
                      shadowColor: primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                // OTP code section (sadece kod gönderildikten sonra)
                if (_codeSent) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        purpleGlow.withValues(alpha: 0.04),
                        primaryColor.withValues(alpha: 0.04),
                      ]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: purpleGlow.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: purpleGlow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.lock_outline, color: purpleGlow, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '8 Haneli Güvenlik Kodu',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: const TextStyle(
                                color: Color(0xFFCBD5E1), letterSpacing: 8),
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                              borderSide: const BorderSide(color: Color(0xFFEEEEF2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                              borderSide: const BorderSide(color: Color(0xFFEEEEF2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Verify button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      icon: _isVerifying
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_user_outlined,
                              size: 18, color: Colors.white),
                      label: Text(
                        _isVerifying ? 'Doğrulanıyor...' : 'Doğrula',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        elevation: 8,
                        shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            setState(() {
                              _codeSent = false;
                              _otpController.clear();
                            });
                          },
                    child: const Text(
                      'Farklı bir e-posta adresi kullan',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Info box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFEEEEF2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: purpleGlow, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Bu özellik, e-posta adresinizin gerçekliğini doğrulamak için kullanılır. Kod 5 dakika geçerlidir.',
                          style: TextStyle(fontSize: 11, color: textSecondary, height: 1.5),
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
    );
  }
}