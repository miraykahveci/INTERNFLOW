import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'student_process_page_mobile.dart';
import 'application_form_page.dart'; 

class StudentProcessWeb extends StatefulWidget {
  const StudentProcessWeb({super.key});

  @override
  State<StudentProcessWeb> createState() => _StudentProcessWebState();
}

class _StudentProcessWebState extends State<StudentProcessWeb> {
  
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  bool _isLoading = true;
  String _internshipStatus = 'none';
  String _academicianName = 'Atanıyor...';
  String _applicationDate = '';
  int _progressPercentage = 0;
  String? _internId;
  String? _internshipResult; 
  DateTime? _completedAt;

  bool _isUploading = false;
  bool _islakImzaUploaded = false;
  bool _sgkBelgesiUploaded = false;
  String? _islakImzaFileName;
  String? _sgkBelgesiFileName;

  int _hoveredStep = -1;

  @override
  void initState() {
    super.initState();
    _loadProcessData();
  }

  Future<void> _loadProcessData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final response = await Supabase.instance.client
          .from('internship')
          .select(
              'intern_id, status, result, completed_at, created_at, academician_id, users!internship_academician_id_fkey(full_name, title)')
          .eq('student_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final status = response['status'] as String;
        final academician = response['users'];
        final createdAt = DateTime.parse(response['created_at']);
        final internId = response['intern_id'] as String;

        int progress = 0;
        if (status == 'pending') progress = 20;
        if (status == 'approved') progress = 40;
        if (status == 'active') progress = 70;
        if (status == 'completed') progress = 100;

        setState(() {
          _internshipStatus = status;
          _progressPercentage = progress;
          _internId = internId;
          _internshipResult = response['result'] as String?;
          _completedAt = response['completed_at'] != null
              ? DateTime.tryParse(response['completed_at'].toString())
              : null;
          _applicationDate =
              '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';
          if (academician != null) {
            _academicianName = '${academician['title'] ?? ''} ${academician['full_name'] ?? ''}'.trim();
          }
        });

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

  Future<void> _pickAndUploadFile(String docType) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true,  
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya boyutu 10MB\'dan büyük olamaz!'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final fileName = '${docType}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final storagePath = '$userId/$fileName';


    final fileBytes = file.bytes;
    if (fileBytes == null) {
      throw Exception('Dosya okunamadı (bytes null)');
    }

    await Supabase.instance.client.storage
        .from('documents')
        .uploadBinary(storagePath, fileBytes,
            fileOptions: const FileOptions(contentType: 'application/pdf'));

    await Supabase.instance.client.from('documents').insert({
      'intern_id': _internId,
      'file_url': storagePath,
      'doc_type': docType,
    });

    setState(() {
      if (docType == 'basvuru_formu') {
        _islakImzaUploaded = true;
        _islakImzaFileName = file.name;
      } else if (docType == 'sgk_belgesi') {
        _sgkBelgesiUploaded = true;
        _sgkBelgesiFileName = file.name;
      }
    });
    
    
if (docType == 'sgk_belgesi' || docType == 'basvuru_formu') {
  final docs = await Supabase.instance.client
      .from('documents')
      .select('doc_type')
      .eq('intern_id', _internId!);

  final uploadedTypes =
      (docs as List).map((d) => d['doc_type'] as String).toSet();
  final hasBasvuru = uploadedTypes.contains('basvuru_formu');
  final hasSgk = uploadedTypes.contains('sgk_belgesi');

  final internRow = await Supabase.instance.client
      .from('internship')
      .select('status')
      .eq('intern_id', _internId!)
      .single();
  final currentStatus = internRow['status'] as String;

  if (hasBasvuru && hasSgk && currentStatus == 'approved') {
    await Supabase.instance.client
        .from('internship')
        .update({'status': 'active'})
        .eq('intern_id', _internId!);

    setState(() {
      _internshipStatus = 'active';
      _progressPercentage = 70;
    });
  }
}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.name} başarıyla yüklendi! ✅'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yükleme başarısız: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isUploading = false);
  }
}






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
     if (_internshipStatus == 'completed') return StepStatus.completed;
     if (_internshipStatus == 'active') return StepStatus.current;
      return StepStatus.locked;
    }
    return StepStatus.locked;
  }

  String _getStatusText() {
    if (_internshipStatus == 'pending') return 'Akademik Onay Süreci';
    if (_internshipStatus == 'approved') return 'Belge Teslim Süreci';
    if (_internshipStatus == 'active') return 'Staj Dönemi';
    if (_internshipStatus == 'completed') return 'Süreç Tamamlandı';
    if (_internshipStatus == 'rejected') return 'Başvuru Reddedildi';
    return 'Başvuru Bekleniyor';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgCanvas,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

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
                      _buildOverviewCards(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Süreç Adımları', 'Staj başvurunuzun her aşamasını buradan takip edebilirsiniz'),
                      const SizedBox(height: 24),
                      _buildTimelineGrid(),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timeline, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText().toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Staj Sürecim',
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
                          'Başvuru süreçinizin her aşamasını canlı olarak takip edin.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                          ),
                        ),
                        
if (_internshipStatus == 'rejected') ...[
  const SizedBox(height: 20),
  ElevatedButton.icon(
    onPressed: () async {
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplicationFormPage()));
      if (result == true) _loadProcessData(); 
    },
    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
    label: const Text('Yeni Başvuru Yap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFDC2626), 
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      elevation: 4,
    ),
  ),
],
                      ],
                    ),
                  ),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: _loadProcessData,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.refresh, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Yenile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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

  // ========== OVERVIEW CARDS ==========
  Widget _buildOverviewCards() {
    final isInactive = _internshipStatus == 'none' || _internshipStatus == 'rejected';
    final completedCount = isInactive
        ? 0
        : [1, 2, 3, 4, 5, 6].where((i) =>
            _getStepStatus(i) == StepStatus.completed ||
            (i == 1)  
          ).length;

    return Row(
      children: [
        Expanded(child: _buildOverviewCard(
          Icons.percent_outlined,
          'İlerleme',
          '%$_progressPercentage',
          primaryColor,
          showProgress: true,
        )),
        const SizedBox(width: 20),
        Expanded(child: _buildOverviewCard(
          Icons.task_alt,
          'Tamamlanan Adım',
          '$completedCount / 6',
          purpleGlow,
        )),
        const SizedBox(width: 20),
        Expanded(child: _buildOverviewCard(
          Icons.calendar_today_outlined,
          'Başvuru Tarihi',
          _applicationDate.isNotEmpty ? _applicationDate : '-',
          const Color(0xFF2563EB),
        )),
        const SizedBox(width: 20),
        Expanded(child: _buildOverviewCard(
          Icons.flag_outlined,
          'Mevcut Durum',
          _getStatusText(),
          const Color(0xFF16A34A),
          isLong: true,
        )),
      ],
    );
  }

  Widget _buildOverviewCard(IconData icon, String label, String value, Color accentColor, {bool showProgress = false, bool isLong = false}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: purpleGlow.withValues(alpha: 0.04),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: TextStyle(
              fontSize: isLong ? 16 : 26,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -0.6,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressPercentage / 100,
                backgroundColor: const Color(0xFFF4F4F5),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

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

  // ========== TIMELINE GRID ==========
  Widget _buildTimelineGrid() {
    final step6Subtitle = _internshipStatus == 'completed'
    ? 'Stajınız başarıyla tamamlandı'
    : _internshipStatus == 'active'
        ? 'Defter yükleyebilirsiniz'
        : 'Staj döneminde aktifleşir';

    final steps = [
      _StepData(
  1, 
  'Başvuru Gönderildi', 
  _internshipStatus == 'rejected' ? 'Başvurunuz akademisyen tarafından reddedildi' : (_applicationDate.isNotEmpty ? _applicationDate : 'Tarih bekleniyor'), 
  Icons.send,
  (_internshipStatus != 'none' && _internshipStatus != 'rejected') ? StepStatus.completed : StepStatus.locked
),
      _StepData(2, 'Akademisyen Değerlendirmesi',
          _getStepStatus(2) == StepStatus.current ? 'Şu anki aşama' : _getStepStatus(2) == StepStatus.completed ? 'Onaylandı' : 'Onay bekleniyor',
          Icons.person_search, _getStepStatus(2)),
      _StepData(3, 'Islak İmzalı Belge',
          _islakImzaUploaded ? 'Yüklendi' : 'Akademik onay sonrası aktifleşir',
          Icons.upload_file, _getStepStatus(3)),
      _StepData(4, 'SGK / Sigorta Belgesi',
          _sgkBelgesiUploaded ? 'Yüklendi' : 'Islak imzalı belge sonrası',
          Icons.security, _getStepStatus(4)),
      _StepData(5, 'Staj Dönemi',
          _getStepStatus(5) == StepStatus.current ? 'Stajınız devam ediyor' : 'SGK girişi sonrası başlar',
          Icons.work_history, _getStepStatus(5)),
      _StepData(6, 'Defter & Değerlendirme', step6Subtitle,
          Icons.verified, _getStepStatus(6)),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildTimelineCard(steps[i], i),
        );
      }),
    );
  }

  Widget _buildTimelineCard(_StepData step, int index) {
    final isHovered = _hoveredStep == index;
    final isCompleted = step.status == StepStatus.completed;
    final isCurrent = step.status == StepStatus.current;
    final isLocked = step.status == StepStatus.locked;

    Color stepColor;
    if (isCompleted) {
      stepColor = const Color(0xFF16A34A);
    } else if (isCurrent) {
      stepColor = primaryColor;
    } else {
      stepColor = textMuted;
    }

    Widget? customContent;
    if (step.stepNumber == 2 && isCurrent) {
      customContent = _buildAcademicianBox();
    } else if (step.stepNumber == 3) {
      if (isCurrent && !_islakImzaUploaded) {
        customContent = _buildUploadBox(
          docType: 'basvuru_formu',
          title: 'Islak İmzalı Kabul Formu',
          description: 'Danışmanınız tarafından onaylanan belgenin ıslak imzalı halini PDF olarak yükleyiniz.',
        );
      } else if (_islakImzaUploaded) {
        customContent = _buildUploadedFileInfo(_islakImzaFileName!);
      }
    } else if (step.stepNumber == 4) {
      if (isCurrent && !_sgkBelgesiUploaded) {
        customContent = _buildUploadBox(
          docType: 'sgk_belgesi',
          title: 'SGK Giriş Bildirgesi',
          description: 'Okul veya kurumunuz tarafından düzenlenen SGK belgesini PDF olarak yükleyiniz.',
        );
      } else if (_sgkBelgesiUploaded) {
        customContent = _buildUploadedFileInfo(_sgkBelgesiFileName!);
      }
      
    } else if (step.stepNumber == 6 && _internshipStatus == 'active') {
  customContent = _buildUploadBox(
    docType: 'staj_defteri',
    title: 'Staj Defteri',
    description: 'Staj sürenizdeki günlük raporları PDF olarak yükleyin. AI sistemi otomatik olarak intihal kontrolü ve özet üretir.',
  );
}
    
    
    else if (step.stepNumber == 6 && _internshipStatus == 'completed') {
      customContent = _buildCompletionInfoBox();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredStep = index),
      onExit: (_) => setState(() => _hoveredStep = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered && !isLocked ? -4 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFFAFAFC) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered && !isLocked
                ? primaryColor.withValues(alpha: 0.3)
                : isCurrent
                    ? primaryColor.withValues(alpha: 0.2)
                    : const Color(0xFFEEEEF2),
            width: (isHovered && !isLocked) || isCurrent ? 1.5 : 1,
          ),
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color: isHovered
                        ? primaryColor.withValues(alpha: 0.18)
                        : stepColor.withValues(alpha: 0.05),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)])
                        : isCurrent
                            ? const LinearGradient(colors: [primaryColor, primaryDark])
                            : null,
                    color: isLocked ? const Color(0xFFF4F4F5) : null,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: isCompleted || isCurrent
                        ? [
                            BoxShadow(
                              color: stepColor.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 26)
                        : isLocked
                            ? Icon(Icons.lock_outline, color: textMuted, size: 22)
                            : Icon(step.icon, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: stepColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ADIM ${step.stepNumber}',
                              style: TextStyle(color: stepColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, color: Colors.white, size: 6),
                                  SizedBox(width: 5),
                                  Text('ŞU AN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 11),
                                  SizedBox(width: 4),
                                  Text('TAMAMLANDI', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? textMuted : textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isLocked ? textMuted : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (customContent != null) ...[
              const SizedBox(height: 18),
              customContent,
            ],
          ],
        ),
      ),
    );
  }

  // ========== ACADEMICIAN INFO BOX ==========
  Widget _buildAcademicianBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.04),
            purpleGlow.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryColor, primaryDark]),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _academicianName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: textSecondary),
                    const SizedBox(width: 4),
                    const Text(
                      'Ortalama inceleme süresi: 3-5 gün',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== UPLOAD BOX ==========
  Widget _buildUploadBox({required String docType, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEA580C).withValues(alpha: 0.05),
            const Color(0xFFEA580C).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PDF',
                            style: TextStyle(color: Color(0xFFC2410C), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Maks. 10MB', style: TextStyle(fontSize: 11, color: textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : () => _pickAndUploadFile(docType),
              icon: _isUploading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file, color: Colors.white, size: 18),
              label: Text(
                _isUploading ? 'Yükleniyor...' : 'PDF Dosyası Seç ve Yükle',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                elevation: 6,
                shadowColor: const Color(0xFFEA580C).withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== UPLOADED FILE INFO ==========
  Widget _buildUploadedFileInfo(String fileName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16A34A).withValues(alpha: 0.05),
            const Color(0xFF16A34A).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Belge Başarıyla Yüklendi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  style: const TextStyle(fontSize: 11, color: textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Color(0xFF16A34A), size: 20),
          ),
        ],
      ),
    );
  }

  // ========== COMPLETION INFO BOX  ==========
  Widget _buildCompletionInfoBox() {
    final isSuccess = _internshipResult == 'success';
    final isFail = _internshipResult == 'fail';
    // Result null ise nötr (sadece bilgilendirme)
    final hasResult = isSuccess || isFail;
    final color = isSuccess
        ? const Color(0xFF16A34A)
        : isFail
            ? const Color(0xFFDC2626)
            : purpleGlow;
    final label = isSuccess ? 'BAŞARILI' : isFail ? 'BAŞARISIZ' : 'SONUÇLANDI';
    final icon = isSuccess
        ? Icons.emoji_events
        : isFail
            ? Icons.info_outline
            : Icons.emoji_events;

    String completedDateText = '-';
    if (_completedAt != null) {
      final d = _completedAt!;
      completedDateText =
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.06),
            purpleGlow.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)]),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasResult)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    const Text(
                      'Stajınız Sonuçlandırıldı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.event_available, size: 12, color: textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          'Tamamlandı: $completedDateText',
                          style: const TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEF2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: purpleGlow),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Akademisyen değerlendirme detayları için "Sonuçlarım" sekmesini ziyaret edebilirsiniz.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== STEP DATA MODEL ==========
class _StepData {
  final int stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final StepStatus status;

  _StepData(this.stepNumber, this.title, this.subtitle, this.icon, this.status);
}


