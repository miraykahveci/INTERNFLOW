import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      final students = List<Map<String, dynamic>>.from(response);

      
      int pending = 0, active = 0, notebook = 0, completed = 0;
      for (var s in students) {
        switch (s['status']) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            pending++;
            break;
          case 'active':
            active++;
            break;
          case 'completed':
            completed++;
            break;
        }
      }

      setState(() {
        _allStudents = students;
        _pendingCount = pending;
        _activeCount = active;
        _notebookCount = notebook;
        _completedCount = completed;
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
      result =
          result.where((s) => s['status'] == 'pending' || s['status'] == 'approved').toList();
    } else if (_activeFilter == 'active') {
      result = result.where((s) => s['status'] == 'active').toList();
    } else if (_activeFilter == 'notebook') {
      result = result
          .where((s) => s['status'] == 'completed' && s['notebook_submitted'] == true)
          .toList();
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: BoxDecoration(color: primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                const Row(
                  children: [
                    Icon(Icons.people, color: Colors.white, size: 26),
                    SizedBox(width: 12),
                    Text(
                      'Öğrencilerim',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Toplam: ${_allStudents.length} Kayıtlı Öğrenci',
                  style: const TextStyle(
                    color: Color(0xFFFFCDD2),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

        
          Transform.translate(
            offset: const Offset(0, -16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: primaryColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            _searchQuery = value;
                            _applyFilters();
                          },
                          decoration: const InputDecoration(
                            hintText: 'İsim, numara veya firma ara...',
                            hintStyle: TextStyle(
                              color: Color(0xFF90A4AE),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _applyFilters();
                          },
                          child: const Icon(Icons.close,
                              color: Color(0xFF90A4AE), size: 20),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // FİLTRE CHİP'LERİ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('Tümü (${_allStudents.length})', 'all'),
                _buildFilterChip(
                    'Onay Bekleyen ($_pendingCount)', 'pending'),
                _buildFilterChip('Stajda ($_activeCount)', 'active'),
                _buildFilterChip(
                    'Defter Teslimi ($_notebookCount)', 'notebook'),
                _buildFilterChip(
                    'Tamamlanan ($_completedCount)', 'completed'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ÖĞRENCİ LİSTESİ
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: primaryColor))
                : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _loadStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            return _buildStudentCard(
                                _filteredStudents[index]);
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : const Color(0xFFECEFF1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF546E7A),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ========== ÖĞRENCİ KARTI ==========
  Widget _buildStudentCard(Map<String, dynamic> internship) {
    final student = internship['users'] as Map<String, dynamic>?;
    final studentName = student?['full_name'] ?? 'Bilinmeyen';
    final studentNumber =
        student?['student_number']?.toString() ?? '-';
    final department = student?['department'] ?? '-';
    final companyName = internship['company_name'] ?? '-';
    final status = internship['status'] as String? ?? 'pending';
    final statusInfo = _getStatusInfo(status);
    final progress = _getProgress(status);
    final startDate = internship['start_date'] ?? '';
    final endDate = internship['end_date'] ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Öğrenci detay sayfasına yönlendir
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: primaryColor.withValues(alpha: 0.12),
                    child: Text(
                      studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF37474F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$studentNumber | $department',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF90A4AE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: Color(0xFF90A4AE)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF546E7A),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today,
                      size: 12, color: Color(0xFF90A4AE)),
                  const SizedBox(width: 4),
                  Text(
                    '$startDate - $endDate',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF90A4AE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Text(
                    'Staj İlerlemesi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF90A4AE),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '%${(progress * 100).toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusInfo['color'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFECEFF1),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(statusInfo['color']),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.phone,
                    label: 'Ara',
                    color: const Color(0xFF546E7A),
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.email,
                    label: 'E-posta',
                    color: const Color(0xFF546E7A),
                    onTap: () {},
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: Icons.arrow_forward,
                    label: 'DETAY',
                    color: primaryColor,
                    isBold: true,
                    onTap: () {
                      // TODO: Öğrenci detay sayfasına yönlendir
                    },
                  ),
                ],
              ),
            ],
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
    bool isBold = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aramanızla eşleşen öğrenci bulunamadı'
                : 'Bu kategoride öğrenci bulunmuyor',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}