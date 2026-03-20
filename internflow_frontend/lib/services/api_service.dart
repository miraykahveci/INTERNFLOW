import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ÖNEMLİ BİLGİ:
  // Eğer Mac'te iOS Simülatör kullanıyorsan burası: "http://127.0.0.1:8000" olmalı.
  // Eğer Android Emülatör kullanıyorsan burası: "http://10.0.2.2:8000" olmalı.
  final String baseUrl = "http://10.0.2.2:8000"; 

  Future<bool> login(String number, String pass) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "student_number": number,
          "password": pass
        }),
      );
      
      // Eğer backend "200 OK" (Başarılı) dönerse true, dönmezse false veriyoruz
      if (response.statusCode == 200) {
        return true; 
      }
      return false;
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return false;
    }
  }
}