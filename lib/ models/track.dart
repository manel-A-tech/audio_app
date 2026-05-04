

class Track {
  final String id;
  final String name;
  final String reciter;
  final String audioUrl;
  final int number;
  final String translation;

  Track({
    required this.id,
    required this.name,
    required this.reciter,
    required this.audioUrl,
    required this.number,
    required this.translation,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      reciter: json['reciter'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      number: json['number'] ?? 0,
      translation: json['translation'] ?? '',
    );
  }
}