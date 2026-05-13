import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'student_process_page_mobile.dart';
import 'student_process_page_web.dart';

class StudentProcessPage extends StatelessWidget {
  const StudentProcessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScaffold: StudentProcessPageMobile(),
      webScaffold: StudentProcessWeb(),
    );
  }
}