
class TtsRequest {
  final String text;
  final String voiceId;
  final String language;

  TtsRequest({
    required this.text,
    required this.voiceId,
    this.language = 'vi',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'voice_id': voiceId,
      'language': language,
    };
  }

  @override
  String toString() => 'TtsRequest(text: ${text.substring(0, 20)}..., voice: $voiceId)';
}