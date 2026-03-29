// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tts/widgets/audio_controls_widget.dart';
import 'dart:typed_data';
import '../config/api_config.dart';
import '../models/voice_info.dart';
import '../models/tts_request.dart';
import '../services/tts_api_service.dart';
import '../services/audio_player_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Services
  final TtsApiService _apiService = TtsApiService();
  final AudioPlayerService _audioService = AudioPlayerService();

  // Controllers
  final TextEditingController _textController = TextEditingController();

  // State variables
  List<VoiceInfo> _voices = [];
  String? _selectedVoiceId;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _hasAudio = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);

    try {
      // Kiểm tra kết nối
      final isHealthy = await _apiService.checkHealth();
      if (!isHealthy) {
        throw Exception('Server không hoạt động hoặc model chưa load');
      }

      // Load danh sách voices
      final voices = await _apiService.getVoices();
      setState(() {
        _voices = voices;
        _selectedVoiceId = voices.isNotEmpty ? voices.first.id : null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
      });
      _showError('Không thể kết nối server. Kiểm tra:\n'
          '1. Backend có chạy không?\n'
          '2. IP trong api_config.dart đúng chưa?\n'
          '3. Cùng mạng WiFi chưa?');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSpeech() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      _showError('Vui lòng nhập văn bản');
      return;
    }

    if (text.length > ApiConfig.maxTextLength) {
      _showError('Văn bản quá dài (tối đa ${ApiConfig.maxTextLength} ký tự)');
      return;
    }

    if (_selectedVoiceId == null) {
      _showError('Vui lòng chọn giọng nói');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _hasAudio = false;
    });

    try {
      // Gọi API generate
      final request = TtsRequest(
        text: text,
        voiceId: _selectedVoiceId!,
        language: 'vi',
      );

      final audioBytes = await _apiService.generateSpeech(request);

      // Load vào audio player
      await _audioService.loadAudio(audioBytes);

      setState(() {
        _hasAudio = true;
      });

      _showSuccess('Tạo giọng nói thành công! Nhấn Play để nghe.');
    } catch (e) {
      _showError('Lỗi tạo giọng nói: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _resetAndReload() async {
    // 1. Dừng audio nếu đang phát
    await _audioService.stop();

    // 2. Xóa nội dung trong ô nhập liệu
    _textController.clear();

    // 3. Reset các biến trạng thái về mặc định
    setState(() {
      _voices = [];
      _selectedVoiceId = null;
      _hasAudio = false;
      _isGenerating = false;
      _errorMessage = null;
      // Set loading = true để giao diện chuyển sang màn hình chờ ngay lập tức
      _isLoading = true;
    });

    // 4. Gọi lại hàm khởi tạo để load lại danh sách giọng nói và kiểm tra server
    await _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vietnamese TTS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAndReload,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _errorMessage != null
          ? _buildErrorScreen()
          : _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitFadingCircle(color: Colors.blue, size: 50),
          SizedBox(height: 20),
          Text('Đang kết nối server...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeApp,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text input
          _buildTextInput(),
          const SizedBox(height: 20),

          // Voice selector
          _buildVoiceSelector(),
          const SizedBox(height: 20),

          // Generate button
          _buildGenerateButton(),
          const SizedBox(height: 30),

          // Audio controls
          if (_hasAudio) _buildAudioControls(),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập văn bản',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              maxLines: 6,
              maxLength: ApiConfig.maxTextLength,
              decoration: const InputDecoration(
                hintText: 'Nhập văn bản tiếng Việt cần chuyển thành giọng nói...',
                border: OutlineInputBorder(),
                counterText: '', // Hide default counter
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${_textController.text.length}/${ApiConfig.maxTextLength} ký tự',
              style: TextStyle(
                fontSize: 12,
                color: _textController.text.length > ApiConfig.maxTextLength
                    ? Colors.red
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn giọng nói',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedVoiceId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _voices.map((voice) {
                return DropdownMenuItem(
                  value: voice.id,
                  child: Text(voice.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedVoiceId = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate = _textController.text.trim().isNotEmpty &&
        _selectedVoiceId != null &&
        !_isGenerating;

    return ElevatedButton(
      onPressed: canGenerate ? _generateSpeech : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
        disabledBackgroundColor: Colors.grey,
      ),
      child: _isGenerating
          ? const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text('Đang tạo giọng nói...', style: TextStyle(color: Colors.white)),
        ],
      )
          : const Text(
        'Tạo Giọng Nói',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildAudioControls() {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '🎵 Audio Player',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            StreamBuilder<Duration?>(
              stream: _audioService.positionStream,
              builder: (context, positionSnapshot) {
                return StreamBuilder<Duration?>(
                  stream: _audioService.durationStream,
                  builder: (context, durationSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final duration = durationSnapshot.data ?? Duration.zero;

                    return Column(
                      children: [


                        Slider(
                          value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                          max: duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                          onChanged: (value) {
                            _audioService.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position)),
                              Text(_formatDuration(duration)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            StreamBuilder<PlayerState>(
              stream: _audioService.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      iconSize: 40,
                      onPressed: _audioService.stop,
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      iconSize: 60,
                      color: Colors.blue,
                      onPressed: _audioService.togglePlayPause,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioService.dispose();
    _apiService.dispose();
    super.dispose();
  }
}