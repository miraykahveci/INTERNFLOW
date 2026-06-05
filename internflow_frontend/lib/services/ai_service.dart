import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'package:flutter/foundation.dart';

class AiService {
  /// [documentId] 
  Future<Map<String, dynamic>?> startAnalysis(String documentId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.aiAnalyze(documentId)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[AiService] startAnalysis hatası: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[AiService] startAnalysis bağlantı hatası: $e');
      return null;
    }
  }

  
  /// [analysisId] 
  Future<Map<String, dynamic>?> getStatus(String analysisId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.aiStatus(analysisId)),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[AiService] getStatus hatası: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[AiService] getStatus bağlantı hatası: $e');
      return null;
    }
  }

  /// [documentId]
  Future<Map<String, dynamic>?> getResult(String documentId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.aiResult(documentId)),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 404) {
        return null;
      }
      debugPrint('[AiService] getResult hatası: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[AiService] getResult bağlantı hatası: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAllAnalyses() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.aiAnalyses),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[AiService] getAllAnalyses hatası: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[AiService] getAllAnalyses bağlantı hatası: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>?> getPendingDocuments(String academicianId) async {
    try {
      final url = '${ApiConfig.apiV1}/ai/analyses/pending?academician_id=$academicianId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[AiService] getPendingDocuments hatası: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[AiService] getPendingDocuments bağlantı hatası: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>?> getCompletedAnalyses(String academicianId) async {
    try {
      final url = '${ApiConfig.apiV1}/ai/analyses/completed?academician_id=$academicianId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[AiService] getCompletedAnalyses hatası: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[AiService] getCompletedAnalyses bağlantı hatası: $e');
      return null;
    }
  }
  }