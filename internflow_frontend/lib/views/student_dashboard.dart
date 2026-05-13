import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'student_dashboard_mobile.dart';
import 'student_dashboard_web.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScaffold: StudentDashboardMobile(),
      webScaffold: StudentDashboardWeb(),
    );
  }
}