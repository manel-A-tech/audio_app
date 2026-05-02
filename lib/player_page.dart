import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'biometric_service.dart';
import 'package:audio_app/ models/track.dart';
import 'services/api_service.dart';

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
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
      if (!state.playing && _playStartTime != null) {
        _saveListeningTime();
      }
    });
  }

  Future<void> _loadFavorites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    if (mounted) {
      setState(() {
        _favorites = snapshot.docs.map((d) => d.id).toSet();
      });
    }
  }

  Future<void> _saveListeningTime() async {
    if (_playStartTime == null || _currentTrack == null) return;
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final elapsed = DateTime.now().difference(_playStartTime!);
    final minutes = elapsed.inSeconds / 60.0;
    _playStartTime = null;
    if (minutes < 0.1) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final trackName = _currentTrack!.name;
    final userDoc = _firestore.collection('users').doc(userId);

    final statsRef = userDoc.collection('stats').doc(today);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(statsRef);
      if (snap.exists) {
        final current = (snap.data()!['minutes'] as num).toDouble();
        tx.update(statsRef, {'minutes': current + minutes});
      } else {
        tx.set(statsRef, {'minutes': minutes, 'date': today});
      }
    });

    final trackRef = userDoc.collection('topTracks').doc(trackName);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(trackRef);
      if (snap.exists) {
        final current = (snap.data()!['count'] as num).toInt();
        tx.update(trackRef, {'count': current + 1});
      } else {
        tx.set(trackRef, {'name': trackName, 'count': 1});
      }
    });
  }

  Future<void> _toggleFavorite(Track track) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    if (_favorites.contains("${track.id}_$_selectedReciterId")) {
      final isAuthenticated =
      await _biometricService.authenticateWithFingerprint(context);
      if (!isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Fingerprint required to remove favorites')));
        }
        return;
      }
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc("${track.id}_${_selectedReciterId}")
          .delete();
      if (mounted) {
        setState(() => _favorites.remove("${track.id}_$_selectedReciterId"));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')));
      }
    } else {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc("${track.id}_${_selectedReciterId}")
          .set({
        'name': track.name,
        'reciter': track.reciter,
        'audioUrl': track.audioUrl,
        'number': track.number,
        'reciterId': _selectedReciterId,
      });
      if (mounted) {
        setState(() => _favorites.add("${track.id}_$_selectedReciterId"));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites')));
      }
    }
  }

  void _playTrack(Track track) async {
    if (_playStartTime != null) await _saveListeningTime();
    setState(() => _currentTrack = track);

    try {
      await _player.stop();
      await _player.setUrl(track.audioUrl);
      await _player.play();
      _playStartTime = DateTime.now();
    } catch (e) {
      debugPrint('Error playing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error playing ${track.name}')));
      }
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
        title: const Text('Select Reciter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reciters.map((reciter) {
            final isSelected = reciter['id'] == _selectedReciterId;
            return ListTile(
              title: Text(reciter['name']),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.green)
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
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_playStartTime != null) _saveListeningTime();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audio Player'),
            Text(_selectedReciter,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _changeReciter,
            tooltip: 'Change Reciter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Now playing bar
          if (_currentTrack != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: [
                  Text(
                    '${_currentTrack!.number}. ${_currentTrack!.name}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (_currentTrack!.translation.isNotEmpty)
                    Text(_currentTrack!.translation,
                        style: const TextStyle(fontSize: 12)),
                  Text(_currentTrack!.reciter,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_isRepeat
                            ? Icons.repeat_one
                            : Icons.repeat),
                        color: _isRepeat ? Colors.green : null,
                        onPressed: _toggleRepeat,
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 52,
                        ),
                        onPressed: _playPause,
                      ),
                      IconButton(
                        icon: Icon(
                          _favorites.contains("${_currentTrack!.id}_$_selectedReciterId")
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _favorites.contains("${_currentTrack!.id}_$_selectedReciterId")
                              ? Colors.red
                              : null,
                        ),
                        onPressed: () => _toggleFavorite(_currentTrack!),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Surah list
          Expanded(
            child: _tracks.isEmpty
                ? const Center(child: Text('No tracks available'))
                : ListView.builder(
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final isCurrentlyPlaying =
                    _currentTrack?.id == track.id && _isPlaying;
                final isCurrent = _currentTrack?.id == track.id;

                return ListTile(
                  tileColor: isCurrent
                      ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3)
                      : null,
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    child: Text(
                      '${track.number}',
                      style: TextStyle(
                          color: isCurrent ? Colors.white : null,
                          fontSize: 13),
                    ),
                  ),
                  title: Text(track.name,
                      style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  subtitle: Text(track.translation),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _favorites.contains("${track.id}_$_selectedReciterId")
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _favorites.contains("${track.id}_$_selectedReciterId")
                              ? Colors.red
                              : Colors.grey,
                          size: 22,
                        ),
                        onPressed: () => _toggleFavorite(track),
                      ),
                      IconButton(
                        icon: Icon(
                          isCurrentlyPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          size: 34,
                          color: isCurrent
                              ? Theme.of(context)
                              .colorScheme
                              .primary
                              : null,
                        ),
                        onPressed: () => isCurrentlyPlaying
                            ? _playPause()
                            : _playTrack(track),
                      ),
                    ],
                  ),
                  onTap: () => _playTrack(track),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.music_note), label: 'Player'),
        ],
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
      ),
    );
  }
}