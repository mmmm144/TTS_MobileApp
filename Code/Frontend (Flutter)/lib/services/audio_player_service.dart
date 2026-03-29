// lib/services/audio_player_service.dart

import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  // Stream để UI có thể lắng nghe
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  bool get isPlaying => _player.playing;
  Duration? get duration => _player.duration;
  Duration? get position => _player.position;

  /// Load audio từ bytes (từ API)
  Future<void> loadAudio(Uint8List audioBytes) async {
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.dataFromBytes(audioBytes, mimeType: 'audio/wav'),
        ),
      );
      print('✓ Audio loaded successfully');
    } catch (e) {
      print('Error loading audio: $e');
      throw Exception('Không thể load audio: $e');
    }
  }

  /// Phát audio
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      print('Error playing audio: $e');
      throw Exception('Không thể phát audio: $e');
    }
  }

  /// Tạm dừng
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  /// Dừng và reset
  Future<void> stop() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Seek đến vị trí cụ thể
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Cleanup
  Future<void> dispose() async {
    await _player.dispose();
  }
}