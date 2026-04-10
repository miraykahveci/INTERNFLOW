import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'academician_student_detail_page.dart';

class AcademicianStudentsPage extends StatefulWidget {
  const AcademicianStudentsPage({super.key});

  @override
  State<AcademicianStudentsPage> createState() =>
      _AcademicianStudentsPageState();
}

class _AcademicianStudentsPageState extends State<AcademicianStudentsPage> {
  final Color primaryColor = const Color(0xFF6A0F0F);

  bool _isLoading = true;
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  String _activeFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();


  int _pendingCount = 0;
  int _activeCount = 0;
  int _notebookCount = 0;
  int _completedCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
  setState(() => _isLoading = true);
  try {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final response = await Supabase.instance.client
        .from('internship')
        .select(
            '*, users!internship_student_id_fkey(full_name, student_number, department)')
        .eq('academician_id', userId)
        .order('created_at', ascending: false);

    final allInternships = List<Map<String, dynamic>>.from(response);

  
    final Map<String, Map<String, dynamic>> uniqueStudents = {};
    for (var intern in allInternships) {
      final studentId = intern['student_id'] as String;
      
      if (!uniqueStudents.containsKey(studentId)) {
        uniqueStudents[studentId] = intern;
      }
    }

    final students = uniqueStudents.values.toList();

    
    int pending = 0, approved = 0, active = 0, completed = 0, rejected = 0;
    for (var s in students) {
      switch (s['status']) {
        case 'pending':
          pending++;
          break;
        case 'approved':
          approved++;
          break;
        case 'active':
          active++;
          break;
        case 'completed':
          completed++;
          break;
        case 'rejected':
          rejected++;
          break;
      }
    }

    setState(() {
      _allStudents = students;
      _pendingCount = pending;
      _approvedCount = approved;
      _activeCount = active;
      _completedCount = completed;
      _rejectedCount = rejected;
      _isLoading = false;
    });

    _applyFilters();
  } catch (e) {
    debugPrint('Öğrenci listesi yüklenemedi: $e');
    setState(() => _isLoading = false);
  }
}

  void _applyFilters() {
    List<Map<String, dynamic>> result = _allStudents;

    
    if (_activeFilter == 'pending') {
  result = result.where((s) => s['status'] == 'pending').toList();
} else if (_activeFilter == 'approved') {
  result = result.where((s) => s['status'] == 'approved').toList();
} else if (_activeFilter == 'active') {
  result = result.where((s) => s['status'] == 'active').toList();
} else if (_activeFilter == 'rejected') {
  result = result.where((s) => s['status'] == 'rejected').toList();
} else if (_activeFilter == 'completed') {
  result = result.where((s) => s['status'] == 'completed').toList();
}

    
    if (_searchQuery.isNotEmpty) {
      result = result.where((s) {
        final name =
            (s['users']?['full_name'] ?? '').toString().toLowerCase();
        final number =
            (s['users']?['student_number'] ?? '').toString().toLowerCase();
        final company = (s['company_name'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            number.contains(query) ||
            company.contains(query);
      }).toList();
    }

    setState(() => _filteredStudents = result);
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'label': 'ONAY BEKLiYOR',
          'color': const Color(0xFFE65100),
          'bgColor': const Color(0xFFFFF3E0),
        };
      case 'approved':
        return {
          'label': 'ONAYLANDI',
          'color': const Color(0xFF2E7D32),
          'bgColor': const Color(0xFFE8F5E9),
        };
      case 'active':
        return {
          'label': 'STAJDA',
          'color': const Color(0xFF1565C0),
          'bgColor': const Color(0xFFE3F2FD),
        };
      case 'completed':
        return {
          'label': 'TAMAMLANDI',
          'color': const Color(0xFF6A1B9A),
          'bgColor': const Color(0xFFF3E5F5),
        };
      case 'rejected':
        return {
          'label': 'REDDEDiLDi',
          'color': const Color(0xFFC62828),
          'bgColor': const Color(0xFFFFEBEE),
        };
      default:
        return {
          'label': status.toUpperCase(),
          'color': const Color(0xFF546E7A),
          'bgColor': const Color(0xFFECEFF1),
        };
    }
  }

  
  double _getProgress(String status) {
    switch (status) {
      case 'pending':
        return 0.2;
      case 'approved':
        return 0.4;
      case 'active':
        return 0.7;
      case 'completed':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: const Color(0xFFF4F6F8), 
      body: Column(
        children: [
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Öğrencilerim',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Toplam: ${_allStudents.length} Kayıtlı Öğrenci',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'İsim, numara veya firma ara...',
                    hintStyle: const TextStyle(color: Color(0xFF95A5A6), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: primaryColor, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _applyFilters();
                            },
                            child: const Icon(Icons.close, color: Color(0xFF95A5A6), size: 20),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          
          Transform.translate(
            offset: const Offset(0, -8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip('Tümü (${_allStudents.length})', 'all'),
                  _buildFilterChip('Onay Bekleyen ($_pendingCount)', 'pending'),
                  _buildFilterChip('Onaylanan ($_approvedCount)', 'approved'),
                  _buildFilterChip('Stajda ($_activeCount)', 'active'),
                  _buildFilterChip('Tamamlanan ($_completedCount)', 'completed'),
                  _buildFilterChip('Reddedilen ($_rejectedCount)', 'rejected'),
                ],
              ),
            ),
          ),

          
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _loadStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            return _buildStudentCard(_filteredStudents[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ========== FİLTRE CHİP ==========
  Widget _buildFilterChip(String label, String filter) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _activeFilter = filter);
        _applyFilters();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? primaryColor : const Color(0xFFE9ECEF)),
          boxShadow: isActive
              ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF7F8C8D),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  
  // ========== ÖĞRENCİ KARTI ==========
  Widget _buildStudentCard(Map<String, dynamic> internship) {
    final student = internship['users'] as Map<String, dynamic>?;
    final studentName = student?['full_name'] ?? 'Bilinmeyen';
    final studentNumber = student?['student_number']?.toString() ?? '-';
    final department = student?['department'] ?? '-';
    final companyName = internship['company_name'] ?? '-';
    final status = internship['status'] as String? ?? 'pending';
    final statusInfo = _getStatusInfo(status);
    final progress = _getProgress(status);
    final startDate = internship['start_date'] ?? '';
    final endDate = internship['end_date'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F2F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AcademicianStudentDetailPage(internship: internship),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Center(
                        child: Text(
                          studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color(0xFF34495E),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$studentNumber | $department',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusInfo['label'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusInfo['color'],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          const Icon(Icons.business, size: 16, color: Color(0xFF95A5A6)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              companyName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF34495E),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Color(0xFFBDC3C7)),
                          const SizedBox(width: 6),
                          Text(
                            startDate.isNotEmpty ? startDate : '-',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Staj İlerlemesi',
                          style: TextStyle(fontSize: 11, color: Color(0xFF95A5A6), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '%${(progress * 100).toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusInfo['color'],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F2F6),
                        valueColor: AlwaysStoppedAnimation<Color>(statusInfo['color']),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                
                Row(
                  children: [
                    _buildActionButton(
                     icon: Icons.phone_outlined,
                     label: 'Ara',
                     color: const Color(0xFF7F8C8D),
                     onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                              content: Text('Telefon bilgisi final döneminde eklenecektir.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                           );
                        },
                      ),
                 const SizedBox(width: 20),
                  _buildActionButton(
                     icon: Icons.email_outlined,
                     label: 'E-posta',
                     color: const Color(0xFF7F8C8D),
                     onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                           content: Text('E-posta bilgisi final döneminde eklenecektir.'),
                           behavior: SnackBarBehavior.floating,
                         ),
                      );
                     },
                   ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'DETAY',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12, color: primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== AKSİYON BUTONU ==========
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ========== BOŞ DURUM ==========
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aramanızla eşleşen öğrenci bulunamadı.'
                : 'Bu kategoride henüz öğrenci kaydı yok.',
            style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}