import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_config.dart';

class StudentFilesWeb extends StatefulWidget {
  const StudentFilesWeb({super.key});

  @override
  State<StudentFilesWeb> createState() => _StudentFilesWebState();
}

class _StudentFilesWebState extends State<StudentFilesWeb> {
  // Premium color palette
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);

  int _hoveredFile = -1;

  // ========== YÖNERGE STATE ==========
  bool _yonergeLoading = true;
  String? _yonergeLastModified;
  String? _yonergeSize;
  String? _yonergePdfUrl;
  String? _yonergeError;

  @override
  void initState() {
    super.initState();
    _fetchYonergeInfo();
  }

  // ========== YÖNERGE BACKEND'DEN ÇEK ==========
  Future<void> _fetchYonergeInfo() async {
    setState(() => _yonergeLoading = true);
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.yonergeInfo))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Backend hatası: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        throw Exception(json['error'] ?? 'Bilinmeyen hata');
      }

      final data = json['data'] as Map<String, dynamic>;

      setState(() {
        _yonergeLastModified = _formatLastModified(data['last_modified']);
        _yonergeSize = _formatSize(data['file_size_kb']);
        _yonergePdfUrl = data['pdf_url'] as String?;
        _yonergeLoading = false;
        _yonergeError = null;
      });
    } catch (e) {
      debugPrint('Yönerge fetch hatası: $e');
      setState(() {
        _yonergeLoading = false;
        _yonergeError = 'Yönerge bilgisi alınamadı';
      });
    }
  }

  String _formatLastModified(dynamic isoString) {
    if (isoString == null) return 'Bilinmiyor';
    try {
      final date = DateTime.parse(isoString.toString());
      const months = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'Bilinmiyor';
    }
  }

  String _formatSize(dynamic sizeKb) {
    if (sizeKb == null) return '-';
    final kb = (sizeKb is num) ? sizeKb.toDouble() : 0.0;
    if (kb >= 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '${kb.toStringAsFixed(0)} KB';
  }

  Future<void> _downloadYonerge() async {
    try {
      // Backend'in download endpoint'ini kullan (cache freshness + self-healing tetiklenir)
      final uri = Uri.parse(ApiConfig.yonergeDownload);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yönerge açılamadı: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _downloadTemplate(String fileName) async {
    try {
      final url =
          '${Supabase.instance.client.rest.url.replaceAll('/rest/v1', '')}/storage/v1/object/public/templates/$fileName';
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya açılamadı: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCanvas,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 60),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoBanner(),
                      const SizedBox(height: 32),

                      // ========== ÖNCELİKLİ: YÖNERGE KARTI (BACKEND BAĞLI) ==========
                      _buildSectionTitle(
                        'Resmi Staj Yönergesi',
                        'Okulun resmi sitesinden otomatik senkronize edilir',
                      ),
                      const SizedBox(height: 20),
                      _buildYonergeCard(),
                      const SizedBox(height: 36),

                      // ========== BAŞLANGIÇ BELGELERİ ==========
                      _buildSectionTitle(
                        'Başlangıç Belgeleri',
                        'Staj öncesinde indirilmesi gereken belgeler',
                      ),
                      const SizedBox(height: 20),
                      _buildFileCard(
                        0,
                        icon: Icons.description_outlined,
                        accentColor: const Color(0xFF2563EB),
                        title: 'Staj Kabul Formu',
                        description:
                            'Staj yapacağınız kurumun doldurması gereken resmi kabul belgesi.',
                        fileName: 'kabul_formu.pdf',
                        fileType: 'PDF',
                        size: 'Şablon',
                      ),
                      const SizedBox(height: 32),

                      _buildSectionTitle(
                        'Dönem İçi & Final Belgeleri',
                        'Staj süresince ve bitiminde kullanılacak belgeler',
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFileCard(
                              2,
                              icon: Icons.book_outlined,
                              accentColor: primaryColor,
                              title: 'Staj Günlüğü / Defteri',
                              description:
                                  'Staj süresince günlük olarak doldurmanız gereken çalışma kayıtları.',
                              fileName: 'staj_gunlugu.pdf',
                              fileType: 'PDF',
                              size: 'Şablon',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildFileCard(
                              3,
                              icon: Icons.insert_drive_file_outlined,
                              accentColor: const Color(0xFF16A34A),
                              title: 'Kapak Sayfası',
                              description:
                                  'Staj defterinizin ön kapağında kullanılacak resmi kapak şablonu.',
                              fileName: 'kapak.pdf',
                              fileType: 'PDF',
                              size: 'Şablon',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFileCard(
                              4,
                              icon: Icons.assignment_outlined,
                              accentColor: const Color(0xFFC62828),
                              title: 'Staj Sicil Fişi',
                              description:
                                  'Staj bitiminde kurumdaki yetkilinin doldurarak imzalayacağı belge.',
                              fileName: 'staj_sicil.pdf',
                              fileType: 'PDF',
                              size: 'Şablon',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildFileCard(
                              5,
                              icon: Icons.poll_outlined,
                              accentColor: const Color(0xFF00838F),
                              title: 'Değerlendirme Formu',
                              description:
                                  'Staj tamamlandıktan sonra deneyiminizi değerlendirmeniz için anket formu.',
                              fileName: 'degerlendirme.pdf',
                              fileType: 'PDF',
                              size: 'Şablon',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      _buildSectionTitle(
                        'SGK & Sigorta Bilgilendirmesi',
                        'Sosyal güvence ile ilgili önemli bilgiler',
                      ),
                      const SizedBox(height: 20),
                      _buildSgkCard(),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Belgeler son güncelleme: Nisan 2026',
                          style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildHelpFooter(),
          ],
        ),
      ),
    );
  }

  // ========== HERO HEADER ==========
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60, top: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purpleGlow.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: 80, bottom: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_copy, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'BELGE MERKEZİ',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Staj Belgelerin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Staj sürecinde ihtiyaç duyacağın tüm resmi belgeler ve şablonlar burada.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// ========== YÖNERGE CARD (BACKEND BAĞLI - PREMIUM) ==========
  Widget _buildYonergeCard() {
    final isHovered = _hoveredFile == 99;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredFile = 99),
      onExit: (_) => setState(() => _hoveredFile = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -6 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHovered ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFEEEEF2),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.18)
                  : primaryColor.withValues(alpha: 0.05),
              blurRadius: isHovered ? 28 : 18,
              offset: Offset(0, isHovered ? 12 : 8),
            ),
            BoxShadow(
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.08)
                  : purpleGlow.withValues(alpha: 0.03),
              blurRadius: isHovered ? 40 : 26,
              offset: Offset(0, isHovered ? 18 : 12),
            ),
          ],
        ),
        child: Row(
          children: [
            // İKON
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHovered
                      ? [primaryColor, primaryDark]
                      : [
                          primaryColor.withValues(alpha: 0.15),
                          primaryColor.withValues(alpha: 0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.gavel,
                color: isHovered ? Colors.white : primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 20),

            // İÇERİK
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MDBF Staj Usul ve Esasları',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'İstanbul Rumeli Üniversitesi Mühendislik ve Doğa Bilimleri Fakültesi resmi staj yönergesi. Okul sitesinden otomatik senkronize edilir.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // META BİLGİLER
                  if (_yonergeLoading)
                    Row(
                      children: [
                        SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Yönerge bilgisi alınıyor...',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else if (_yonergeError != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _yonergeError!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        _buildMetaBadge(
                          Icons.picture_as_pdf,
                          'PDF',
                          const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        _buildMetaBadge(
                          Icons.history,
                          _yonergeLastModified ?? '-',
                          primaryColor,
                          label: 'Son güncelleme',
                        ),
                        const SizedBox(width: 8),
                        _buildMetaBadge(
                          Icons.straighten,
                          _yonergeSize ?? '-',
                          purpleGlow,
                          label: 'Boyut',
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // İNDİR BUTONU
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _yonergeLoading ? null : _downloadYonerge,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.file_download_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Yönergeyi İndir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
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
    );
  }

  Widget _buildMetaBadge(IconData icon, String value, Color color, {String? label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          if (label != null) ...[
            Text(
              '$label: ',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ========== INFO BANNER ==========
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.05),
            purpleGlow.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2563EB).withValues(alpha: 0.2),
                  const Color(0xFF2563EB).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staj Belgeleri Hakkında',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Aşağıdaki belgeler staj sürecinizde kullanmanız gereken resmi şablonlardır. İndirip bilgisayarınızda doldurunuz.',
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECTION TITLE ==========
  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: textSecondary),
        ),
      ],
    );
  }

  // ========== FILE CARD WITH HOVER ==========
  Widget _buildFileCard(
    int index, {
    required IconData icon,
    required Color accentColor,
    required String title,
    required String description,
    required String fileName,
    required String fileType,
    required String size,
  }) {
    final isHovered = _hoveredFile == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredFile = index),
      onExit: (_) => setState(() => _hoveredFile = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -6 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered ? primaryColor.withValues(alpha: 0.3) : const Color(0xFFEEEEF2),
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? primaryColor.withValues(alpha: 0.18) : accentColor.withValues(alpha: 0.05),
              blurRadius: isHovered ? 28 : 18,
              offset: Offset(0, isHovered ? 12 : 8),
            ),
            BoxShadow(
              color: isHovered ? primaryColor.withValues(alpha: 0.08) : purpleGlow.withValues(alpha: 0.03),
              blurRadius: isHovered ? 40 : 26,
              offset: Offset(0, isHovered ? 18 : 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHovered
                          ? [accentColor, accentColor.withValues(alpha: 0.7)]
                          : [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(icon, color: isHovered ? Colors.white : accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 12, color: accentColor),
                      const SizedBox(width: 5),
                      Text(fileType, style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(size, style: const TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => _downloadTemplate(fileName),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.download, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text('İndir', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== SGK CARD ==========
  Widget _buildSgkCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBC02D).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: purpleGlow.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBC02D), Color(0xFFF9A825)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBC02D).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SGK İş Kazası Sigortası', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('Sosyal güvence ile ilgili bilmen gerekenler', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSgkInfoItem('Staj başlamadan önce SGK girişiniz okul tarafından yapılır.')),
              const SizedBox(width: 14),
              Expanded(child: _buildSgkInfoItem('Eğer kurum SGK girişinizi yapıyorsa, bunu başvuru formunda belirtmeniz yeterlidir.')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSgkInfoItem('SGK giriş belgesi sisteme yüklenmelidir.')),
              const SizedBox(width: 14),
              Expanded(child: _buildSgkInfoItem('Staj bitiminde SGK çıkışı otomatik olarak yapılır.')),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEA580C).withValues(alpha: 0.06),
                  const Color(0xFFEA580C).withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.warning_amber, color: Color(0xFFEA580C), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'SGK girişi yapılmadan staja başlamak yasalara aykırıdır.',
                    style: TextStyle(color: Color(0xFFC2410C), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSgkInfoItem(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: textPrimary, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ========== HELP FOOTER ==========
  Widget _buildHelpFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -60, top: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purpleGlow.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: 80, bottom: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.support_agent, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yardıma mı ihtiyacın var?',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Staj komisyonuna staj@rumeli.edu.tr adresinden ulaşabilirsiniz.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () async {
                        final uri = Uri.parse('mailto:staj@rumeli.edu.tr');
                        await launchUrl(uri);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.mail_outline, color: primaryColor, size: 18),
                            SizedBox(width: 10),
                            Text(
                              'İletişime Geç',
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
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
        ],
      ),
    );
  }
}