import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend API yapılandırması
/// - Web (Chrome): http://localhost:8000
/// - Android Emulator: http://10.0.2.2:8000 (özel IP, host makineye erişir)
/// - iOS Simulator: http://localhost:8000
/// - Production: Render URL'i
class ApiConfig {
  static String get baseUrl {
    // Production'da burası güncellenecek
    // return 'https://internflow-backend.onrender.com';
    
    // Web (Chrome)
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    
    // Mobile
    try {
      if (Platform.isAndroid) {
        // Android Emulator için özel IP
        return 'http://10.0.2.2:8000';
      } else if (Platform.isIOS) {
        return 'http://localhost:8000';
      }
    } catch (_) {
      // Fallback
    }
    
    return 'http://localhost:8000';
  }
  
  static String get apiV1 => '$baseUrl/api/v1';
  
  static String get yonergeInfo => '$apiV1/yonerge/info';
  static String get yonergeDownload => '$apiV1/yonerge/download';

 // ========== AI Analiz Endpoint'leri ==========
  static String aiAnalyze(String documentId) => '$apiV1/ai/analyze/$documentId';

  
  static String aiStatus(String analysisId) => '$apiV1/ai/analysis/$analysisId/status';

  static String aiResult(String documentId) => '$apiV1/ai/analysis/document/$documentId';

  static String get aiAnalyses => '$apiV1/ai/analyses';
}