/*import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'biometric_service.dart';
import 'package:audio_app/ models/track.dart';
import 'services/api_service.dart';
import 'app_localizations.dart';
import 'surah_translations.dart';

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

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BiometricService _biometricService = BiometricService();
  final ApiService _apiService = ApiService();

  List<Track> _tracks = [];
  List<Track> _filteredTracks = [];
  Track? _currentTrack;
  bool _isPlaying = false;
  bool _isRepeat = false;
  Set<String> _favorites = {};
  bool _isLoading = true;
  String _selectedReciter = 'Mishary Rashid Alafasy';
  String _selectedReciterId = '1';
  List<Map<String, dynamic>> _reciters = [];
  DateTime? _playStartTime;
  bool _isTrackCompleted = false;
  String? _currentPlayingTrackId;

  // Progress tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSeeking = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Keys for SharedPreferences
  static const String _savedTrackId = 'saved_track_id';
  static const String _savedTrackPosition = 'saved_track_position';
  static const String _savedReciterId = 'saved_reciter_id';
  static const String _savedSurahNumber = 'saved_surah_number';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
    _searchController.addListener(_onSearchChanged);
    _setupProgressListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveCurrentPlaybackState();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    if (_playStartTime != null && !_isTrackCompleted && _currentTrack != null) {
      _saveListeningTime();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (_playStartTime != null && !_isTrackCompleted && _currentTrack != null) {
        _saveListeningTime();
        _playStartTime = null;
      }
      _saveCurrentPlaybackState();
    } else if (state == AppLifecycleState.resumed) {
      _restorePlaybackState();
    }
  }

  /*Future<void> _saveCurrentPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentTrack != null && !_isTrackCompleted) {
      await prefs.setString(_savedTrackId, _currentTrack!.id);
      await prefs.setInt(_savedSurahNumber, _currentTrack!.number);
      await prefs.setString(_savedReciterId, _selectedReciterId);
      await prefs.setInt(_savedTrackPosition, _currentPosition.inSeconds);
    }
  }*/

  Future<void> _saveCurrentPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();

    //
    if (_currentTrack == null || _isTrackCompleted) return;

    //
    if (_totalDuration.inSeconds > 0 &&
        _currentPosition >= _totalDuration) return;

    await prefs.setString(_savedTrackId, _currentTrack!.id);
    await prefs.setInt(_savedSurahNumber, _currentTrack!.number);
    await prefs.setString(_savedReciterId, _selectedReciterId);
    await prefs.setInt(_savedTrackPosition, _currentPosition.inSeconds);
  }

  Future<void> _restorePlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTrackId = prefs.getString(_savedTrackId);
    final savedReciterId = prefs.getString(_savedReciterId);
    final savedPosition = prefs.getInt(_savedTrackPosition) ?? 0;

    if (savedTrackId != null && savedReciterId != null && savedTrackId.isNotEmpty && _tracks.isNotEmpty) {
      Track? savedTrack;
      for (var track in _tracks) {
        if (track.id == savedTrackId) {
          savedTrack = track;
          break;
        }
      }

      if (savedTrack != null && savedTrack.id != _currentTrack?.id) {
        setState(() {
          _currentTrack = savedTrack;
        });
        await _player.stop();
        await _player.setUrl(savedTrack!.audioUrl);
        if (savedPosition > 0) {
          await _player.seek(Duration(seconds: savedPosition));
          _currentPosition = Duration(seconds: savedPosition);
        }
      }
    }
  }

  void _setupProgressListeners() {
    _player.positionStream.listen((position) {
      if (!_isSeeking && mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _player.durationStream.listen((duration) {
      if (duration != null && mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterTracks();
    });
  }

  void _filterTracks() {
    final locale = Localizations.localeOf(context).languageCode;
    if (_searchQuery.isEmpty) {
      _filteredTracks = List.from(_tracks);
    } else {
      _filteredTracks = _tracks.where((track) {
        final surahName = getSurahName(track.number, 'en').toLowerCase();
        final translation = getSurahTranslation(track.number, locale).toLowerCase();
        return surahName.contains(_searchQuery) ||
            translation.contains(_searchQuery) ||
            track.number.toString().contains(_searchQuery);
      }).toList();
    }
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
        _filteredTracks = List.from(tracks);
        _isLoading = false;
      });
    }

    await _restorePlaybackState();
  }

  Future<void> _loadTracks() async {
    if (mounted) setState(() => _isLoading = true);
    final tracks = await _apiService.getTracksByReciter(
        _selectedReciterId, _selectedReciter);
    await _player.stop();
    if (_playStartTime != null && !_isTrackCompleted && _currentTrack != null) {
      await _saveListeningTime();
      _playStartTime = null;
    }
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _filteredTracks = List.from(tracks);
        _searchQuery = '';
        _searchController.clear();
        _currentTrack = null;
        _isPlaying = false;
        _isTrackCompleted = false;
        _currentPlayingTrackId = null;
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
        _isLoading = false;
      });
    }
  }
  /*
   void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });



    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (_currentTrack != null && !_isTrackCompleted) {
          _isTrackCompleted = true;

          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentPosition = Duration.zero;
            });
          }

          if (_playStartTime != null) {
            await _saveListeningTime();
            _playStartTime = null;
          }

          _currentPlayingTrackId = null;
          _isTrackCompleted = false;
        }

        if (!_isRepeat) {
          if (mounted) {
            setState(() {
              _currentTrack = null;
            });
          }
        }
      }
    });
  }*/

  void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (_currentTrack != null) {
          _isTrackCompleted = true;

          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentPosition = Duration.zero;
            });
          }

          if (_playStartTime != null) {
            await _saveListeningTime();
            _playStartTime = null;
          }

          //
          await _clearSavedPlaybackState();

          _currentPlayingTrackId = null;
        }

        if (!_isRepeat) {
          if (mounted) {
            setState(() {
              _currentTrack = null;
            });
          }
        }
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

  Future<void> _saveListeningTime() async {
    if (_playStartTime == null || _currentTrack == null) {
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final elapsed = DateTime.now().difference(_playStartTime!);
    double minutes = elapsed.inSeconds / 60.0;

    if (minutes < 0.05) return;
    if (minutes > 60) minutes = 60;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Use ONLY the surah number for top tracks (without reciter)
    final uniqueTrackKey = 'surah_${_currentTrack!.number}';
    // Store only the surah name, not including reciter
    final surahName = getSurahName(_currentTrack!.number, "en");
    final userDoc = _firestore.collection('users').doc(userId);
    final statsRef = userDoc.collection('stats').doc(today);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(statsRef);
        if (snap.exists) {
          final currentMinutes = (snap.data()!['minutes'] as num).toDouble();
          tx.update(statsRef, {
            'minutes': currentMinutes + minutes,
            'date': today,
            'last_updated': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(statsRef, {
            'minutes': minutes,
            'date': today,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      });

      // Save to top tracks - using surah number as unique ID (not including reciter)
      final trackRef = userDoc.collection('topTracks').doc(uniqueTrackKey);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(trackRef);
        if (snap.exists) {
          final currentCount = (snap.data()!['count'] as num).toInt();
          final currentTotalMinutes = (snap.data()!['total_minutes'] as num?)?.toDouble() ?? 0;
          tx.update(trackRef, {
            'count': currentCount + 1,
            'name': surahName,  // Only surah name, no reciter
            'surah_name': surahName,
            'surah_number': _currentTrack!.number,
            'total_minutes': currentTotalMinutes + minutes,
            'last_played': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(trackRef, {
            'name': surahName,  // Only surah name, no reciter
            'surah_name': surahName,
            'surah_number': _currentTrack!.number,
            'count': 1,
            'total_minutes': minutes,
            'first_played': FieldValue.serverTimestamp(),
            'last_played': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _clearSavedPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedTrackId);
    await prefs.remove(_savedTrackPosition);
    await prefs.remove(_savedReciterId);
    await prefs.remove(_savedSurahNumber);
  }

  Future<void> _toggleFavorite(Track track) async {
    final l = AppLocalizations.of(context);
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    // For favorites, keep reciter info since user might want specific reciter
    final key = '${track.id}_$_selectedReciterId';
    if (_favorites.contains(key)) {
      final ok = await _biometricService.authenticateWithFingerprint(context);
      if (!ok) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.fingerprintRequired)));
        return;
      }
      await _firestore
          .collection('users').doc(userId).collection('favorites').doc(key).delete();
      if (mounted) {
        setState(() => _favorites.remove(key));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.removedFromFavourites)));
      }
    } else {
      await _firestore
          .collection('users').doc(userId).collection('favorites').doc(key)
          .set({
        'name': track.name,
        'surah_name': getSurahName(track.number, "en"),
        'reciter': track.reciter,
        'audioUrl': track.audioUrl,
        'number': track.number,
        'reciterId': _selectedReciterId,
        'added_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() => _favorites.add(key));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.addedToFavourites)));
      }
    }
  }

  void _playTrack(Track track) async {
    final l = AppLocalizations.of(context);

    if (_playStartTime != null && !_isTrackCompleted && _currentTrack != null) {
      await _saveListeningTime();
    }

    _playStartTime = null;
    _isTrackCompleted = false;
    _currentPlayingTrackId = track.id;

    setState(() {
      _currentTrack = track;
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });

    try {
      await _player.stop();
      await _player.setUrl(track.audioUrl);
      await _player.play();
      _playStartTime = DateTime.now();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l.errorPlaying} ${track.name}')));
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  void _playPause() async {
    if (_isPlaying) {
      if (_playStartTime != null && !_isTrackCompleted && _currentTrack != null) {
        await _saveListeningTime();
        _playStartTime = null;
      }
      await _player.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      if (_currentTrack != null) {
        _playStartTime = DateTime.now();
        await _player.play();
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeat = !_isRepeat;
      _player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    });
  }

  void _seekTo(Duration position) async {
    setState(() {
      _isSeeking = true;
    });
    await _player.seek(position);
    setState(() {
      _currentPosition = position;
      _isSeeking = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _changeReciter() {
    final l = AppLocalizations.of(context);
    if (_reciters.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius)),
        title: Text(l.selectReciter,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _textMain)),
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return Column(
      children: [
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
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          size: 14, color: _accent),
                      const SizedBox(width: 4),
                      Text(l.change,
                          style: const TextStyle(
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

        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.searchSurahs,
                hintStyle: const TextStyle(fontSize: 13, color: _textSub),
                prefixIcon: const Icon(Icons.search_rounded, color: _textSub, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: _textSub, size: 20),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredTracks.length} ${l.resultsFound}',
                  style: const TextStyle(fontSize: 11, color: _textSub),
                ),
              ],
            ),
          ),

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
                  '${_currentTrack!.number}. ${getSurahName(_currentTrack!.number, "en")}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3),
                  textAlign: TextAlign.center,
                ),
                if (getSurahTranslation(_currentTrack!.number, locale).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(getSurahTranslation(_currentTrack!.number, locale),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white70)),
                ],
                const SizedBox(height: 10),

                Column(
                  children: [
                    Slider(
                      value: _currentPosition.inSeconds.toDouble(),
                      max: _totalDuration.inSeconds.toDouble() > 0
                          ? _totalDuration.inSeconds.toDouble()
                          : 1.0,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                      onChanged: (value) {
                        _seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_currentPosition),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70),
                          ),
                          Text(
                            _formatDuration(_totalDuration),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

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

        Expanded(
          child: _filteredTracks.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: _textSub),
                const SizedBox(height: 12),
                Text(
                  '${l.noResultsFound} "$_searchQuery"',
                  style: const TextStyle(fontSize: 14, color: _textSub),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: _filteredTracks.length,
            itemBuilder: (context, index) {
              final track = _filteredTracks[index];
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
                  title: Text(
                    getSurahName(track.number, "en"),
                    style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                        color: _textMain),
                  ),
                  subtitle: Text(
                    getSurahTranslation(track.number, locale),
                    style: const TextStyle(
                        fontSize: 11, color: _textSub),
                  ),
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
}*/

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'biometric_service.dart';
import 'package:audio_app/ models/track.dart';
import 'services/api_service.dart';
import 'app_localizations.dart';
import 'surah_translations.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _accent     = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);
const _bg         = Color(0xFFEDEAE6); // warm soft gray
const _textMain   = Color(0xFF1A1A2E);
const _textSub    = Color(0xFF8A8A9A);
const _divider    = Color(0xFFE0DCF0);
const _cardBg     = Color(0xFFE8E4F0); // warmer lavender card bg
const _playerBg   = Color(0xFF6B6090); // softened player card (was #7C6FA0)
const _heartColor = Color(0xFFC4829A); // muted rose (was pinkAccent)
const kRadius     = 16.0;

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BiometricService _biometricService = BiometricService();
  final ApiService _apiService = ApiService();

  List<Track> _tracks = [];
  List<Track> _filteredTracks = [];
  Track? _currentTrack;
  bool _isPlaying = false;
  bool _isRepeat = false;
  Set<String> _favorites = {};
  bool _isLoading = true;
  String _selectedReciter = 'Mishary Rashid Alafasy';
  String _selectedReciterId = '1';
  List<Map<String, dynamic>> _reciters = [];
  DateTime? _playStartTime;
  bool _isTrackCompleted = false;
  String? _currentPlayingTrackId;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSeeking = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const String _savedTrackId = 'saved_track_id';
  static const String _savedTrackPosition = 'saved_track_position';
  static const String _savedReciterId = 'saved_reciter_id';
  static const String _savedSurahNumber = 'saved_surah_number';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
    _searchController.addListener(_onSearchChanged);
    _setupProgressListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveCurrentPlaybackState();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    if (_playStartTime != null && !_isTrackCompleted && _currentTrack != null) {
      _saveListeningTime();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_playStartTime != null &&
          !_isTrackCompleted &&
          _currentTrack != null) {
        _saveListeningTime();
        _playStartTime = null;
      }
      _saveCurrentPlaybackState();
    } else if (state == AppLifecycleState.resumed) {
      _restorePlaybackState();
    }
  }

  Future<void> _saveCurrentPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentTrack == null || _isTrackCompleted) return;
    if (_totalDuration.inSeconds > 0 &&
        _currentPosition >= _totalDuration) return;
    await prefs.setString(_savedTrackId, _currentTrack!.id);
    await prefs.setInt(_savedSurahNumber, _currentTrack!.number);
    await prefs.setString(_savedReciterId, _selectedReciterId);
    await prefs.setInt(_savedTrackPosition, _currentPosition.inSeconds);
  }

  Future<void> _restorePlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTrackId = prefs.getString(_savedTrackId);
    final savedReciterId = prefs.getString(_savedReciterId);
    final savedPosition = prefs.getInt(_savedTrackPosition) ?? 0;

    if (savedTrackId != null &&
        savedReciterId != null &&
        savedTrackId.isNotEmpty &&
        _tracks.isNotEmpty) {
      Track? savedTrack;
      for (var track in _tracks) {
        if (track.id == savedTrackId) {
          savedTrack = track;
          break;
        }
      }
      if (savedTrack != null && savedTrack.id != _currentTrack?.id) {
        setState(() => _currentTrack = savedTrack);
        await _player.stop();
        await _player.setUrl(savedTrack!.audioUrl);
        if (savedPosition > 0) {
          await _player.seek(Duration(seconds: savedPosition));
          _currentPosition = Duration(seconds: savedPosition);
        }
      }
    }
  }

  void _setupProgressListeners() {
    _player.positionStream.listen((position) {
      if (!_isSeeking && mounted) {
        setState(() => _currentPosition = position);
      }
    });
    _player.durationStream.listen((duration) {
      if (duration != null && mounted) {
        setState(() => _totalDuration = duration);
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterTracks();
    });
  }

  void _filterTracks() {
    final locale = Localizations.localeOf(context).languageCode;
    if (_searchQuery.isEmpty) {
      _filteredTracks = List.from(_tracks);
    } else {
      _filteredTracks = _tracks.where((track) {
        final surahName = getSurahName(track.number, 'en').toLowerCase();
        final translation =
        getSurahTranslation(track.number, locale).toLowerCase();
        return surahName.contains(_searchQuery) ||
            translation.contains(_searchQuery) ||
            track.number.toString().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _initializePlayer() async {
    final reciters = await _apiService.getReciters();
    final tracks =
    await _apiService.getTracksByReciter(_selectedReciterId, _selectedReciter);
    await _loadFavorites();
    _setupPlayerListeners();
    if (mounted) {
      setState(() {
        _reciters = reciters;
        _tracks = tracks;
        _filteredTracks = List.from(tracks);
        _isLoading = false;
      });
    }
    await _restorePlaybackState();
  }

  Future<void> _loadTracks() async {
    if (mounted) setState(() => _isLoading = true);
    final tracks = await _apiService.getTracksByReciter(
        _selectedReciterId, _selectedReciter);
    await _player.stop();
    if (_playStartTime != null && !_isTrackCompleted && _currentTrack != null) {
      await _saveListeningTime();
      _playStartTime = null;
    }
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _filteredTracks = List.from(tracks);
        _searchQuery = '';
        _searchController.clear();
        _currentTrack = null;
        _isPlaying = false;
        _isTrackCompleted = false;
        _currentPlayingTrackId = null;
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
        _isLoading = false;
      });
    }
  }

  void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });

    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (_currentTrack != null) {
          _isTrackCompleted = true;
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentPosition = Duration.zero;
            });
          }
          if (_playStartTime != null) {
            await _saveListeningTime();
            _playStartTime = null;
          }
          await _clearSavedPlaybackState();
          _currentPlayingTrackId = null;
        }
        if (!_isRepeat) {
          if (mounted) setState(() => _currentTrack = null);
        }
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
      setState(() => _favorites = snapshot.docs.map((d) => d.id).toSet());
    }
  }

  Future<void> _saveListeningTime() async {
    if (_playStartTime == null || _currentTrack == null) return;
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final elapsed = DateTime.now().difference(_playStartTime!);
    double minutes = elapsed.inSeconds / 60.0;
    if (minutes < 0.05) return;
    if (minutes > 60) minutes = 60;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final uniqueTrackKey = 'surah_${_currentTrack!.number}';
    final surahName = getSurahName(_currentTrack!.number, "en");
    final userDoc = _firestore.collection('users').doc(userId);
    final statsRef = userDoc.collection('stats').doc(today);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(statsRef);
        if (snap.exists) {
          final currentMinutes = (snap.data()!['minutes'] as num).toDouble();
          tx.update(statsRef, {
            'minutes': currentMinutes + minutes,
            'date': today,
            'last_updated': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(statsRef, {
            'minutes': minutes,
            'date': today,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      });

      final trackRef = userDoc.collection('topTracks').doc(uniqueTrackKey);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(trackRef);
        if (snap.exists) {
          final currentCount = (snap.data()!['count'] as num).toInt();
          final currentTotalMinutes =
              (snap.data()!['total_minutes'] as num?)?.toDouble() ?? 0;
          tx.update(trackRef, {
            'count': currentCount + 1,
            'name': surahName,
            'surah_name': surahName,
            'surah_number': _currentTrack!.number,
            'total_minutes': currentTotalMinutes + minutes,
            'last_played': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(trackRef, {
            'name': surahName,
            'surah_name': surahName,
            'surah_number': _currentTrack!.number,
            'count': 1,
            'total_minutes': minutes,
            'first_played': FieldValue.serverTimestamp(),
            'last_played': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _clearSavedPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedTrackId);
    await prefs.remove(_savedTrackPosition);
    await prefs.remove(_savedReciterId);
    await prefs.remove(_savedSurahNumber);
  }

  Future<void> _toggleFavorite(Track track) async {
    final l = AppLocalizations.of(context);
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final key = '${track.id}_$_selectedReciterId';
    if (_favorites.contains(key)) {
      final ok = await _biometricService.authenticateWithFingerprint(context);
      if (!ok) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.fingerprintRequired)));
        return;
      }
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(key)
          .delete();
      if (mounted) {
        setState(() => _favorites.remove(key));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.removedFromFavourites)));
      }
    } else {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(key)
          .set({
        'name': track.name,
        'surah_name': getSurahName(track.number, "en"),
        'reciter': track.reciter,
        'audioUrl': track.audioUrl,
        'number': track.number,
        'reciterId': _selectedReciterId,
        'added_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() => _favorites.add(key));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.addedToFavourites)));
      }
    }
  }

  void _playTrack(Track track) async {
    final l = AppLocalizations.of(context);

    if (_playStartTime != null && !_isTrackCompleted && _currentTrack != null) {
      await _saveListeningTime();
    }

    _playStartTime = null;
    _isTrackCompleted = false;
    _currentPlayingTrackId = track.id;

    setState(() {
      _currentTrack = track;
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });

    try {
      await _player.stop();
      await _player.setUrl(track.audioUrl);
      await _player.play();
      _playStartTime = DateTime.now();
      setState(() => _isPlaying = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l.errorPlaying} ${track.name}')));
        setState(() => _isPlaying = false);
      }
    }
  }

  void _playPause() async {
    if (_isPlaying) {
      if (_playStartTime != null && !_isTrackCompleted && _currentTrack != null) {
        await _saveListeningTime();
        _playStartTime = null;
      }
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_currentTrack != null) {
        _playStartTime = DateTime.now();
        await _player.play();
        setState(() => _isPlaying = true);
      }
    }
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeat = !_isRepeat;
      _player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    });
  }

  void _seekTo(Duration position) async {
    setState(() => _isSeeking = true);
    await _player.seek(position);
    setState(() {
      _currentPosition = position;
      _isSeeking = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Reciter picker modal with thin divider between each option.
  void _changeReciter() {
    final l = AppLocalizations.of(context);
    if (_reciters.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius)),
        backgroundColor: Colors.white,
        title: Text(l.selectReciter,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _textMain)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: () {
            // Build list with dividers between items
            final items = <Widget>[];
            for (int i = 0; i < _reciters.length; i++) {
              final reciter = _reciters[i];
              final isSelected = reciter['id'] == _selectedReciterId;
              items.add(
                InkWell(
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
                  child: Container(
                    color: isSelected
                        ? _accentMild.withOpacity(0.6)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            reciter['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? _accent : _textMain,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: _accent, size: 20),
                      ],
                    ),
                  ),
                ),
              );
              // Add thin divider between items (not after last)
              if (i < _reciters.length - 1) {
                items.add(const Divider(
                    height: 1, thickness: 1, color: _divider));
              }
            }
            return items;
          }(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return Column(
      children: [
        // ── Reciter row ──────────────────────────────────────────────────────
        Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _accentMild,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          size: 14, color: _accent),
                      const SizedBox(width: 4),
                      Text(l.change,
                          style: const TextStyle(
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

        // ── Search bar ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C6FA0).withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.searchSurahs,
                hintStyle: const TextStyle(fontSize: 13, color: _textSub),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _textSub, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: _textSub, size: 20),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredTracks.length} ${l.resultsFound}',
                  style: const TextStyle(fontSize: 11, color: _textSub),
                ),
              ],
            ),
          ),

        // ── Now-playing card (softened dark purple) ──────────────────────────
        if (_currentTrack != null)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            decoration: BoxDecoration(
              color: _playerBg, // #6B6090 — softened
              borderRadius: BorderRadius.circular(kRadius),
              boxShadow: [
                BoxShadow(
                    color: _playerBg.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Text(
                  '${_currentTrack!.number}. ${getSurahName(_currentTrack!.number, "en")}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3),
                  textAlign: TextAlign.center,
                ),
                if (getSurahTranslation(_currentTrack!.number, locale)
                    .isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    getSurahTranslation(_currentTrack!.number, locale),
                    style:
                    const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 10),

                // Progress slider
                Column(
                  children: [
                    Slider(
                      value: _currentPosition.inSeconds.toDouble(),
                      max: _totalDuration.inSeconds.toDouble() > 0
                          ? _totalDuration.inSeconds.toDouble()
                          : 1.0,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                      onChanged: (value) =>
                          _seekTo(Duration(seconds: value.toInt())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_currentPosition),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white70)),
                          Text(_formatDuration(_totalDuration),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isRepeat
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        size: 22,
                      ),
                      color: _isRepeat ? Colors.white : Colors.white38,
                      onPressed: _toggleRepeat,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _playPause,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: _playerBg,
                          size: 30,
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
                          ? _heartColor   // muted rose
                          : Colors.white38,
                      onPressed: () => _toggleFavorite(_currentTrack!),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // ── Track list ───────────────────────────────────────────────────────
        Expanded(
          child: _filteredTracks.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: _textSub),
                const SizedBox(height: 12),
                Text(
                  '${l.noResultsFound} "$_searchQuery"',
                  style:
                  const TextStyle(fontSize: 14, color: _textSub),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: _filteredTracks.length,
            itemBuilder: (context, index) {
              final track = _filteredTracks[index];
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
                        color: const Color(0xFF7C6FA0).withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 2),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                    isCurrent ? _accent : const Color(0xFFEDE9F5),
                    child: Text('${track.number}',
                        style: TextStyle(
                            color:
                            isCurrent ? Colors.white : _textSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  title: Text(
                    getSurahName(track.number, "en"),
                    style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                        color: _textMain),
                  ),
                  subtitle: Text(
                    getSurahTranslation(track.number, locale),
                    style: const TextStyle(
                        fontSize: 11, color: _textSub),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? _heartColor : _textSub, // muted rose
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