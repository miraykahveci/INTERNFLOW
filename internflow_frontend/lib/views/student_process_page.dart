import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

enum StepStatus { completed, current, locked }

class StudentProcessPage extends StatefulWidget {
  const StudentProcessPage({super.key});

  @override
  State<StudentProcessPage> createState() => _StudentProcessPageState();
}

class _StudentProcessPageState extends State<StudentProcessPage> {
  final Color primaryColor = const Color(0xFF6A0F0F);

  bool _isLoading = true;
  String _internshipStatus = 'none';
  String _academicianName = 'Atanıyor...';
  String _applicationDate = '';
  int _progressPercentage = 0;
  String? _internId; // Staj kaydının ID'si (documents tablosu için lazım)

  // Belge yükleme durumları
  bool _isUploading = false;
  bool _islakImzaUploaded = false;
  bool _sgkBelgesiUploaded = false;
  String? _islakImzaFileName;
  String? _sgkBelgesiFileName;

  @override
  void initState() {
    super.initState();
    _loadProcessData();
  }

  // ============================================================
  // VERİ YÜKLEME
  // ============================================================

  Future<void> _loadProcessData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Öğrencinin son başvurusunu ve akademisyen bilgilerini çek
      final response = await Supabase.instance.client
          .from('internship')
          .select(
              'intern_id, status, created_at, academician_id, users!internship_academician_id_fkey(full_name, title)')
          .eq('student_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final status = response['status'] as String;
        final academician = response['users'];
        final createdAt = DateTime.parse(response['created_at']);
        final internId = response['intern_id'] as String;

        // İlerleme yüzdesini duruma göre belirle
        int progress = 0;
        if (status == 'pending') progress = 20;
        if (status == 'approved') progress = 40;
        if (status == 'active') progress = 70;
        if (status == 'completed') progress = 100;

        setState(() {
          _internshipStatus = status;
          _progressPercentage = progress;
          _internId = internId;
          _applicationDate =
              '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';
          if (academician != null) {
            _academicianName =
                '${academician['title'] ?? ''} ${academician['full_name'] ?? ''}'
                    .trim();
          }
        });

        // Yüklenmiş belgeleri kontrol et
        await _checkUploadedDocuments(internId);
      }
    } catch (e) {
      debugPrint('Süreç verisi çekilemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUploadedDocuments(String internId) async {
    try {
      final docs = await Supabase.instance.client
          .from('documents')
          .select('doc_type, file_url')
          .eq('intern_id', internId);

      for (var doc in docs) {
        final type = doc['doc_type'] as String;
        final url = doc['file_url'] as String;
        final fileName = url.split('/').last;

        if (type == 'basvuru_formu') {
          setState(() {
            _islakImzaUploaded = true;
            _islakImzaFileName = fileName;
          });
        } else if (type == 'sgk_belgesi') {
          setState(() {
            _sgkBelgesiUploaded = true;
            _sgkBelgesiFileName = fileName;
          });
        }
      }
    } catch (e) {
      debugPrint('Belge kontrol hatası: $e');
    }
  }

  // ============================================================
  // DOSYA YÜKLEME FONKSİYONU
  // ============================================================

  Future<void> _pickAndUploadFile(String docType) async {
    try {
      // 1. Dosya seçiciyi aç (sadece PDF)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // Boyut kontrolü (10MB)
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dosya boyutu 10MB\'dan büyük olamaz!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileName =
          '${docType}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storagePath = '$userId/$fileName';

      // 2. Supabase Storage'a yükle
      final fileBytes = File(file.path!).readAsBytesSync();

      await Supabase.instance.client.storage
          .from('documents')
          .uploadBinary(storagePath, fileBytes,
              fileOptions: const FileOptions(contentType: 'application/pdf'));

      // 3. Documents tablosuna kaydet
      await Supabase.instance.client.from('documents').insert({
        'intern_id': _internId,
        'file_url': storagePath,
        'doc_type': docType,
      });

      // 4. UI güncelle
      setState(() {
        if (docType == 'basvuru_formu') {
          _islakImzaUploaded = true;
          _islakImzaFileName = file.name;
        } else if (docType == 'sgk_belgesi') {
          _sgkBelgesiUploaded = true;
          _sgkBelgesiFileName = file.name;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} başarıyla yüklendi! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Dosya yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yükleme başarısız: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                  decoration: BoxDecoration(color: primaryColor),
                  child: Row(
                    children: [
                      const Icon(Icons.timeline, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      const Text(
                        'Staj Sürecim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        onPressed: _loadProcessData,
                      )
                    ],
                  ),
                ),

                // SCROLL EDİLEBİLİR İÇERİK
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildProgressCard(),
                        const SizedBox(height: 32),

                        // TIMELINE
                        _buildTimelineStep(
                          stepNumber: 1,
                          isFirst: true,
                          title: 'Başvuru Gönderildi',
                          subtitle: _applicationDate.isNotEmpty
                              ? _applicationDate
                              : 'Tarih Bekleniyor',
                          status: _internshipStatus != 'none'
                              ? StepStatus.completed
                              : StepStatus.locked,
                          icon: Icons.send,
                        ),
                        _buildTimelineStep(
                          stepNumber: 2,
                          title: 'Akademisyen Değerlendirmesi',
                          subtitle: _getStepStatus(2) == StepStatus.current
                              ? 'Şu anki aşama'
                              : _getStepStatus(2) == StepStatus.completed
                                  ? 'Onaylandı'
                                  : 'Onay bekleniyor',
                          status: _getStepStatus(2),
                          icon: Icons.person_search,
                          customContent: _getStepStatus(2) == StepStatus.current
                              ? _buildAcademicianInfoBox()
                              : null,
                        ),
                        _buildTimelineStep(
                          stepNumber: 3,
                          title: 'Islak İmzalı Belge Teslimi',
                          subtitle: _islakImzaUploaded
                              ? 'Yüklendi: $_islakImzaFileName'
                              : '(Akademik onay sonrası aktifleşir)',
                          status: _getStepStatus(3),
                          icon: Icons.upload_file,
                          customContent: _getStepStatus(3) == StepStatus.current &&
                                  !_islakImzaUploaded
                              ? _buildUploadBox(
                                  docType: 'basvuru_formu',
                                  title: 'Islak İmzalı Kabul Formu',
                                  description:
                                      'Danışmanınız tarafından onaylanan belgenin ıslak imzalı halini PDF olarak yükleyiniz.',
                                )
                              : _islakImzaUploaded
                                  ? _buildUploadedFileInfo(
                                      fileName: _islakImzaFileName!,
                                      docType: 'basvuru_formu',
                                    )
                                  : null,
                        ),
                        _buildTimelineStep(
                          stepNumber: 4,
                          title: 'SGK / Sigorta Belgesi Yükle',
                          subtitle: _sgkBelgesiUploaded
                              ? 'Yüklendi: $_sgkBelgesiFileName'
                              : '(Islak imzalı belge sonrası aktifleşir)',
                          status: _getStepStatus(4),
                          icon: Icons.security,
                          customContent: _getStepStatus(4) == StepStatus.current &&
                                  !_sgkBelgesiUploaded
                              ? _buildUploadBox(
                                  docType: 'sgk_belgesi',
                                  title: 'SGK Giriş Bildirgesi',
                                  description:
                                      'Okul veya kurumunuz tarafından düzenlenen SGK belgesini PDF olarak yükleyiniz.',
                                )
                              : _sgkBelgesiUploaded
                                  ? _buildUploadedFileInfo(
                                      fileName: _sgkBelgesiFileName!,
                                      docType: 'sgk_belgesi',
                                    )
                                  : null,
                        ),
                        _buildTimelineStep(
                          stepNumber: 5,
                          title: 'Staj Dönemi',
                          subtitle: _getStepStatus(5) == StepStatus.current
                              ? 'Stajınız devam ediyor'
                              : 'SGK girişi sonrası başlar.',
                          status: _getStepStatus(5),
                          icon: Icons.work_history,
                        ),
                        _buildTimelineStep(
                          stepNumber: 6,
                          isLast: true,
                          title: 'Defter Teslimi & Değerlendirme',
                          subtitle: 'Staj bitiminde aktifleşir.',
                          status: _getStepStatus(6),
                          icon: Icons.verified,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // ADIM DURUMU HESAPLAMA
  // ============================================================

  StepStatus _getStepStatus(int stepIndex) {
    if (_internshipStatus == 'none' || _internshipStatus == 'rejected') {
      return StepStatus.locked;
    }

    if (stepIndex == 2) {
      if (_internshipStatus == 'pending') return StepStatus.current;
      return StepStatus.completed;
    }
    if (stepIndex == 3) {
      if (_internshipStatus == 'pending') return StepStatus.locked;
      if (_internshipStatus == 'approved') {
        return _islakImzaUploaded ? StepStatus.completed : StepStatus.current;
      }
      return StepStatus.completed;
    }
    if (stepIndex == 4) {
      if (_internshipStatus == 'pending') return StepStatus.locked;
      if (_internshipStatus == 'approved') {
        if (!_islakImzaUploaded) return StepStatus.locked;
        return _sgkBelgesiUploaded ? StepStatus.completed : StepStatus.current;
      }
      return StepStatus.completed;
    }
    if (stepIndex == 5) {
      if (_internshipStatus == 'active') return StepStatus.current;
      if (_internshipStatus == 'completed') return StepStatus.completed;
      return StepStatus.locked;
    }
    if (stepIndex == 6) {
      if (_internshipStatus == 'completed') return StepStatus.current;
      return StepStatus.locked;
    }
    return StepStatus.locked;
  }

  // ============================================================
  // WIDGET YAPICILAR
  // ============================================================

  Widget _buildProgressCard() {
    String statusText;
    if (_internshipStatus == 'pending') {
      statusText = 'Akademik Onay Süreci';
    } else if (_internshipStatus == 'approved') {
      statusText = 'Belge Teslim Süreci';
    } else if (_internshipStatus == 'active') {
      statusText = 'Staj Dönemi';
    } else if (_internshipStatus == 'completed') {
      statusText = 'Süreç Tamamlandı';
    } else {
      statusText = 'Başvuru Bekleniyor';
    }

    return Card(
      elevation: 8,
      color: const Color(0xFF37474F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _progressPercentage / 100,
                    backgroundColor: const Color(0xFF546E7A),
                    color: Colors.white,
                    strokeWidth: 6,
                  ),
                  Center(
                    child: Text(
                      '%$_progressPercentage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genel Durum',
                    style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== DOSYA YÜKLEME KUTUSU ==========
  Widget _buildUploadBox({
    required String docType,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA726),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_upload, color: Color(0xFFFB8C00), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Sadece PDF • Maks. 10MB',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : () => _pickAndUploadFile(docType),
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.attach_file, color: Colors.white, size: 18),
              label: Text(
                _isUploading ? 'Yükleniyor...' : 'PDF Dosyası Seç ve Yükle',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB8C00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== YÜKLENMIŞ DOSYA BİLGİSİ ==========
  Widget _buildUploadedFileInfo({
    required String fileName,
    required String docType,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Belge Yüklendi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4CAF50),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.picture_as_pdf, color: Color(0xFF2E7D32), size: 24),
        ],
      ),
    );
  }

  // ========== TIMELINE ADIMI ==========
  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required StepStatus status,
    required IconData icon,
    bool isFirst = false,
    bool isLast = false,
    Widget? customContent,
  }) {
    Color dotColor;
    Color lineColor = const Color(0xFFE0E0E0);
    Color cardColor;
    Color textColor;

    if (status == StepStatus.completed) {
      dotColor = const Color(0xFF43A047);
      lineColor = const Color(0xFF43A047);
      cardColor = Colors.white;
      textColor = const Color(0xFF43A047);
    } else if (status == StepStatus.current) {
      dotColor = const Color(0xFFFB8C00);
      cardColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFFB8C00);
    } else {
      dotColor = const Color(0xFF9E9E9E);
      cardColor = Colors.transparent;
      textColor = const Color(0xFF757575);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst
                      ? Colors.transparent
                      : (status == StepStatus.completed
                          ? lineColor
                          : const Color(0xFFE0E0E0)),
                ),
                Container(
                  width: status == StepStatus.current ? 20 : 16,
                  height: status == StepStatus.current ? 20 : 16,
                  decoration: BoxDecoration(
                    color: status == StepStatus.completed
                        ? dotColor
                        : Colors.white,
                    border: Border.all(
                      color: dotColor,
                      width: status == StepStatus.locked ? 2 : 4,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: status == StepStatus.completed
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: status == StepStatus.locked
                      ? Border.all(color: const Color(0xFFE0E0E0))
                      : null,
                  boxShadow: status != StepStatus.locked &&
                          cardColor != Colors.transparent
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: textColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: status == StepStatus.locked
                                  ? const Color(0xFF616161)
                                  : textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: status == StepStatus.locked
                            ? const Color(0xFF9E9E9E)
                            : (status == StepStatus.current
                                ? const Color(0xFFF57C00)
                                : const Color(0xFF9E9E9E)),
                        fontSize: 11,
                      ),
                    ),
                    if (customContent != null) ...[
                      const SizedBox(height: 16),
                      customContent,
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== AKADEMİSYEN BİLGİ KUTUSU ==========
  Widget _buildAcademicianInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: Color(0xFFFB8C00), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _academicianName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Ortalama inceleme süresi: 3-5 gün',
                      style:
                          TextStyle(color: Color(0xFF757575), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFFFBC02D), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu aşamada akademisyeniniz belgelerinizi inceler. Eksik görülürse bildirim alırsınız.',
                    style: TextStyle(color: Color(0xFFF57F17), fontSize: 11),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}