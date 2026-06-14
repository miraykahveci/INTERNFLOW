import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend API yapılandırması
/// - Web (Chrome - Lokal):     http://localhost:8000
/// - Web (Production):          --dart-define=API_BASE_URL=https://internflow-backend-1p5z.onrender.com
/// - Android Emulator:          http://10.0.2.2:8000
/// - iOS Simulator:             http://localhost:8000
///
/// Production Build:
///   flutter build web --release \
///     --dart-define=API_BASE_URL=https://internflow-backend-1p5z.onrender.com
class ApiConfig {
  /// Compile-time environment variable
  /// Production build'de --dart-define ile override edilebilir
  static const String _productionUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    // Eğer build sırasında PRODUCTION URL belirtildiyse, onu kullan
    if (_productionUrl.isNotEmpty) {
      return _productionUrl;
    }

    // Web (Chrome) - lokal geliştirme
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

  /// Environment bilgisi (debug için)
  static bool get isProduction => _productionUrl.isNotEmpty;
}