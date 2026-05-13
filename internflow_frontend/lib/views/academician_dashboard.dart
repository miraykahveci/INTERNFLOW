import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'academician_dashboard_mobile.dart';
import 'academician_dashboard_page_web.dart';

class AcademicianDashboardPage extends StatelessWidget {
  const AcademicianDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScaffold: AcademicianDashboardMobile(),
      webScaffold: AcademicianDashboardWeb(),
    );
  }
}