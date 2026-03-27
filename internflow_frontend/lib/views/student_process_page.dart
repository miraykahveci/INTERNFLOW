import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. ENUM EN TEPEDE (CLASS'LARIN DIŞINDA) ✅
enum StepStatus { completed, current, locked }

class StudentProcessPage extends StatefulWidget {
  const StudentProcessPage({super.key});

  @override
  State<StudentProcessPage> createState() => _StudentProcessPageState();
}

class _StudentProcessPageState extends State<StudentProcessPage> {
  final Color primaryColor = const Color(0xFF6A0F0F);
  
  // 2. DEĞİŞKENLER CLASS'IN HEMEN İÇİNDE ✅
  bool _isLoading = true;
  String _internshipStatus = 'none'; // Kırmızı yanan değişkenimiz burada güvende!
  String _academicianName = 'Atanıyor...';
  String _applicationDate = '';
  int _progressPercentage = 0;

  @override
  void initState() {
    super.initState();
    _loadProcessData();
  }

  Future<void> _loadProcessData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Öğrencinin son başvurusunu ve akademisyen bilgilerini çek
      final response = await Supabase.instance.client
          .from('internship')
          .select('status, created_at, academician_id, users!internship_academician_id_fkey(full_name, title)')
          .eq('student_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final status = response['status'] as String;
        final academician = response['users'];
        final createdAt = DateTime.parse(response['created_at']);

        // İlerleme yüzdesini duruma göre belirle
        int progress = 0;
        if (status == 'pending') progress = 25;
        if (status == 'approved') progress = 50;
        if (status == 'active') progress = 75;
        if (status == 'completed') progress = 100;

        setState(() {
          _internshipStatus = status;
          _progressPercentage = progress;
          _applicationDate = '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';
          if (academician != null) {
            _academicianName = '${academician['title'] ?? ''} ${academician['full_name'] ?? ''}'.trim();
          }
        });
      }
    } catch (e) {
      debugPrint('Süreç verisi çekilemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                        // ÜST KARANLIK KART (Progress)
                        _buildProgressCard(),
                        const SizedBox(height: 32),

                        // TIMELINE (YOL HARİTASI)
                        _buildTimelineStep(
                          stepNumber: 1,
                          isFirst: true,
                          title: 'Başvuru Gönderildi',
                          subtitle: _applicationDate.isNotEmpty ? _applicationDate : 'Tarih Bekleniyor',
                          status: _internshipStatus != 'none' ? StepStatus.completed : StepStatus.locked,
                          icon: Icons.send,
                        ),
                        _buildTimelineStep(
                          stepNumber: 2,
                          title: 'Akademisyen Değerlendirmesi',
                          subtitle: 'Şu anki aşama',
                          status: _getStepStatus(2),
                          icon: Icons.person_search,
                          customContent: _getStepStatus(2) == StepStatus.current
                              ? _buildAcademicianInfoBox()
                              : null,
                        ),
                        _buildTimelineStep(
                          stepNumber: 3,
                          title: 'Islak İmzalı Belge Teslimi',
                          subtitle: '(Akademik onay sonrası aktifleşir)',
                          status: _getStepStatus(3),
                          icon: Icons.upload_file,
                        ),
                        _buildTimelineStep(
                          stepNumber: 4,
                          title: 'SGK / Sigorta Belgesi Yükle',
                          subtitle: '(Islak imzalı belge sonrası aktifleşir)',
                          status: _getStepStatus(4),
                          icon: Icons.security,
                        ),
                        _buildTimelineStep(
                          stepNumber: 5,
                          title: 'Staj Dönemi',
                          subtitle: 'SGK girişi sonrası başlar.',
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

  // --- MANTIKSAL YARDIMCILAR ---

  StepStatus _getStepStatus(int stepIndex) {
    if (_internshipStatus == 'none' || _internshipStatus == 'rejected') return StepStatus.locked;

    if (stepIndex == 2) {
      if (_internshipStatus == 'pending') return StepStatus.current;
      return StepStatus.completed;
    }
    if (stepIndex == 3 || stepIndex == 4) {
      if (_internshipStatus == 'pending') return StepStatus.locked;
      if (_internshipStatus == 'approved') return StepStatus.current;
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

  // --- WIDGET YAPICILAR ---

  Widget _buildProgressCard() {
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
                    _internshipStatus == 'pending'
                        ? 'Akademik Onay Süreci'
                        : _internshipStatus == 'approved'
                            ? 'Belge Teslim Süreci'
                            : _internshipStatus == 'active'
                                ? 'Staj Dönemi'
                                : 'Süreç Tamamlandı',
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
                  color: isFirst ? Colors.transparent : (status == StepStatus.completed ? lineColor : const Color(0xFFE0E0E0)),
                ),
                Container(
                  width: status == StepStatus.current ? 20 : 16,
                  height: status == StepStatus.current ? 20 : 16,
                  decoration: BoxDecoration(
                    color: status == StepStatus.completed ? dotColor : Colors.white,
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
                  boxShadow: status != StepStatus.locked && cardColor != Colors.transparent
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
                              color: status == StepStatus.locked ? const Color(0xFF616161) : textColor,
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
                        color: status == StepStatus.locked ? const Color(0xFF9E9E9E) : (status == StepStatus.current ? const Color(0xFFF57C00) : const Color(0xFF9E9E9E)),
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Ortalama inceleme süresi: 3-5 gün',
                      style: TextStyle(color: Color(0xFF757575), fontSize: 11),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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