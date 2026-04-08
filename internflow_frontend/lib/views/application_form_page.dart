import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationFormPage extends StatefulWidget {
  const ApplicationFormPage({super.key});

  @override
  State<ApplicationFormPage> createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  final Color primaryColor = const Color(0xFF6A0F0F);

  // Form Controllers
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

  @override
  void dispose() {
    _companyNameController.dispose();
    _companySectorController.dispose();
    _companyAddressController.dispose();
    _companyEmailController.dispose();
    _supervisorNameController.dispose();
    super.dispose();
  }

  // İş günü hesaplama (hafta sonları hariç)
  int _calculateBusinessDays(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
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
    if (_startDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
       _showError('Geçmişe dönük staj tarihi seçilemez.');
        return;
}
    if (_startDate == null || _endDate == null) {
      _showError('Başlangıç ve bitiş tarihlerini seçiniz.');
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            decoration: BoxDecoration(color: primaryColor),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Başvuru Formu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // FORM İÇERİĞİ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aşağıdaki bilgileri doldurarak staj başvurunuzu danışman onayına gönderebilirsiniz.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // ========== STAJ TÜRÜ VE TARİHLERİ ==========
                  _buildSectionCard(
                    icon: Icons.calendar_month,
                    title: 'Staj Türü ve Tarihleri',
                    children: [
                      // Radio Buttons
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Yaz Stajı', style: TextStyle(fontSize: 14)),
                              value: 'summer',
                              groupValue: _internshipType,
                              activeColor: primaryColor,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _internshipType = v!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Dönem İçi', style: TextStyle(fontSize: 14)),
                              value: 'term',
                              groupValue: _internshipType,
                              activeColor: primaryColor,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _internshipType = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tarih Seçiciler
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'Başlangıç Tarihi',
                              value: _formatDate(_startDate),
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateField(
                              label: 'Bitiş Tarihi',
                              value: _formatDate(_endDate),
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hesaplanan Süre
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _calculatedDays >= 20
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Hesaplanan Süre: $_calculatedDays İş Günü (Belgeye işlenecek)',
                          style: TextStyle(
                            color: _calculatedDays >= 20
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFF57C00),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ========== İŞ YERİ BİLGİLERİ ==========
                  _buildSectionCard(
                    icon: Icons.business,
                    title: 'İş Yeri / Kurum Bilgileri',
                    children: [
                      _buildTextField(
                        controller: _companyNameController,
                        label: 'Kurum Adı / Unvanı',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _companySectorController,
                        label: 'Üretim / Hizmet Alanı',
                        hint: 'Örn: Yazılım, Savunma Sanayi',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _companyAddressController,
                        label: 'Açık Adres',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _companyEmailController,
                        label: 'Kurum E-Posta',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ========== YETKİLİ BİLGİSİ ==========
                  _buildSectionCard(
                    icon: Icons.person,
                    title: 'Yetkili / Mühendis Bilgisi',
                    children: [
                      _buildTextField(
                        controller: _supervisorNameController,
                        label: 'Adı Soyadı',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '*Diploma No, Mezuniyet Tarihi, Oda Sicil No gibi teknik bilgiler; PDF onaylanıp indirildikten sonra ilgili mühendis tarafından evrak üzerine elle doldurulacaktır.',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ========== SGK ==========
                  _buildSectionCard(
                    icon: Icons.security,
                    title: 'Sosyal Güvence (SGK)',
                    children: [
                      const Text(
                        'Ailenizden kaynaklı sağlık güvenceniz (SPAS Müstehaklık) var mı?',
                        style: TextStyle(color: Color(0xFF616161), fontSize: 13),
                      ),
                      RadioListTile<bool>(
                        title: const Text('Evet, Var (Müstehaklık belgesi ekte)',
                            style: TextStyle(fontSize: 13)),
                        value: true,
                        groupValue: _hasSgk,
                        activeColor: primaryColor,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _hasSgk = v!),
                      ),
                      RadioListTile<bool>(
                        title: const Text('Hayır, Yok (Okul tarafından yapılacak)',
                            style: TextStyle(fontSize: 13)),
                        value: false,
                        groupValue: _hasSgk,
                        activeColor: primaryColor,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _hasSgk = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),

      // ALT BUTON
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Başvurunuz önce danışman onayına düşecektir.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitApplication,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(
                  _isLoading ? 'Gönderiliyor...' : 'Başvuruyu Tamamla ve Onaya Gönder',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== YARDIMCI WİDGET'LAR ==========

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              value.isEmpty ? label : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey[600] : Colors.black,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}