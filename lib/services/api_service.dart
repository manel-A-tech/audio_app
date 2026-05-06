import 'package:audio_app/ models/track.dart';

class ApiService {
  // Verified working URLs tested directly on device
  static const Map<String, String> _serverPaths = {
    '1': 'https://server8.mp3quran.net/afs',
    '2': 'https://server11.mp3quran.net/sds',
    '3': 'https://server7.mp3quran.net/s_gmd',
  };

  static const List<Map<String, dynamic>> _allSurahs = [
    {'id': 1,   'name': 'Al-Fatiha',    'translation': 'The Opener'},
    {'id': 2,   'name': 'Al-Baqarah',   'translation': 'The Cow'},
    {'id': 3,   'name': 'Aal-E-Imran',  'translation': 'The Family of Imran'},
    {'id': 4,   'name': 'An-Nisa',      'translation': 'The Women'},
    {'id': 5,   'name': 'Al-Maidah',    'translation': 'The Table Spread'},
    {'id': 6,   'name': 'Al-Anam',      'translation': 'The Cattle'},
    {'id': 7,   'name': 'Al-Araf',      'translation': 'The Heights'},
    {'id': 8,   'name': 'Al-Anfal',     'translation': 'The Spoils of War'},
    {'id': 9,   'name': 'At-Tawbah',    'translation': 'The Repentance'},
    {'id': 10,  'name': 'Yunus',         'translation': 'Jonah'},
    {'id': 11,  'name': 'Hud',           'translation': 'Hud'},
    {'id': 12,  'name': 'Yusuf',         'translation': 'Joseph'},
    {'id': 13,  'name': 'Ar-Rad',        'translation': 'The Thunder'},
    {'id': 14,  'name': 'Ibrahim',       'translation': 'Abraham'},
    {'id': 15,  'name': 'Al-Hijr',       'translation': 'The Rocky Tract'},
    {'id': 16,  'name': 'An-Nahl',       'translation': 'The Bee'},
    {'id': 17,  'name': 'Al-Isra',       'translation': 'The Night Journey'},
    {'id': 18,  'name': 'Al-Kahf',       'translation': 'The Cave'},
    {'id': 19,  'name': 'Maryam',        'translation': 'Mary'},
    {'id': 20,  'name': 'Ta-Ha',         'translation': 'Ta-Ha'},
    {'id': 21,  'name': 'Al-Anbiya',     'translation': 'The Prophets'},
    {'id': 22,  'name': 'Al-Hajj',       'translation': 'The Pilgrimage'},
    {'id': 23,  'name': 'Al-Muminun',    'translation': 'The Believers'},
    {'id': 24,  'name': 'An-Nur',        'translation': 'The Light'},
    {'id': 25,  'name': 'Al-Furqan',     'translation': 'The Criterion'},
    {'id': 26,  'name': 'Ash-Shuara',    'translation': 'The Poets'},
    {'id': 27,  'name': 'An-Naml',       'translation': 'The Ant'},
    {'id': 28,  'name': 'Al-Qasas',      'translation': 'The Stories'},
    {'id': 29,  'name': 'Al-Ankabut',    'translation': 'The Spider'},
    {'id': 30,  'name': 'Ar-Rum',        'translation': 'The Romans'},
    {'id': 31,  'name': 'Luqman',        'translation': 'Luqman'},
    {'id': 32,  'name': 'As-Sajdah',     'translation': 'The Prostration'},
    {'id': 33,  'name': 'Al-Ahzab',      'translation': 'The Clans'},
    {'id': 34,  'name': 'Saba',          'translation': 'Sheba'},
    {'id': 35,  'name': 'Fatir',         'translation': 'Originator'},
    {'id': 36,  'name': 'Ya-Sin',        'translation': 'Ya Sin'},
    {'id': 37,  'name': 'As-Saffat',     'translation': 'Those Who Set The Ranks'},
    {'id': 38,  'name': 'Sad',           'translation': 'The Letter Sad'},
    {'id': 39,  'name': 'Az-Zumar',      'translation': 'The Troops'},
    {'id': 40,  'name': 'Ghafir',        'translation': 'The Forgiver'},
    {'id': 41,  'name': 'Fussilat',      'translation': 'Explained In Detail'},
    {'id': 42,  'name': 'Ash-Shura',     'translation': 'The Consultation'},
    {'id': 43,  'name': 'Az-Zukhruf',    'translation': 'The Ornaments of Gold'},
    {'id': 44,  'name': 'Ad-Dukhan',     'translation': 'The Smoke'},
    {'id': 45,  'name': 'Al-Jathiyah',   'translation': 'The Crouching'},
    {'id': 46,  'name': 'Al-Ahqaf',      'translation': 'The Wind-Curved Sandhills'},
    {'id': 47,  'name': 'Muhammad',      'translation': 'Muhammad'},
    {'id': 48,  'name': 'Al-Fath',       'translation': 'The Victory'},
    {'id': 49,  'name': 'Al-Hujurat',    'translation': 'The Rooms'},
    {'id': 50,  'name': 'Qaf',           'translation': 'The Letter Qaf'},
    {'id': 51,  'name': 'Adh-Dhariyat',  'translation': 'The Winnowing Winds'},
    {'id': 52,  'name': 'At-Tur',        'translation': 'The Mount'},
    {'id': 53,  'name': 'An-Najm',       'translation': 'The Star'},
    {'id': 54,  'name': 'Al-Qamar',      'translation': 'The Moon'},
    {'id': 55,  'name': 'Ar-Rahman',     'translation': 'The Beneficent'},
    {'id': 56,  'name': 'Al-Waqiah',     'translation': 'The Inevitable'},
    {'id': 57,  'name': 'Al-Hadid',      'translation': 'The Iron'},
    {'id': 58,  'name': 'Al-Mujadila',   'translation': 'The Pleading Woman'},
    {'id': 59,  'name': 'Al-Hashr',      'translation': 'The Exile'},
    {'id': 60,  'name': 'Al-Mumtahanah', 'translation': 'She That Is To Be Examined'},
    {'id': 61,  'name': 'As-Saf',        'translation': 'The Ranks'},
    {'id': 62,  'name': 'Al-Jumuah',     'translation': 'The Congregation'},
    {'id': 63,  'name': 'Al-Munafiqun',  'translation': 'The Hypocrates'},
    {'id': 64,  'name': 'At-Taghabun',   'translation': 'The Mutual Disillusion'},
    {'id': 65,  'name': 'At-Talaq',      'translation': 'The Divorce'},
    {'id': 66,  'name': 'At-Tahrim',     'translation': 'The Prohibition'},
    {'id': 67,  'name': 'Al-Mulk',       'translation': 'The Sovereignty'},
    {'id': 68,  'name': 'Al-Qalam',      'translation': 'The Pen'},
    {'id': 69,  'name': 'Al-Haqqah',     'translation': 'The Reality'},
    {'id': 70,  'name': 'Al-Maarij',     'translation': 'The Ascending Stairways'},
    {'id': 71,  'name': 'Nuh',           'translation': 'Noah'},
    {'id': 72,  'name': 'Al-Jinn',       'translation': 'The Jinn'},
    {'id': 73,  'name': 'Al-Muzzammil',  'translation': 'The Enshrouded One'},
    {'id': 74,  'name': 'Al-Muddaththir','translation': 'The Cloaked One'},
    {'id': 75,  'name': 'Al-Qiyamah',    'translation': 'The Resurrection'},
    {'id': 76,  'name': 'Al-Insan',      'translation': 'The Man'},
    {'id': 77,  'name': 'Al-Mursalat',   'translation': 'The Emissaries'},
    {'id': 78,  'name': 'An-Naba',       'translation': 'The Tidings'},
    {'id': 79,  'name': 'An-Naziat',     'translation': 'Those Who Drag Forth'},
    {'id': 80,  'name': 'Abasa',         'translation': 'He Frowned'},
    {'id': 81,  'name': 'At-Takwir',     'translation': 'The Overthrowing'},
    {'id': 82,  'name': 'Al-Infitar',    'translation': 'The Cleaving'},
    {'id': 83,  'name': 'Al-Mutaffifin', 'translation': 'The Defrauding'},
    {'id': 84,  'name': 'Al-Inshiqaq',   'translation': 'The Splitting Open'},
    {'id': 85,  'name': 'Al-Buruj',      'translation': 'The Mansions of the Stars'},
    {'id': 86,  'name': 'At-Tariq',      'translation': 'The Morning Star'},
    {'id': 87,  'name': 'Al-Ala',        'translation': 'The Most High'},
    {'id': 88,  'name': 'Al-Ghashiyah',  'translation': 'The Overwhelming'},
    {'id': 89,  'name': 'Al-Fajr',       'translation': 'The Dawn'},
    {'id': 90,  'name': 'Al-Balad',      'translation': 'The City'},
    {'id': 91,  'name': 'Ash-Shams',     'translation': 'The Sun'},
    {'id': 92,  'name': 'Al-Layl',       'translation': 'The Night'},
    {'id': 93,  'name': 'Ad-Duhaa',      'translation': 'The Morning Hours'},
    {'id': 94,  'name': 'Ash-Sharh',     'translation': 'The Relief'},
    {'id': 95,  'name': 'At-Tin',        'translation': 'The Fig'},
    {'id': 96,  'name': 'Al-Alaq',       'translation': 'The Clot'},
    {'id': 97,  'name': 'Al-Qadr',       'translation': 'The Power'},
    {'id': 98,  'name': 'Al-Bayyinah',   'translation': 'The Clear Proof'},
    {'id': 99,  'name': 'Az-Zalzalah',   'translation': 'The Earthquake'},
    {'id': 100, 'name': 'Al-Adiyat',     'translation': 'The Courser'},
    {'id': 101, 'name': 'Al-Qariah',     'translation': 'The Calamity'},
    {'id': 102, 'name': 'At-Takathur',   'translation': 'The Rivalry in World Increase'},
    {'id': 103, 'name': 'Al-Asr',        'translation': 'The Declining Day'},
    {'id': 104, 'name': 'Al-Humazah',    'translation': 'The Traducer'},
    {'id': 105, 'name': 'Al-Fil',        'translation': 'The Elephant'},
    {'id': 106, 'name': 'Quraysh',       'translation': 'Quraysh'},
    {'id': 107, 'name': 'Al-Maun',       'translation': 'The Small Kindnesses'},
    {'id': 108, 'name': 'Al-Kawthar',    'translation': 'The Abundance'},
    {'id': 109, 'name': 'Al-Kafirun',    'translation': 'The Disbelievers'},
    {'id': 110, 'name': 'An-Nasr',       'translation': 'The Divine Support'},
    {'id': 111, 'name': 'Al-Masad',      'translation': 'The Palm Fibre'},
    {'id': 112, 'name': 'Al-Ikhlas',     'translation': 'The Sincerity'},
    {'id': 113, 'name': 'Al-Falaq',      'translation': 'The Daybreak'},
    {'id': 114, 'name': 'An-Nas',        'translation': 'Mankind'},
  ];

