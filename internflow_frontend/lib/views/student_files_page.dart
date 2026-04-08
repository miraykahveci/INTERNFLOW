import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';


class StudentFilesPage extends StatelessWidget {
  const StudentFilesPage({super.key});
 
  final Color primaryColor = const Color(0xFF6A0F0F);
 
  Future<void> _downloadTemplate(String fileName, BuildContext context) async {
    try {
      final url =
          '${Supabase.instance.client.rest.url.replaceAll('/rest/v1', '')}/storage/v1/object/public/templates/$fileName';
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya açılamadı: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.folder_copy, color: Colors.white, size: 26),
                    SizedBox(width: 12),
                    Text(
                      'Belge Merkezi',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Staj sürecinde ihtiyaç duyacağın tüm belgeler ve bilgiler',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
 
          // İÇERİK
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF90CAF9), width: 0.5),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Staj Belgeleri Hakkında',
                                style: TextStyle(color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Aşağıdaki belgeler staj sürecinizde kullanmanız gereken resmi şablonlardır. İndirip bilgisayarınızda doldurunuz.',
                                style: TextStyle(color: Color(0xFF1976D2), fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
 
                  // BAŞLANGIÇ BELGELERİ
                  _buildSectionTitle('Başlangıç Belgeleri'),
                  const SizedBox(height: 12),
 
                  _buildFileCard(
                    context: context,
                    icon: Icons.description,
                    iconColor: const Color(0xFF1565C0),
                    iconBgColor: const Color(0xFFE3F2FD),
                    title: 'Staj Kabul Formu',
                    description: 'Staj yapacağınız kurumun doldurması gereken resmi kabul belgesi. İmzalatıp sisteme yüklemeniz gerekir.',
                    fileName: 'kabul_formu.pdf',
                    fileType: 'PDF',
                    fileSize: 'Şablon',
                  ),
 
                  _buildFileCard(
                    context: context,
                    icon: Icons.security,
                    iconColor: const Color(0xFF6A1B9A),
                    iconBgColor: const Color(0xFFF3E5F5),
                    title: 'Staj Koşulları ve Kurallar',
                    description: 'Staj süresince uymanız gereken kurallar, devamsızlık limitleri ve değerlendirme kriterleri.',
                    fileName: 'staj_kosul.pdf',
                    fileType: 'PDF',
                    fileSize: 'Bilgilendirme',
                  ),
 
                  const SizedBox(height: 24),
 
                  // DÖNEM İÇİ BELGELER
                  _buildSectionTitle('Dönem İçi & Final Belgeleri'),
                  const SizedBox(height: 12),
 
                  _buildFileCard(
                    context: context,
                    icon: Icons.book,
                    iconColor: const Color(0xFFE65100),
                    iconBgColor: const Color(0xFFFFF3E0),
                    title: 'Staj Günlüğü / Defteri',
                    description: 'Staj süresince günlük olarak doldurmanız gereken çalışma kayıtları. Her iş günü için ayrı giriş yapılmalıdır.',
                    fileName: 'staj_gunlugu.pdf',
                    fileType: 'PDF',
                    fileSize: 'Şablon',
                  ),
 
                  _buildFileCard(
                    context: context,
                    icon: Icons.insert_drive_file,
                    iconColor: const Color(0xFF2E7D32),
                    iconBgColor: const Color(0xFFE8F5E9),
                    title: 'Kapak Sayfası',
                    description: 'Staj defterinizin ön kapağında kullanılacak resmi kapak şablonu. Ad, numara ve kurum bilgilerini doldurunuz.',
                    fileName: 'kapak.pdf',
                    fileType: 'PDF',
                    fileSize: 'Şablon',
                  ),
 
                  _buildFileCard(
                    context: context,
                    icon: Icons.assignment,
                    iconColor: const Color(0xFFC62828),
                    iconBgColor: const Color(0xFFFFEBEE),
                    title: 'Staj Sicil Fişi',
                    description: 'Staj bitiminde kurumdaki yetkilinin doldurarak imzalayacağı performans değerlendirme belgesi.',
                    fileName: 'staj_sicil.pdf',
                    fileType: 'PDF',
                    fileSize: 'Şablon',
                  ),
 
                  _buildFileCard(
                    context: context,
                    icon: Icons.poll,
                    iconColor: const Color(0xFF00838F),
                    iconBgColor: const Color(0xFFE0F7FA),
                    title: 'Değerlendirme Formu',
                    description: 'Staj tamamlandıktan sonra kurumu ve deneyiminizi değerlendirmeniz için kullanılan anket formu.',
                    fileName: 'degerlendirme.pdf',
                    fileType: 'PDF',
                    fileSize: 'Şablon',
                  ),
 
                  const SizedBox(height: 24),
 
                  // SGK BİLGİLENDİRME
                  _buildSectionTitle('SGK & Sigorta Bilgilendirmesi'),
                  const SizedBox(height: 12),
 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield, color: Color(0xFFFBC02D), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('SGK İş Kazası Sigortası', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildSgkInfoItem('Staj başlamadan önce SGK girişiniz okul tarafından yapılır.'),
                        _buildSgkInfoItem('Eğer kurum SGK girişinizi yapıyorsa, bunu başvuru formunda belirtmeniz yeterlidir.'),
                        _buildSgkInfoItem('SGK giriş belgesi sisteme yüklenmelidir.'),
                        _buildSgkInfoItem('Staj bitiminde SGK çıkışı otomatik olarak yapılır.'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber, color: Color(0xFFFB8C00), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'SGK girişi yapılmadan staja başlamak yasalara aykırıdır.',
                                  style: TextStyle(color: Color(0xFFE65100), fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
 
                  // İLETİŞİM
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.support_agent, color: primaryColor, size: 32),
                        const SizedBox(height: 10),
                        Text(
                          'Yardıma mı ihtiyacın var?',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Staj komisyonuna staj@rumeli.edu.tr adresinden ulaşabilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF757575), fontSize: 12),
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
 
  // ========== BÖLÜM BAŞLIĞI ==========
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
      ],
    );
  }
 
  // ========== DOSYA KARTI ==========
  Widget _buildFileCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required String fileName,
    required String fileType,
    required String fileSize,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF37474F))),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF757575), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      fileType == 'PDF' ? Icons.picture_as_pdf : Icons.article,
                      size: 12,
                      color: fileType == 'PDF' ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(fileType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF757575))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(fileSize, style: const TextStyle(fontSize: 10, color: Color(0xFF757575))),
              ),
              const Spacer(),
              
              GestureDetector(
                onTap: () => _downloadTemplate(fileName, context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.download, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('İndir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  // ========== SGK BİLGİ SATIRI ==========
  Widget _buildSgkInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A), height: 1.4)),
          ),
        ],
      ),
    );
  }
}
 