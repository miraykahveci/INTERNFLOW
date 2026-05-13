import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'student_files_page_mobile.dart';
import 'student_files_page_web.dart';

class StudentFilesPage extends StatelessWidget {
  const StudentFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScaffold: StudentFilesPageMobile(),
      webScaffold: StudentFilesWeb(),
    );
  }
}