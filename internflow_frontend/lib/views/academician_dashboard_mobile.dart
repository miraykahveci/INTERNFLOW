import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'academician_students_page.dart';
import 'academician_profile_page.dart';

class AcademicianDashboardMobile extends StatefulWidget {
  const AcademicianDashboardMobile({super.key});

  @override
  State<AcademicianDashboardMobile> createState() =>
      _AcademicianDashboardMobileState();
}

class _AcademicianDashboardMobileState extends State<AcademicianDashboardMobile> {
  final Color primaryColor = const Color(0xFF6A0F0F);

  String _fullName = '';
  String _title = '';
  bool _isLoading = true;

  int _pendingCount = 0;
  int _sgkPendingCount = 0;
  int _activeCount = 0;
  int _selectedIndex = 0;

  List<Map<String, dynamic>> _pendingItems = [];
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('full_name, title')
          .eq('user_id', userId)
          .single();

      final internships = await Supabase.instance.client
          .from('internship')
          .select('*, users!internship_student_id_fkey(full_name, student_number, department)')
          .eq('academician_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> allInternships =
          List<Map<String, dynamic>>.from(internships);

      int pending = 0;
      int sgkPending = 0;
      int active = 0;
      List<Map<String, dynamic>> items = [];

      for (var intern in allInternships) {
        final status = intern['status'] as String;

        if (status == 'pending') {
          pending++;
          items.add({'type': 'pending', 'data': intern});
        } else if (status == 'approved') {
          sgkPending++;
          items.add({'type': 'sgk', 'data': intern});
        } else if (status == 'active') {
          active++;
        }
      }

      setState(() {
        _fullName = userResponse['full_name'] ?? '';
        _title = userResponse['title'] ?? 'Akademisyen';
        _pendingCount = pending;
        _sgkPendingCount = sgkPending;
        _activeCount = active;
        _pendingItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri yüklenemedi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_activeFilter == 'all') return _pendingItems;
    return _pendingItems.where((item) => item['type'] == _activeFilter).toList();
  }

void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });
}

