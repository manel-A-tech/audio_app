
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'biometric_service.dart';
import 'package:audio_app/ models/track.dart';
import 'services/api_service.dart';

const _accent     = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);
const _bg         = Color(0xFFFAF9F7);
const _textMain   = Color(0xFF1A1A2E);
const _textSub    = Color(0xFF8A8A9A);
const _divider    = Color(0xFFEEECE8);
const _cardBg     = Colors.white;
const kRadius     = 16.0;

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final AudioPlayer _player = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BiometricService _biometricService = BiometricService();
  final ApiService _apiService = ApiService();

  List<Track> _tracks = [];
  Track? _currentTrack;
  bool _isPlaying = false;
  bool _isRepeat = false;
  Set<String> _favorites = {};
  bool _isLoading = true;
  String _selectedReciter = 'Mishary Rashid Alafasy';
  String _selectedReciterId = '1';
  List<Map<String, dynamic>> _reciters = [];
  DateTime? _playStartTime;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final reciters = await _apiService.getReciters();
    final tracks = await _apiService.getTracksByReciter(
        _selectedReciterId, _selectedReciter);
    await _loadFavorites();
    _setupPlayerListeners();
    if (mounted) {
      setState(() {
        _reciters = reciters;
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTracks() async {
    if (mounted) setState(() => _isLoading = true);
    final tracks = await _apiService.getTracksByReciter(
        _selectedReciterId, _selectedReciter);
    await _player.stop();
    if (_playStartTime != null) await _saveListeningTime();
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _currentTrack = null;
        _isLoading = false;
      });
    }
  }

  void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) async {
      if (mounted) setState(() => _isPlaying = state.playing);

      // FIX: Save when playback completes naturally - DON'T clear _playStartTime yet
      if (state.processingState == ProcessingState.completed) {
        print('Track completed naturally');
        // Save listening time BEFORE clearing _playStartTime
        await _saveListeningTime();
        // Clear after saving
        _playStartTime = null;
      }

      // Save when playback stops/pauses
      if (!state.playing && _playStartTime != null) {
        print('Track paused/stopped');
        await _saveListeningTime();
        _playStartTime = null;
      }
    });
  }

  Future<void> _loadFavorites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final snapshot = await _firestore
        .collection('users').doc(userId).collection('favorites').get();
    if (mounted) {
      setState(() {
        _favorites = snapshot.docs.map((d) => d.id).toSet();
      });
    }
  }

  // FIX: Don't clear _playStartTime until AFTER saving
  Future<void> _saveListeningTime() async {
    print('=== SAVE LISTENING TIME CALLED ===');
    print('Play start time: $_playStartTime');
    print('Current track: ${_currentTrack?.name}');

    if (_playStartTime == null || _currentTrack == null) {
      print('ERROR: playStartTime or currentTrack is null');
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('ERROR: No user logged in');
      return;
    }

    final elapsed = DateTime.now().difference(_playStartTime!);
    final minutes = elapsed.inSeconds / 60.0;
    print('Elapsed seconds: ${elapsed.inSeconds}');
    print('Minutes to save: $minutes');

    // IMPORTANT: Don't clear _playStartTime here - let the caller clear it
    // _playStartTime = null; // REMOVED - caller will clear it

    // Lower threshold to 0.01 minutes (0.6 seconds) for testing
    if (minutes < 0.01) {
      print('Minutes too small (<0.01), not saving');
      return;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    print('Saving for date: $today');

    final trackName = _currentTrack!.name;
    final userDoc = _firestore.collection('users').doc(userId);
    final statsRef = userDoc.collection('stats').doc(today);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(statsRef);
        if (snap.exists) {
          final currentMinutes = (snap.data()!['minutes'] as num).toDouble();
          final newMinutes = currentMinutes + minutes;
          print('Updating existing doc: $currentMinutes + $minutes = $newMinutes');
          tx.update(statsRef, {'minutes': newMinutes, 'date': today});
        } else {
          print('Creating new doc with $minutes minutes');
          tx.set(statsRef, {'minutes': minutes, 'date': today});
        }
      });
      print('Successfully saved to Firestore!');

      // Update topTracks
      final trackRef = userDoc.collection('topTracks').doc(trackName);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(trackRef);
        if (snap.exists) {
          final currentCount = (snap.data()!['count'] as num).toInt();
          tx.update(trackRef, {'count': currentCount + 1, 'name': trackName});
          print('Updated topTracks: $trackName count = ${currentCount + 1}');
        } else {
          tx.set(trackRef, {'name': trackName, 'count': 1});
          print('Created topTracks: $trackName with count 1');
        }
      });
    } catch (e) {
      print('ERROR saving to Firestore: $e');
    }
  }

  Future<void> _toggleFavorite(Track track) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final key = '${track.id}_$_selectedReciterId';
    if (_favorites.contains(key)) {
      final ok = await _biometricService.authenticateWithFingerprint(context);
      if (!ok) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Fingerprint required to remove favourites')));
        return;
      }
      await _firestore
          .collection('users').doc(userId).collection('favorites').doc(key).delete();
      if (mounted) {
        setState(() => _favorites.remove(key));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favourites')));
      }
    } else {
      await _firestore
          .collection('users').doc(userId).collection('favorites').doc(key)
          .set({
        'name': track.name,
        'reciter': track.reciter,
        'audioUrl': track.audioUrl,
        'number': track.number,
        'reciterId': _selectedReciterId,
      });
      if (mounted) {
        setState(() => _favorites.add(key));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favourites')));
      }
    }
  }

  void _playTrack(Track track) async {
    // Save any currently playing track before switching
    if (_playStartTime != null) {
      await _saveListeningTime();
      _playStartTime = null;
    }

    setState(() => _currentTrack = track);
    try {
      await _player.stop();
      await _player.setUrl(track.audioUrl);
      await _player.play();
      _playStartTime = DateTime.now();
      print('Started playing: ${track.name} at $_playStartTime');
    } catch (e) {
      debugPrint('Error playing: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing ${track.name}')));
    }
  }

  void _playPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      _playStartTime = DateTime.now();
      await _player.play();
    }
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeat = !_isRepeat;
      _player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    });
  }

  void _changeReciter() {
    if (_reciters.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius)),
        title: const Text('Select Reciter',
            style: TextStyle(fontWeight: FontWeight.w800, color: _textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reciters.map((reciter) {
            final isSelected = reciter['id'] == _selectedReciterId;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isSelected ? _accentMild : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                title: Text(reciter['name'],
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _accent : _textMain)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                    color: _accent, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (reciter['id'] != _selectedReciterId) {
                    setState(() {
                      _selectedReciter = reciter['name'];
                      _selectedReciterId = reciter['id'].toString();
                    });
                    _loadTracks();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_playStartTime != null) {
      _saveListeningTime();
      _playStartTime = null;
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    // PlayerPage is embedded in HomePage's tab — NO Scaffold, NO bottom nav
    return Column(
      children: [
        // ── Reciter selector ──────────────────────────────────────────────────
        Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    color: _accentMild,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.record_voice_over_rounded,
                    color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_selectedReciter,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textMain)),
              ),
              GestureDetector(
                onTap: _changeReciter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _accentMild,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.swap_horiz_rounded,
                          size: 14, color: _accent),
                      SizedBox(width: 4),
                      Text('Change',
                          style: TextStyle(
                              fontSize: 12,
                              color: _accent,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Now playing card ──────────────────────────────────────────────────
        if (_currentTrack != null)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(kRadius),
              boxShadow: [
                BoxShadow(
                    color: _accent.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Text(
                  '${_currentTrack!.number}. ${_currentTrack!.name}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3),
                  textAlign: TextAlign.center,
                ),
                if (_currentTrack!.translation.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_currentTrack!.translation,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white60)),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                          _isRepeat
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          size: 22),
                      color: _isRepeat ? Colors.white : Colors.white38,
                      onPressed: _toggleRepeat,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _playPause,
                      child: Container(
                        width: 52, height: 52,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: _accent, size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _favorites.contains(
                            '${_currentTrack!.id}_$_selectedReciterId')
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 22,
                      ),
                      color: _favorites.contains(
                          '${_currentTrack!.id}_$_selectedReciterId')
                          ? Colors.pink[200]
                          : Colors.white38,
                      onPressed: () => _toggleFavorite(_currentTrack!),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // ── Surah list ────────────────────────────────────────────────────────
        Expanded(
          child: _tracks.isEmpty
              ? const Center(child: Text('No tracks available'))
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: _tracks.length,
            itemBuilder: (context, index) {
              final track = _tracks[index];
              final isCurrent = _currentTrack?.id == track.id;
              final isCurrentlyPlaying = isCurrent && _isPlaying;
              final isFav = _favorites
                  .contains('${track.id}_$_selectedReciterId');

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? _accentMild : _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrent
                      ? Border.all(
                      color: _accent.withOpacity(0.3), width: 1.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 2),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                    isCurrent ? _accent : const Color(0xFFF0EEF6),
                    child: Text('${track.number}',
                        style: TextStyle(
                            color: isCurrent ? Colors.white : _textSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  title: Text(track.name,
                      style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                          color: _textMain)),
                  subtitle: Text(track.translation,
                      style: const TextStyle(
                          fontSize: 11, color: _textSub)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? Colors.pinkAccent : _textSub,
                          size: 20,
                        ),
                        onPressed: () => _toggleFavorite(track),
                      ),
                      IconButton(
                        icon: Icon(
                          isCurrentlyPlaying
                              ? Icons.pause_circle_rounded
                              : Icons.play_circle_rounded,
                          size: 32,
                          color: isCurrent ? _accent : _textSub,
                        ),
                        onPressed: () => isCurrentlyPlaying
                            ? _playPause()
                            : _playTrack(track),
                      ),
                    ],
                  ),
                  onTap: () => _playTrack(track),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}