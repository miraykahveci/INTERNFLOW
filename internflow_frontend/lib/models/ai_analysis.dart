class AiAnalysis {
  final String analysisId;
  final String? documentId;
  final String status;          
  final int progress;           
  final String? currentStep;    
  final String? errorMessage;

  
  final String? riskLevel;          
  final double? plagiarismScore;   
  final bool isRisky;
  final String? aiSummary;
  final String? plagiarismExplanation;
  final String? similarDocumentId;
  final String? maskedText;
  final String? completedAt;

  final String? similarStudentName;
  final String? similarStudentNumber;
  final String? similarCompanyName;

  AiAnalysis({
    required this.analysisId,
    this.documentId,
    required this.status,
    required this.progress,
    this.currentStep,
    this.errorMessage,
    this.riskLevel,
    this.plagiarismScore,
    this.isRisky = false,
    this.aiSummary,
    this.plagiarismExplanation,
    this.similarDocumentId,
    this.maskedText,
    this.completedAt,
    this.similarStudentName,
    this.similarStudentNumber,
    this.similarCompanyName,
  });

 
  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      analysisId: json['analysis_id']?.toString() ?? '',
      documentId: json['document_id']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      currentStep: json['current_step']?.toString(),
      errorMessage: json['error_message']?.toString(),
      riskLevel: json['risk_level']?.toString(),
      plagiarismScore: (json['plagiarism_score'] as num?)?.toDouble(),
      isRisky: json['is_risky'] == true,
      aiSummary: json['ai_summary']?.toString(),
      plagiarismExplanation: json['plagiarism_explanation']?.toString(),
      similarDocumentId: json['similar_document_id']?.toString(),
      maskedText: json['masked_text']?.toString(),
      completedAt: json['completed_at']?.toString(),
      similarStudentName: json['similar_student_name']?.toString(),
      similarStudentNumber: json['similar_student_number']?.toString(),
      similarCompanyName: json['similar_company_name']?.toString(),
    );
  }

 

  bool get isCompleted => status == 'completed';

  bool get isProcessing => status == 'processing';

  bool get isFailed => status == 'failed';

  String get scorePercent {
    if (plagiarismScore == null) return '0';
    return (plagiarismScore! * 100).toStringAsFixed(1);
  }

  String get riskLabel {
    switch (riskLevel) {
      case 'high':
        return 'Yüksek Risk';
      case 'medium':
        return 'Orta Risk';
      case 'low':
        return 'Düşük Risk';
      default:
        return 'Belirsiz';
    }
  }

 
  bool get hasSimilarMatch =>
      similarDocumentId != null && similarStudentName != null;
}