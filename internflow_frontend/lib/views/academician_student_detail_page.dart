import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademicianStudentDetailPage extends StatefulWidget {
  final Map<String, dynamic> internship;

  const AcademicianStudentDetailPage({
    super.key,
    required this.internship,
  });

  @override
  State<AcademicianStudentDetailPage> createState() =>
      _AcademicianStudentDetailPageState();
}

class _AcademicianStudentDetailPageState
    extends State<AcademicianStudentDetailPage> {
  final Color primaryColor = const Color(0xFF6A0F0F);

  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];

  late String _studentName;
  late String _studentNumber;
  late String _department;
  late String _companyName;
  late String _status;
  late String _startDate;
  late String _endDate;
  late String _internId;

  @override
  void initState() {
    super.initState();
    _initData();
    _loadDocuments();
  }

  void _initData() {
    final student = widget.internship['users'] as Map<String, dynamic>?;
    _studentName = student?['full_name'] ?? 'Bilinmeyen';
    _studentNumber = student?['student_number']?.toString() ?? '-';
    _department = student?['department'] ?? '-';
    _companyName = widget.internship['company_name'] ?? '-';
    _status = widget.internship['status'] ?? 'pending';
    _startDate = widget.internship['start_date'] ?? '';
    _endDate = widget.internship['end_date'] ?? '';
    _internId = widget.internship['intern_id'] ?? '';
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docs = await Supabase.instance.client
          .from('documents')
          .select()
          .eq('intern_id', _internId)
          .order('uploaded_at', ascending: false);

      setState(() {
        _documents = List<Map<String, dynamic>>.from(docs);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Belgeler yüklenemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewDocument(String filePath) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('documents')
          .createSignedUrl(filePath, 3600);

      final uri = Uri.parse(signedUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Belge açılamadı: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, dynamic> _getStatusInfo() {
    switch (_status) {
      case 'pending':
        return {'label': 'ONAY BEKLİYOR', 'color': const Color(0xFFE65100), 'bgColor': const Color(0xFFFFF3E0)};
      case 'approved':
        return {'label': 'ONAYLANDI', 'color': const Color(0xFF2E7D32), 'bgColor': const Color(0xFFE8F5E9)};
      case 'active':
        return {'label': 'STAJDA', 'color': const Color(0xFF1565C0), 'bgColor': const Color(0xFFE3F2FD)};
      case 'completed':
        return {'label': 'TAMAMLANDI', 'color': const Color(0xFF6A1B9A), 'bgColor': const Color(0xFFF3E5F5)};
      case 'rejected':
        return {'label': 'REDDEDİLDİ', 'color': const Color(0xFFC62828), 'bgColor': const Color(0xFFFFEBEE)};
      default:
        return {'label': _status.toUpperCase(), 'color': const Color(0xFF546E7A), 'bgColor': const Color(0xFFECEFF1)};
    }
  }

  double _getProgress() {
    switch (_status) {
      case 'pending': return 0.15;
      case 'approved': return 0.4;
      case 'active': return 0.7;
      case 'completed': return 1.0;
      default: return 0.0;
    }
  }

  int _getDaysCompleted() {
    if (_startDate.isEmpty) return 0;
    try {
      final start = DateTime.parse(_startDate);
      final now = DateTime.now();
      if (now.isBefore(start)) return 0;
      int days = 0;
      DateTime current = start;
      final end = _endDate.isNotEmpty ? DateTime.parse(_endDate) : now;
      while (current.isBefore(now) && current.isBefore(end)) {
        if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
          days++;
        }
        current = current.add(const Duration(days: 1));
      }
      return days;
    } catch (_) {
      return 0;
    }
  }

  int _getTotalDays() {
    if (_startDate.isEmpty || _endDate.isEmpty) return 0;
    try {
      final start = DateTime.parse(_startDate);
      final end = DateTime.parse(_endDate);
      int days = 0;
      DateTime current = start;
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
          days++;
        }
        current = current.add(const Duration(days: 1));
      }
      return days;
    } catch (_) {
      return 0;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getDocTypeName(String docType) {
    switch (docType) {
      case 'basvuru_formu': return 'Başvuru / Kabul Formu';
      case 'sgk_belgesi': return 'SGK Giriş Belgesi';
      case 'staj_defteri': return 'Staj Defteri';
      case 'anket': return 'Firma Değerlendirme Anketi';
      default: return docType;
    }
  }

  IconData _getDocTypeIcon(String docType) {
    switch (docType) {
      case 'basvuru_formu': return Icons.description;
      case 'sgk_belgesi': return Icons.security;
      case 'staj_defteri': return Icons.book;
      case 'anket': return Icons.poll;
      default: return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();
    final daysCompleted = _getDaysCompleted();
    final totalDays = _getTotalDays();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), 
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusInfo['color'],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(statusInfo['label'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _studentName.isNotEmpty ? _studentName[0].toUpperCase() : '?',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_studentName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$_department  |  No: $_studentNumber', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.calendar_today, size: 20, color: statusInfo['color']),
                            ),
                            const SizedBox(width: 16),
                            const Text('Staj Süreci', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2C3E50))),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: statusInfo['bgColor'], borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                totalDays > 0 ? '$daysCompleted. Gün' : 'Başlamadı',
                                style: TextStyle(fontWeight: FontWeight.bold, color: statusInfo['color'], fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _getProgress(), 
                            minHeight: 10,
                            backgroundColor: const Color(0xFFF1F2F6),
                            valueColor: AlwaysStoppedAnimation<Color>(statusInfo['color']),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(_startDate), style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
                            Text(_formatDate(_endDate), style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA), 
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE9ECEF)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.business, size: 20, color: Color(0xFF95A5A6)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_companyName, style: const TextStyle(fontSize: 15, color: Color(0xFF34495E), fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Row(
                                   children: [
                                     Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                     SizedBox(width: 10),
                                     Expanded(child: Text('AI Analiz modülü final döneminde aktifleşecektir.')),
                                    ],
                                   ),
                                  backgroundColor: Color(0xFF5A0B0B),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 3),
                                ),
                               );
                            },
                          child: Container(
                            height: 125,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF801313), Color(0xFF5A0B0B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 30),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('AI Analiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    SizedBox(height: 2),
                                    Text('Panelini Aç', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Container(
                          height: 125,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4))],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                totalDays > 0 ? '$daysCompleted / $totalDays' : '- / -',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: statusInfo['color']),
                              ),
                              const SizedBox(height: 6),
                              const Text('Gün Tamamlandı', style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: totalDays > 0 ? daysCompleted / totalDays : 0,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFF1F2F6),
                                  valueColor: AlwaysStoppedAnimation<Color>(statusInfo['color']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Yüklenen Belgeler', trailing: '${_documents.length} dosya'),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_documents.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE9ECEF), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Öğrenci henüz belge yüklemedi', style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  else
                    ..._documents.map((doc) => _buildDocumentCard(doc)),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Başvuru Detayları'),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.work_outline, 'Staj Türü', widget.internship['internship_type'] == 'summer' ? 'Yaz Stajı' : 'Dönem İçi'),
                        _buildDivider(),
                        _buildInfoRow(Icons.business, 'Kurum Adı', _companyName),
                        _buildDivider(),
                        _buildInfoRow(Icons.category_outlined, 'Sektör', widget.internship['company_sector'] ?? '-'),
                        _buildDivider(),
                        _buildInfoRow(Icons.location_on_outlined, 'Adres', widget.internship['company_address'] ?? '-'),
                        _buildDivider(),
                        _buildInfoRow(Icons.email_outlined, 'Kurum E-Posta', widget.internship['company_email'] ?? '-'),
                        _buildDivider(),
                        _buildInfoRow(Icons.person_outline, 'Yetkili Mühendis', widget.internship['supervisor_name'] ?? '-'),
                        _buildDivider(),
                        _buildInfoRow(Icons.security_outlined, 'SGK Durumu', widget.internship['has_sgk'] == true ? 'Öğrenciden (Müstehaklık var)' : 'Okul Tarafından Yapılacak'),
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

  Widget _buildSectionTitle(String title, {String? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 5, height: 20, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        if (trailing != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE9ECEF), borderRadius: BorderRadius.circular(10)),
            child: Text(trailing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D))),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final docType = doc['doc_type'] as String? ?? '';
    final fileUrl = doc['file_url'] as String? ?? '';
    final uploadedAt = doc['uploaded_at']?.toString().split('T')[0] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F2F6), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
            child: Icon(_getDocTypeIcon(docType), color: const Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getDocTypeName(docType), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50))),
                const SizedBox(height: 4),
                Text('Yüklendi: $uploadedAt', style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _viewDocument(fileUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Text('İncele', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: const Color(0xFF95A5A6)),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(label, style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(value, style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: const Color(0xFFF1F2F6), thickness: 1.5);
  }
}