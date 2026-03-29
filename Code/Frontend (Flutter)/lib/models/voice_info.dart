class VoiceInfo {
  final String id;
  final String name;
  final String filePath;

  VoiceInfo({
    required this.id,
    required this.name,
    required this.filePath,
  });

  factory VoiceInfo.fromJson(Map<String, dynamic> json) {
    return VoiceInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['file_path'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
    };
  }

  @override
  String toString() => 'VoiceInfo(id: $id, name: $name)';
}