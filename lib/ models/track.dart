class Track {
  final String id;
  final String name;
  final String reciter;
  final String audioUrl;
  final String translation;
  final int number;

  Track({
    required this.id,
    required this.name,
    required this.reciter,
    required this.audioUrl,
    this.translation = '',
    required this.number,
  });

  factory Track.fromSurahJson(Map<String, dynamic> json, String reciterName) {
    return Track(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown',
      reciter: reciterName,
      audioUrl: json['audio_url'] ?? '',
      translation: json['translation'] ?? '',
      number: json['id'] ?? 0,
    );
  }

  factory Track.fromReciterJson(Map<String, dynamic> json) {
    return Track(
      id: json['surah_id'].toString(),
      name: json['surah_name'] ?? 'Unknown',
      reciter: json['reciter_name'] ?? 'Unknown',
      audioUrl: json['file_url'] ?? '',
      translation: '',
      number: json['surah_id'] ?? 0,
    );
  }
}