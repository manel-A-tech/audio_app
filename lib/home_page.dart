

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'player_page.dart';
import 'favourites_page.dart';
import 'profile_page.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _bg         = Color(0xFFFAF9F7);
const _accent     = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);
const _textMain   = Color(0xFF1A1A2E);
const _textSub    = Color(0xFF8A8A9A);
const _cardBg     = Colors.white;
const _divider    = Color(0xFFEEECE8);
const _barColor   = Color(0xFF7C6FA0);
const _progressBg = Color(0xFFE8E5F0);
const _progressFg = Color(0xFF7C6FA0);
const kRadius     = 16.0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentTab = 0;
  String _fullName = '';
  double _monthlyGoal = 20.0;
  double _totalMinutesListened = 0;
  Map<int, double> _dailyMinutes = {};
  List<Map<String, dynamic>> _topTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoal();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _monthlyGoal = prefs.getDouble('monthly_goal') ?? 20.0);
  }

  Future<void> _saveGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_goal', goal);
    setState(() => _monthlyGoal = goal);
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final fullName = await _authService.getFullName(user.uid);
      if (mounted) setState(() => _fullName = fullName);
    }
  }

  // IMPROVED: Better stats loading with proper date filtering
  Future<void> _loadStats() async {
    if (mounted) setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);

    // Get first and last day of current month
    final firstDay = '$currentMonth-01';
    final lastDay = DateFormat('yyyy-MM-dd').format(
        DateTime(now.year, now.month + 1, 0)
    );

    print('Loading stats from $firstDay to $lastDay'); // Debug

    try {
      final statsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .where('date', isGreaterThanOrEqualTo: firstDay)
          .where('date', isLessThanOrEqualTo: lastDay)
          .get();

      print('Found ${statsSnapshot.docs.length} stat documents'); // Debug

      double totalMinutes = 0;
      final Map<int, double> dailyMap = {};

      for (final doc in statsSnapshot.docs) {
        final data = doc.data();
        final minutes = (data['minutes'] as num).toDouble();
        final date = data['date'] as String;
        final day = int.parse(date.split('-')[2]);
        dailyMap[day] = (dailyMap[day] ?? 0) + minutes;
        totalMinutes += minutes;
        print('Date: $date, Minutes: $minutes'); // Debug
      }

      print('Total minutes: $totalMinutes'); // Debug
      print('Daily map: $dailyMap'); // Debug

      final tracksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('topTracks')
          .orderBy('count', descending: true)
          .limit(5)
          .get();

      final topTracks = tracksSnapshot.docs
          .map((d) => {'name': d.data()['name'], 'count': d.data()['count']})
          .toList();

      if (mounted) {
        setState(() {
          _totalMinutesListened = totalMinutes;
          _dailyMinutes = dailyMap;
          _topTracks = topTracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    }
  }

  void _updateGoal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius)),
        title: const Text('Set Monthly Goal',
            style: TextStyle(fontWeight: FontWeight.w800, color: _textMain)),
        content: DropdownButton<double>(
          value: _monthlyGoal,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 10.0, child: Text('10 hours')),
            DropdownMenuItem(value: 15.0, child: Text('15 hours')),
            DropdownMenuItem(value: 20.0, child: Text('20 hours')),
            DropdownMenuItem(value: 30.0, child: Text('30 hours')),
            DropdownMenuItem(value: 40.0, child: Text('40 hours')),
            DropdownMenuItem(value: 50.0, child: Text('50 hours')),
          ],
          onChanged: (value) {
            if (value != null) {
              _saveGoal(value);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  double get _progressPercentage {
    if (_monthlyGoal <= 0) return 0;
    return ((_totalMinutesListened / 60) / _monthlyGoal).clamp(0.0, 1.0);
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildDashboard() {
    final totalHours = (_totalMinutesListened / 60).floor();
    final totalMins  = (_totalMinutesListened % 60).floor();
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final maxY = _dailyMinutes.values.isEmpty
        ? 60.0
        : (_dailyMinutes.values.reduce((a, b) => a > b ? a : b) * 1.2)
        .ceilToDouble()
        .clamp(10.0, double.infinity);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome with refresh button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome',
                        style: TextStyle(fontSize: 13, color: _textSub,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(_fullName,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textMain,
                            letterSpacing: -0.5)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: _accent),
                  onPressed: () async {
                    await _loadStats();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stats refreshed')),
                      );
                    }
                  },
                  tooltip: 'Refresh stats',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Listening time card
            _card(
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _accentMild,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.headphones_rounded,
                        color: _accent, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Listening Time',
                          style: TextStyle(
                              fontSize: 11,
                              color: _textSub,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('${totalHours}h ${totalMins}min',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _textMain,
                              letterSpacing: -0.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Monthly goal card
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Goal  ·  ${_monthlyGoal.toStringAsFixed(0)}h',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textMain),
                      ),
                      GestureDetector(
                        onTap: _updateGoal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentMild,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Change',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _accent,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressPercentage,
                      backgroundColor: _progressBg,
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(_progressFg),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(_progressPercentage * 100).toStringAsFixed(0)}% of goal reached',
                    style: const TextStyle(
                        fontSize: 11,
                        color: _textSub,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Chart
            const Text('Minutes per day',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textMain)),
            const SizedBox(height: 3),
            Text(DateFormat('MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(fontSize: 11, color: _textSub)),
            const SizedBox(height: 10),
            _card(
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
              child: SizedBox(
                height: 180,
                child: _dailyMinutes.isEmpty
                    ? Center(
                  child: Text(
                    'Play some audio to see your\nlistening stats here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: _textSub),
                  ),
                )
                    : BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  barGroups: List.generate(daysInMonth, (i) {
                    final day = i + 1;
                    return BarChartGroupData(
                      x: day,
                      barRods: [
                        BarChartRodData(
                          toY: _dailyMinutes[day] ?? 0,
                          color: _barColor,
                          width: 5,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, _) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(
                              fontSize: 9, color: _textSub),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final d = val.toInt();
                          if (d % 5 == 0 || d == 1) {
                            return Text('$d',
                                style: const TextStyle(
                                    fontSize: 9, color: _textSub));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) =>
                    const FlLine(color: _divider, strokeWidth: 1),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                )),
              ),
            ),
            const SizedBox(height: 28),

            // Top tracks
            const Text('Most Listened',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textMain)),
            const SizedBox(height: 10),
            _card(
              padding: EdgeInsets.zero,
              child: _topTracks.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No tracks played yet.',
                    style: TextStyle(fontSize: 13, color: _textSub)),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _topTracks.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: _divider),
                itemBuilder: (context, index) {
                  final track = _topTracks[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: _accentMild,
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _accent)),
                    ),
                    title: Text(track['name'],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textMain)),
                    trailing: Text('${track['count']} plays',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _textSub,
                            fontWeight: FontWeight.w500)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0: return _buildDashboard();
      case 1: return const PlayerPage();
      case 2: return const FavouritesPage();
      case 3: return const ProfilePage();
      default: return _buildDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Dashboard', 'Player', 'Favourites', 'Profile'];
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          titles[_currentTab],
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: _textMain,
              letterSpacing: -0.3),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _divider, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentTab,
          backgroundColor: _bg,
          selectedItemColor: _accent,
          unselectedItemColor: _textSub,
          selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          onTap: (index) {
            setState(() => _currentTab = index);
            if (index == 0) _loadStats();
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.music_note_rounded), label: 'Player'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded), label: 'Favourites'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}