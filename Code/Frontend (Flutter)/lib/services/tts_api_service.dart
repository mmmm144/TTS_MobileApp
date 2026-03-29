// lib/services/tts_api_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:tts/widgets/audio_controls_widget.dart';
import '../config/api_config.dart';
import '../models/voice_info.dart';
import '../models/tts_request.dart';

class TtsApiService {
  final http.Client _client = http.Client();

  /// Kiểm tra server có hoạt động không
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(
        Uri.parse(ApiConfig.healthUrl),
      )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy' && data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }

  /// Lấy danh sách giọng nói có sẵn
  Future<List<VoiceInfo>> getVoices() async {
    try {
      final response = await _client
          .get(
        Uri.parse(ApiConfig.voicesUrl),
      )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => VoiceInfo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load voices: ${response.statusCode}');
      }
    } catch (e) {
      print('Get voices error: $e');
      throw Exception('Không thể tải danh sách giọng nói: $e');
    }
  }

  /// Generate speech từ text
  Future<Uint8List> generateSpeech(TtsRequest request) async {
    try {
      print('Generating speech for: ${request.text.substring(0, 30)}...');

      final response = await _client
          .post(
        Uri.parse(ApiConfig.ttsUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(request.toJson()),
      )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        print('✓ Received audio: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        final error = json.decode(response.body);
        throw Exception('Error ${response.statusCode}: ${error['detail']}');
      }
    } catch (e) {
      print('Generate speech error: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: Server mất quá nhiều thời gian xử lý');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Không thể kết nối đến server. Kiểm tra IP và WiFi.');
      }
      throw Exception('Lỗi tạo giọng nói: $e');
    }
  }

  /// Test connection với nhiều thông tin
  Future<Map<String, dynamic>> testConnection() async {
    final result = {
      'health': false,
      'voices_count': 0,
      'error': null,
    };

    try {
      // Test health
      result['health'] = await checkHealth();

      // Test get voices
      if (result['health'] == true) {
        final voices = await getVoices();
        result['voices_count'] = voices.length;
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  void dispose() {
    _client.close();
  }
}