  static const List<Map<String, dynamic>> _reciters = [
    {'id': '1', 'name': 'Mishary Rashid Alafasy'},
    {'id': '2', 'name': 'Abdul Rahman Al-Sudais'},
    {'id': '3', 'name': 'Saad Al-Ghamdi'},
  ];
/*
  static const Map<String, String> _serverPaths = {
    // FULL + VERIFIED folders
    '1': 'https://server8.mp3quran.net/afs/001',  // Mishary FULL
    '2': 'https://server11.mp3quran.net/sds/001', // Sudais FULL
    '3': 'https://server7.mp3quran.net/s_gmd/001', // Ghamdi FULL
  };*/

  Future<List<Map<String, dynamic>>> getSurahs() async => _allSurahs;

  Future<List<Map<String, dynamic>>> getReciters() async => _reciters;

  /// Returns verified working MP3 URL for the given surah and reciter.
  /// Format: https://{server}/{folder}/{surahNumber zero-padded to 3}.mp3
  String getAudioUrl(int surahNumber, String reciterId) {
    final server = _serverPaths[reciterId] ?? _serverPaths['1']!;
    final padded = surahNumber.toString().padLeft(3, '0');
    return '$server/$padded.mp3';
    //return '$server/001$padded.mp3';
  }

  Future<List<Track>> getTracksByReciter(
      String reciterId, String reciterName) async {
    return _allSurahs.map((surah) {
      final id = surah['id'] as int;
      return Track(
        id: id.toString(),
        name: surah['name'] as String,
        reciter: reciterName,
        audioUrl: getAudioUrl(id, reciterId),
        translation: surah['translation'] as String,
        number: id,
      );
    }).toList();
  }
}