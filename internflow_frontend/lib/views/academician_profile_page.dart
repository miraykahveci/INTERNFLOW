import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'academician_profile_page_mobile.dart';
import 'academician_profile_page_web.dart';

class AcademicianProfilePage extends StatelessWidget {
  const AcademicianProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScaffold: AcademicianProfileMobile(),
      webScaffold: AcademicianProfileWeb(),
    );
  }
}