Widget _getSelectedPage() {
  switch (_selectedIndex) {
    case 0:
      return _buildHomeContent();
    case 1:
      return const AcademicianStudentsPage();
    case 2:
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Color(0xFFCCCCCC)),
            SizedBox(height: 16),
            Text('AI Analiz Laboratuvarı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF546E7A))),
            SizedBox(height: 8),
            Text('Bu modül final döneminde aktifleşecektir.',
                style: TextStyle(color: Color(0xFF90A4AE), fontSize: 13)),
          ],
        ),
      );
    case 3:
       return const AcademicianProfilePage();
    default:
      return _buildHomeContent();
  }
}

  Future<void> _updateInternshipStatus(String internId, String newStatus, {String? reason}) async {
    try {
      await Supabase.instance.client
          .from('internship')
          .update({'status': newStatus})
          .eq('intern_id', internId);

      final intern = _pendingItems.firstWhere(
        (item) => item['data']['intern_id'] == internId,
      );
      final studentId = intern['data']['student_id'];

      String message;
      String type;
      if (newStatus == 'approved') {
        message = 'Staj başvurunuz onaylandı! SGK belgelerinizi yükleyiniz.';
        type = 'success';
      } else {
        message = 'Staj başvurunuz reddedildi. ${reason ?? ''}';
        type = 'error';
      }

      await Supabase.instance.client.from('notifications').insert({
        'user_id': studentId,
        'type': type,
        'message': message,
        'is_read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'approved'
                ? 'Başvuru onaylandı ✅'
                : 'Başvuru reddedildi ❌'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }

      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showApprovalDialog(Map<String, dynamic> internData) {
    final studentName = internData['users']?['full_name'] ?? 'Öğrenci';
    final studentNumber = internData['users']?['student_number']?.toString() ?? '-';
    final studentDepartment = internData['users']?['department'] ?? '-';
    final companyName = internData['company_name'] ?? '-';
    final internId = internData['intern_id'];
    final rejectReasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Başvuru Değerlendirmesi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: primaryColor.withValues(alpha: 0.15),
                          child: Text(
                            studentName.isNotEmpty ? studentName[0] : '?',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'No: $studentNumber • $studentDepartment',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('Staj Türü',
                        internData['internship_type'] == 'summer' ? 'Yaz Stajı' : 'Dönem İçi'),
                    _buildDetailRow('Tarih',
                        '${internData['start_date']} - ${internData['end_date']}'),
                    const Divider(height: 16),
                    _buildDetailRow('Kurum Adı', companyName),
                    _buildDetailRow('Departman',
                        internData['company_sector'] ?? '-'),
                    _buildDetailRow('Adres',
                        internData['company_address'] ?? '-'),
                    _buildDetailRow('Kurum E-Posta',
                        internData['company_email'] ?? '-'),
                    const Divider(height: 16),
                    _buildDetailRow('Yetkili Mühendis',
                        internData['supervisor_name'] ?? '-'),
                    _buildDetailRow('SGK Durumu',
                        internData['has_sgk'] == true
                            ? 'Var (Müstehaklık mevcut)'
                            : 'Yok (Okul yapacak)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: rejectReasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Red Gerekçesi (opsiyonel)',
                  hintText: 'Sadece reddetme durumunda doldurunuz...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateInternshipStatus(
                            internId,
                            'rejected',
                            reason: rejectReasonController.text.trim(),
                          );
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          'Reddet',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateInternshipStatus(internId, 'approved');
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Onayla',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _getSelectedPage(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
             onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outlined),
                activeIcon: Icon(Icons.people),
                label: 'Öğrenciler',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome),
                label: 'AI Analiz',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
Widget _buildHomeContent() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                decoration: BoxDecoration(color: primaryColor),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Text(
                        _fullName.isNotEmpty ? _fullName[0] : '?',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fullName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(_title,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: primaryColor),
                              const SizedBox(width: 12),
                               Expanded(
                                child: TextField(
                                 onChanged: (value) {
      
                                  },
                                  
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Öğrenci Adı, No veya Bölüm Ara...',
                                    hintStyle: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildStatCard(
                            value: _pendingCount.toString(),
                            label: 'Bekleyen\nBaşvuru',
                            bgColor: const Color(0xFFFFF3E0),
                            textColor: const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            value: _sgkPendingCount.toString(),
                            label: 'SGK\nGirişi',
                            bgColor: const Color(0xFFF3E5F5),
                            textColor: const Color(0xFF7B1FA2),
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            value: _activeCount.toString(),
                            label: 'Aktif\nStajyer',
                            bgColor: const Color(0xFFE8F5E9),
                            textColor: const Color(0xFF2E7D32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        color: const Color(0xFFE8EAF6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: Colors.indigo[700], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('AI Analiz Raporu',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo[700],
                                            fontSize: 13)),
                                    Text('Analiz modülü hazırlanıyor...',
                                        style: TextStyle(
                                            color: Colors.indigo[400],
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  size: 14, color: Colors.indigo[400]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Tümü', 'all'),
                            _buildFilterChip('Başvurular ($_pendingCount)', 'pending'),
                            _buildFilterChip('SGK ($_sgkPendingCount)', 'sgk'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Bekleyen İşlemler',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F))),
                      const SizedBox(height: 12),
                      if (_filteredItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('Bekleyen işlem bulunmuyor',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 14)),
                            ],
                          ),
                        )
                      else
                        ..._filteredItems
                            .map((item) => _buildPendingItemCard(item)),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
  }


  Widget _buildStatCard({
    required String value,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF37474F) : const Color(0xFFECEFF1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF546E7A),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPendingItemCard(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>;
    final type = item['type'] as String;
    final studentName = data['users']?['full_name'] ?? 'Bilinmeyen';
    final companyName = data['company_name'] ?? '';
    final createdAt = data['created_at']?.toString().split('T')[0] ?? '';

    Color stripeColor;
    Color iconBgColor;
    Color iconColor;
    IconData icon;
    String subtitle;
    String statusLabel;
    Color statusBgColor;
    Color statusTextColor;
    String actionLabel;
    Color actionColor;
    Color actionBgColor;

    if (type == 'pending') {
      stripeColor = const Color(0xFFEF6C00);
      iconBgColor = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFEF6C00);
      icon = Icons.description;
      subtitle = 'Staj Yeri Kabul Formu';
      statusLabel = 'ONAY BEKLİYOR';
      statusBgColor = const Color(0xFFFFF3E0);
      statusTextColor = const Color(0xFFE65100);
      actionLabel = 'DEĞERLENDİR';
      actionColor = const Color(0xFFEF6C00);
      actionBgColor = const Color(0xFFFFF3E0);
    } else {
      stripeColor = const Color(0xFF7B1FA2);
      iconBgColor = const Color(0xFFF3E5F5);
      iconColor = const Color(0xFF7B1FA2);
      icon = Icons.shield;
      subtitle = 'SGK Belgesi Bekleniyor';
      statusLabel = 'BELGE EKSİK';
      statusBgColor = const Color(0xFFF3E5F5);
      statusTextColor = const Color(0xFF7B1FA2);
      actionLabel = 'HATIRLAT';
      actionColor = const Color(0xFF7B1FA2);
      actionBgColor = const Color(0xFFF3E5F5);
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(width: 5, height: 90, color: stripeColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          Text(
                            '$subtitle • $companyName',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                createdAt,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF546E7A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: statusTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (type == 'pending') {
                          _showApprovalDialog(data);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: actionBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          actionLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: actionColor,
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF37474F),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}