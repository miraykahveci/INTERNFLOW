import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'academician_students_page_mobile.dart';
import 'academician_students_page_web.dart';

class AcademicianStudentsPage extends StatelessWidget {
  const AcademicianStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScaffold: AcademicianStudentsPageMobile(),
      webScaffold: AcademicianStudentsWeb(),
    );
  }
}