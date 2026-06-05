import 'package:flutter/material.dart';
import '../core/responsive_layout.dart';
import 'ai_analysis_detail_page_mobile.dart';
import 'ai_analysis_detail_page_web.dart';


class AiAnalysisDetailPage extends StatelessWidget {
  final String documentId;
  final String studentName;

  const AiAnalysisDetailPage({
    super.key,
    required this.documentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: AiAnalysisDetailMobile(
        documentId: documentId,
        studentName: studentName,
      ),
      webScaffold: AiAnalysisDetailWeb(
        documentId: documentId,
        studentName: studentName,
      ),
    );
  }
}