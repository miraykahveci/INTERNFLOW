import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'student_results_page_mobile.dart';
import 'student_results_page_web.dart';

class StudentResultsPage extends StatelessWidget {
  const StudentResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScaffold: StudentResultsMobile(),
      webScaffold: StudentResultsWeb(),
    );
  }
}