import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'academician_student_detail_page_mobile.dart';
import 'academician_student_detail_page_web.dart';

class AcademicianStudentDetailPage extends StatelessWidget {
  final Map<String, dynamic> internship;

  const AcademicianStudentDetailPage({super.key, required this.internship});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: AcademicianStudentDetailMobile(internship: internship),
      webScaffold: AcademicianStudentDetailWeb(internship: internship),
    );
  }
}