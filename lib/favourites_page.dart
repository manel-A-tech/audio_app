import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'biometric_service.dart';
import 'package:audio_app/ models/track.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _player = AudioPlayer();
  final BiometricService _biometricService = BiometricService();

  List<Track> _favourites = [];
  bool _isLoading = true;
  Track? _currentTrack;
  bool _isPlaying = false;

  // Don't keep alive — always reload when tab is switched to
  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
    _setupPlayerListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavourites();
  }

  void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  Future<void> _loadFavourites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();

    final favourites = snapshot.docs.map((doc) {
      final data = doc.data();
      return Track(
        id: doc.id,
        name: data['name'] ?? 'Unknown',
        reciter: data['reciter'] ?? 'Unknown',
        audioUrl: data['audioUrl'] ?? '',
        number: data['number'] ?? 0,
      );
    }).toList();

    favourites.sort((a, b) => a.number.compareTo(b.number));

    if (mounted) {
      setState(() {
        _favourites = favourites;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavourite(Track track) async {
    final isAuthenticated =
    await _biometricService.authenticateWithFingerprint(context);
    if (!isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Fingerprint required to remove favourites')),
        );
      }
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
        const SnackBar(content: Text('Removed from favourites')),
      );
    }
  }

  void _playTrack(Track track) async {
    setState(() => _currentTrack = track);
    try {
      await _player.stop();
      await _player.setUrl(track.audioUrl);
      await _player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing ${track.name}')),
        );
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadFavourites,
      child: Column(
        children: [
          // Now playing bar
          if (_currentTrack != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  const Icon(Icons.music_note),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentTrack!.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _currentTrack!.reciter,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 40,
                    ),
                    onPressed: _playPause,
                  ),
                ],
              ),
            ),

          Expanded(
            child: _favourites.isEmpty
                ? ListView(
              // Needed for RefreshIndicator to work when empty
              children: [
                SizedBox(
                  height: 400,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No favourites yet',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart icon on any surah\nto add it here',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            )
                : ListView.builder(
              itemCount: _favourites.length,
              itemBuilder: (context, index) {
                final track = _favourites[index];
                final isCurrent = _currentTrack?.id == track.id;
                final isCurrentlyPlaying = isCurrent && _isPlaying;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  color: isCurrent
                      ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.4)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      child: Text(
                        '${track.number}',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : null,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(track.name,
                        style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    subtitle: Text(track.reciter),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite,
                              color: Colors.red),
                          onPressed: () => _removeFavourite(track),
                          tooltip: 'Remove',
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