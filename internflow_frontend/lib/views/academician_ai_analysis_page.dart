import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'academician_ai_analysis_page_mobile.dart';
import 'academician_ai_analysis_page_web.dart';



class AcademicianAiAnalysisPage extends StatelessWidget {
  const AcademicianAiAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileScaffold: AcademicianAiAnalysisMobile(),
      webScaffold: AcademicianAiAnalysisWeb(),
    );
  }
}