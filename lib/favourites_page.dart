/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'biometric_service.dart';
import 'package:audio_app/ models/track.dart';
import 'app_localizations.dart';

const _accent     = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);
const _textMain   = Color(0xFF1A1A2E);
const _textSub    = Color(0xFF8A8A9A);
const _cardBg     = Colors.white;
const kRadius     = 16.0;

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});
  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _player = AudioPlayer();
  final BiometricService _biometricService = BiometricService();

  List<Track> _favourites = [];
  bool _isLoading = true;
  Track? _currentTrack;
  bool _isPlaying = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _loadFavourites();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _player.playerStateStream
        .listen((s) { if (mounted) setState(() => _isPlaying = s.playing); });
  }

  Future<void> _loadFavourites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final snapshot = await _firestore
        .collection('users').doc(userId).collection('favorites').get();
    final favs = snapshot.docs.map((doc) {
      final d = doc.data();
      return Track(
        id: doc.id,
        name: d['name'] ?? 'Unknown',
        reciter: d['reciter'] ?? 'Unknown',
        audioUrl: d['audioUrl'] ?? '',
        number: d['number'] ?? 0,
        translation: '',
      );
    }).toList();
    favs.sort((a, b) => a.number.compareTo(b.number));
    if (mounted) setState(() { _favourites = favs; _isLoading = false; });
  }

  Future<void> _removeFavourite(Track track) async {
    final l = AppLocalizations.of(context);
    final ok = await _biometricService.authenticateWithFingerprint(context);
    if (!ok) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.fingerprintRequired)));
      return;
    }
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore
        .collection('users').doc(userId).collection('favorites').doc(track.id).delete();
    if (mounted) {
      setState(() => _favourites.removeWhere((t) => t.id == track.id));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.removedFromFavourites)));
    }
  }

  void _playTrack(Track track) async {
    final l = AppLocalizations.of(context);
    setState(() => _currentTrack = track);
    try {
      await _player.stop();
      await _player.setUrl(track.audioUrl);
      await _player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l.errorPlaying}: ${track.name}')));
      }
    }
  }

  void _playPause() async {
    if (_isPlaying) { await _player.pause(); } else { await _player.play(); }
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadFavourites,
      child: Column(
        children: [
          if (_currentTrack != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(kRadius),
                boxShadow: [
                  BoxShadow(
                      color: _accent.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentTrack!.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                        Text(_currentTrack!.reciter,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                    onPressed: _playPause,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: _favourites.isEmpty
                ? ListView(children: [
              SizedBox(
                height: 380,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 72, color: _textSub.withOpacity(0.4)),
                    const SizedBox(height: 18),
                    Text(l.noFavouritesYet,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _textMain)),
                    const SizedBox(height: 8),
                    Text(
                      l.noFavouritesHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: _textSub.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ])
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _favourites.length,
              itemBuilder: (context, index) {
                final track = _favourites[index];
                final isCurrent = _currentTrack?.id == track.id;
                final isPlaying = isCurrent && _isPlaying;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? _accentMild : _cardBg,
                    borderRadius: BorderRadius.circular(kRadius),
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
                        horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      radius: 20,
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
                            fontSize: 14,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _textMain)),
                    subtitle: Text(track.reciter,
                        style: const TextStyle(
                            fontSize: 11, color: _textSub)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded,
                              color: Colors.pinkAccent, size: 20),
                          onPressed: () => _removeFavourite(track),
                          tooltip: l.remove,
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_rounded
                                : Icons.play_circle_rounded,
                            size: 34,
                            color: isCurrent ? _accent : _textSub,
                          ),
                          onPressed: () =>
                          isPlaying ? _playPause() : _playTrack(track),
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
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'biometric_service.dart';
import 'package:audio_app/ models/track.dart';
import 'app_localizations.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _accent     = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);
const _textMain   = Color(0xFF1A1A2E);
const _textSub    = Color(0xFF8A8A9A);
const _cardBg     = Color(0xFFE8E4F0); // warmer lavender card bg
const _heartColor = Color(0xFFC4829A); // muted rose
const kRadius     = 16.0;

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});
  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _player = AudioPlayer();
  final BiometricService _biometricService = BiometricService();

  List<Track> _favourites = [];
  bool _isLoading = true;
  Track? _currentTrack;
  bool _isPlaying = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _loadFavourites();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _player.playerStateStream.listen(
            (s) { if (mounted) setState(() => _isPlaying = s.playing); });
  }

  Future<void> _loadFavourites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    final favs = snapshot.docs.map((doc) {
      final d = doc.data();
      return Track(
        id: doc.id,
        name: d['name'] ?? 'Unknown',
        reciter: d['reciter'] ?? 'Unknown',
        audioUrl: d['audioUrl'] ?? '',
        number: d['number'] ?? 0,
        translation: '',
      );
    }).toList();
    favs.sort((a, b) => a.number.compareTo(b.number));
    if (mounted) {
      setState(() {
        _favourites = favs;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavourite(Track track) async {
    final l = AppLocalizations.of(context);
    final ok = await _biometricService.authenticateWithFingerprint(context);
    if (!ok) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.fingerprintRequired)));
      return;
    }
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(track.id)
        .delete();
    if (mounted) {
      setState(() => _favourites.removeWhere((t) => t.id == track.id));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.removedFromFavourites)));
    }
  }

  void _playTrack(Track track) async {
    final l = AppLocalizations.of(context);
    setState(() => _currentTrack = track);
    try {
      await _player.stop();
      await _player.setUrl(track.audioUrl);
      await _player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l.errorPlaying}: ${track.name}')));
      }
    }
  }

  void _playPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadFavourites,
      child: Column(
        children: [
          // ── Now-playing mini-bar ───────────────────────────────────────────
          if (_currentTrack != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(kRadius),
                boxShadow: [
                  BoxShadow(
                      color: _accent.withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentTrack!.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                        Text(_currentTrack!.reciter,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                    onPressed: _playPause,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Track list ─────────────────────────────────────────────────────
          Expanded(
            child: _favourites.isEmpty
                ? ListView(children: [
              SizedBox(
                height: 380,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 72,
                        color: _textSub.withOpacity(0.4)),
                    const SizedBox(height: 18),
                    Text(l.noFavouritesYet,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _textMain)),
                    const SizedBox(height: 8),
                    Text(
                      l.noFavouritesHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: _textSub.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ])
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _favourites.length,
              itemBuilder: (context, index) {
                final track = _favourites[index];
                final isCurrent = _currentTrack?.id == track.id;
                final isPlaying = isCurrent && _isPlaying;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? _accentMild : _cardBg,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: isCurrent
                        ? Border.all(
                        color: _accent.withOpacity(0.3), width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF7C6FA0).withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: isCurrent
                          ? _accent
                          : const Color(0xFFEDE9F5),
                      child: Text('${track.number}',
                          style: TextStyle(
                              color:
                              isCurrent ? Colors.white : _textSub,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Text(track.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _textMain)),
                    subtitle: Text(track.reciter,
                        style: const TextStyle(
                            fontSize: 11, color: _textSub)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded,
                              color: _heartColor, // muted rose
                              size: 20),
                          onPressed: () => _removeFavourite(track),
                          tooltip: l.remove,
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_rounded
                                : Icons.play_circle_rounded,
                            size: 34,
                            color: isCurrent ? _accent : _textSub,
                          ),
                          onPressed: () => isPlaying
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
      ),
    );
  }
}