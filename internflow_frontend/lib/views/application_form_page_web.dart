import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationFormWeb extends StatefulWidget {
  const ApplicationFormWeb({super.key});

  @override
  State<ApplicationFormWeb> createState() => _ApplicationFormWebState();
}

class _ApplicationFormWebState extends State<ApplicationFormWeb> {
  // Premium color palette
  static const Color primaryColor = Color(0xFF6A0F0F);
  static const Color primaryDark = Color(0xFF4A0808);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color bgCanvas = Color(0xFFF8F7FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);

  final _companyNameController = TextEditingController();
  final _companySectorController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _supervisorNameController = TextEditingController();

  String _internshipType = 'summer';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasSgk = false;
  bool _isLoading = false;
  int _calculatedDays = 0;

  int _hoveredCard = -1;
  bool _hoveredSubmit = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companySectorController.dispose();
    _companyAddressController.dispose();
    _companyEmailController.dispose();
    _supervisorNameController.dispose();
    super.dispose();
  }

  int _calculateBusinessDays(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  void _updateCalculatedDays() {
    if (_startDate != null && _endDate != null) {
      setState(() {
        _calculatedDays = _calculateBusinessDays(_startDate!, _endDate!);
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
            _calculatedDays = 0;
          }
        } else {
          _endDate = picked;
        }
      });
      _updateCalculatedDays();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _submitApplication() async {
    if (_companyNameController.text.trim().isEmpty) {
      _showError('Kurum adı boş bırakılamaz.');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _showError('Başlangıç ve bitiş tarihlerini seçiniz.');
      return;
    }
    if (_startDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      _showError('Geçmişe dönük staj tarihi seçilemez.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showError('Bitiş tarihi başlangıçtan önce olamaz.');
      return;
    }
    if (_calculatedDays < 20) {
      _showError('Staj süresi en az 20 iş günü olmalıdır.');
      return;
    }
    if (_companyEmailController.text.trim().isNotEmpty &&
        !_companyEmailController.text.trim().contains('@')) {
      _showError('Geçerli bir kurum e-posta adresi giriniz.');
      return;
    }
    if (_supervisorNameController.text.trim().isEmpty) {
      _showError('Yetkili mühendis adı boş bırakılamaz.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('department')
          .eq('user_id', userId)
          .single();

      final academicianResponse = await Supabase.instance.client
          .from('users')
          .select('user_id')
          .eq('role', 'academician')
          .eq('department', userResponse['department'])
          .limit(1)
          .maybeSingle();

      await Supabase.instance.client.from('internship').insert({
        'student_id': userId,
        'academician_id': academicianResponse?['user_id'],
        'company_name': _companyNameController.text.trim(),
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'end_date': _endDate!.toIso8601String().split('T')[0],
        'status': 'pending',
        'internship_type': _internshipType,
        'company_sector': _companySectorController.text.trim(),
        'company_address': _companyAddressController.text.trim(),
        'company_email': _companyEmailController.text.trim(),
        'supervisor_name': _supervisorNameController.text.trim(),
        'has_sgk': _hasSgk,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başvurunuz başarıyla gönderildi! ✅'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _showError('Başvuru gönderilemedi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner
                      _buildInfoBanner(),
                      const SizedBox(height: 28),

                      // Section 1: Staj Türü ve Tarihleri
                      _buildSectionCard(
                        cardIndex: 0,
                        icon: Icons.calendar_month,
                        title: 'Staj Türü ve Tarihleri',
                        subtitle: 'Staj döneminizi ve sürenizi belirleyin',
                        accentColor: primaryColor,
                        child: _buildDatesSection(),
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Kurum Bilgileri
                      _buildSectionCard(
                        cardIndex: 1,
                        icon: Icons.business,
                        title: 'İş Yeri / Kurum Bilgileri',
                        subtitle: 'Staj yapacağınız kurumu tanımlayın',
                        accentColor: const Color(0xFF2563EB),
                        child: _buildCompanySection(),
                      ),
                      const SizedBox(height: 24),

                      // Section 3: Yetkili
                      _buildSectionCard(
                        cardIndex: 2,
                        icon: Icons.person,
                        title: 'Yetkili / Mühendis Bilgisi',
                        subtitle: 'Staj sorumlusu mühendisin bilgileri',
                        accentColor: purpleGlow,
                        child: _buildSupervisorSection(),
                      ),
                      const SizedBox(height: 24),

                      // Section 4: SGK
                      _buildSectionCard(
                        cardIndex: 3,
                        icon: Icons.security,
                        title: 'Sosyal Güvence (SGK)',
                        subtitle: 'Sigorta durumunuzu belirtin',
                        accentColor: const Color(0xFF16A34A),
                        child: _buildSgkSection(),
                      ),
                      const SizedBox(height: 32),

                      // Submit button + info
                      _buildSubmitSection(),
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
                  colors: [
                    purpleGlow.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
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
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Row(
                children: [
                  // Back button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
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
                              Icon(Icons.edit_note, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'YENİ BAŞVURU',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Staj Başvuru Formu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aşağıdaki bilgileri eksiksiz doldurarak başvurunuzu danışman onayına gönderin.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15,
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
                colors: [const Color(0xFF2563EB).withValues(alpha: 0.2), const Color(0xFF2563EB).withValues(alpha: 0.1)],
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
                  'Başvuru hakkında bilmen gerekenler',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Form gönderildikten sonra düzenleme yapamazsınız. Bilgilerin doğruluğunu kontrol edin.',
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECTION CARD WITH HOVER ==========
  Widget _buildSectionCard({
    required int cardIndex,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Widget child,
  }) {
    final isHovered = _hoveredCard == cardIndex;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCard = cardIndex),
      onExit: (_) => setState(() => _hoveredCard = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
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
                  : accentColor.withValues(alpha: 0.05),
              blurRadius: isHovered ? 28 : 20,
              offset: Offset(0, isHovered ? 12 : 8),
            ),
            BoxShadow(
              color: isHovered
                  ? primaryColor.withValues(alpha: 0.08)
                  : purpleGlow.withValues(alpha: 0.03),
              blurRadius: isHovered ? 40 : 28,
              offset: Offset(0, isHovered ? 16 : 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  // ========== DATES SECTION ==========
  Widget _buildDatesSection() {
    return Column(
      children: [
        // Internship type
        Row(
          children: [
            Expanded(
              child: _buildRadioCard(
                isSelected: _internshipType == 'summer',
                icon: Icons.wb_sunny_outlined,
                label: 'Yaz Stajı',
                description: 'Yaz döneminde yapılan',
                onTap: () => setState(() => _internshipType = 'summer'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildRadioCard(
                isSelected: _internshipType == 'term',
                icon: Icons.school_outlined,
                label: 'Dönem İçi',
                description: 'Eğitim dönemi içinde',
                onTap: () => setState(() => _internshipType = 'term'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Date pickers
        Row(
          children: [
            Expanded(child: _buildDateField(label: 'Başlangıç Tarihi', value: _formatDate(_startDate), onTap: () => _pickDate(isStart: true))),
            const SizedBox(width: 14),
            Expanded(child: _buildDateField(label: 'Bitiş Tarihi', value: _formatDate(_endDate), onTap: () => _pickDate(isStart: false))),
          ],
        ),
        const SizedBox(height: 18),

        // Calculated days indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _calculatedDays >= 20
                  ? [const Color(0xFF16A34A).withValues(alpha: 0.08), const Color(0xFF16A34A).withValues(alpha: 0.03)]
                  : [const Color(0xFFEA580C).withValues(alpha: 0.08), const Color(0xFFEA580C).withValues(alpha: 0.03)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _calculatedDays >= 20
                  ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                  : const Color(0xFFEA580C).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: (_calculatedDays >= 20 ? const Color(0xFF16A34A) : const Color(0xFFEA580C)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _calculatedDays >= 20 ? Icons.check_circle : Icons.warning_amber,
                  color: _calculatedDays >= 20 ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hesaplanan Süre: $_calculatedDays İş Günü',
                      style: TextStyle(
                        color: _calculatedDays >= 20 ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _calculatedDays >= 20 ? 'Süre yeterli, belgeye işlenecek' : 'Minimum 20 iş günü gerekli',
                      style: TextStyle(
                        color: _calculatedDays >= 20 ? const Color(0xFF15803D) : const Color(0xFFC2410C),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== RADIO CARD ==========
  Widget _buildRadioCard({
    required bool isSelected,
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFEEEEF2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? Colors.white : textSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? primaryColor : textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== DATE FIELD ==========
  Widget _buildDateField({required String label, required String value, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: value.isEmpty ? const Color(0xFFEEEEF2) : primaryColor.withValues(alpha: 0.3),
              width: value.isEmpty ? 1 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: value.isEmpty ? const Color(0xFFF4F4F5) : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: value.isEmpty ? textSecondary : primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.isEmpty ? 'Tarih seçin' : value,
                      style: TextStyle(
                        color: value.isEmpty ? textSecondary : textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== COMPANY SECTION ==========
  Widget _buildCompanySection() {
    return Column(
      children: [
        _buildTextField(controller: _companyNameController, label: 'Kurum Adı / Unvanı', icon: Icons.business_outlined),
        const SizedBox(height: 14),
        _buildTextField(controller: _companySectorController, label: 'Üretim / Hizmet Alanı', hint: 'Örn: Yazılım, Savunma Sanayi', icon: Icons.category_outlined),
        const SizedBox(height: 14),
        _buildTextField(controller: _companyAddressController, label: 'Açık Adres', maxLines: 2, icon: Icons.location_on_outlined),
        const SizedBox(height: 14),
        _buildTextField(controller: _companyEmailController, label: 'Kurum E-Posta', keyboardType: TextInputType.emailAddress, icon: Icons.email_outlined),
      ],
    );
  }

  // ========== SUPERVISOR SECTION ==========
  Widget _buildSupervisorSection() {
    return Column(
      children: [
        _buildTextField(controller: _supervisorNameController, label: 'Adı Soyadı', icon: Icons.person_outline),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Color(0xFFEA580C), size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Diploma No, Mezuniyet Tarihi, Oda Sicil No gibi teknik bilgiler PDF onaylandıktan sonra yetkili mühendis tarafından evrak üzerine elle doldurulacaktır.',
                  style: TextStyle(color: Color(0xFFC2410C), fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== SGK SECTION ==========
  Widget _buildSgkSection() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Ailenizden kaynaklı sağlık güvenceniz (SPAS Müstehaklık) var mı?',
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildRadioCard(
                isSelected: _hasSgk == true,
                icon: Icons.check_circle_outline,
                label: 'Evet, var',
                description: 'Müstehaklık belgesi ekte',
                onTap: () => setState(() => _hasSgk = true),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildRadioCard(
                isSelected: _hasSgk == false,
                icon: Icons.cancel_outlined,
                label: 'Hayır, yok',
                description: 'Okul tarafından yapılacak',
                onTap: () => setState(() => _hasSgk = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========== TEXT FIELD ==========
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: textSecondary, size: 19) : null,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEF2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEF2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  // ========== SUBMIT SECTION ==========
  Widget _buildSubmitSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
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
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Başvurunuz önce danışman onayına düşecektir. Onay sonrası belge yükleme adımına geçebilirsiniz.',
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          MouseRegion(
            onEnter: (_) => setState(() => _hoveredSubmit = true),
            onExit: (_) => setState(() => _hoveredSubmit = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              transform: Matrix4.translationValues(0, _hoveredSubmit ? -2 : 0, 0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitApplication,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                  label: Text(
                    _isLoading ? 'Gönderiliyor...' : 'Başvuruyu Tamamla ve Onaya Gönder',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: _hoveredSubmit ? 12 : 8,
                    shadowColor: primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}