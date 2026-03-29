// lib/config/api_config.dart

class ApiConfig {
  // ⚠️ QUAN TRỌNG: Thay YOUR_LAPTOP_IP bằng IP thật của laptop
  // Ví dụ: static const String baseUrl = 'http://192.168.1.100:8000';
  static const String baseUrl = 'https://cranelike-jesica-impeccant.ngrok-free.dev';
  // API Endpoints
  static const String healthEndpoint = '/health';
  static const String voicesEndpoint = '/api/voices';
  static const String ttsEndpoint = '/api/tts';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 120); // TTS có thể chậm

  // Text limits
  static const int maxTextLength = 500;

  // Full URLs
  static String get healthUrl => '$baseUrl$healthEndpoint';
  static String get voicesUrl => '$baseUrl$voicesEndpoint';
  static String get ttsUrl => '$baseUrl$ttsEndpoint';
}