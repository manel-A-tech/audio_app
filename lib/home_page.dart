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

  Future<void> _loadStats() async {
    if (mounted) setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);

    final statsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .where('date', isGreaterThanOrEqualTo: '$currentMonth-01')
        .where('date', isLessThanOrEqualTo: '$currentMonth-31')
        .get();

    double totalMinutes = 0;
    final Map<int, double> dailyMap = {};

    for (final doc in statsSnapshot.docs) {
      final data = doc.data();
      final minutes = (data['minutes'] as num).toDouble();
      final date = data['date'] as String;
      final day = int.parse(date.split('-')[2]);
      dailyMap[day] = (dailyMap[day] ?? 0) + minutes;
      totalMinutes += minutes;
    }

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
  }

  void _updateGoal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Goal'),
        content: DropdownButton<double>(
          value: _monthlyGoal,
          isExpanded: true,
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

  Widget _buildDashboard() {
    final totalHours = (_totalMinutesListened / 60).floor();
    final totalMinutes = (_totalMinutesListened % 60).floor();
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final maxY = _dailyMinutes.values.isEmpty
        ? 60.0
        : (_dailyMinutes.values.reduce((a, b) => a > b ? a : b) * 1.2)
        .ceilToDouble()
        .clamp(10.0, double.infinity);

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            RichText(
              text: TextSpan(
                style:
                const TextStyle(fontSize: 24, color: Colors.black),
                children: [
                  const TextSpan(text: 'Welcome, '),
                  TextSpan(
                    text: _fullName,
                    style:
                    const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Total listening time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.headphones, size: 36),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Listening Time',
                            style: TextStyle(fontSize: 14)),
                        Text(
                          '$totalHours h $totalMinutes min',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Monthly goal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Monthly Goal: ${_monthlyGoal.toStringAsFixed(0)} h',
                            style: const TextStyle(fontSize: 15)),
                        TextButton(
                          onPressed: _updateGoal,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progressPercentage,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${(_progressPercentage * 100).toStringAsFixed(0)}% completed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bar chart
            const Text('Minutes per day (this month)',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: SizedBox(
                  height: 180,
                  child: _dailyMinutes.isEmpty
                      ? const Center(
                    child: Text(
                      'No data yet.\nPlay some audio to see your stats!',
                      textAlign: TextAlign.center,
                    ),
                  )
                      : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barGroups: List.generate(daysInMonth, (i) {
                        final day = i + 1;
                        return BarChartGroupData(
                          x: day,
                          barRods: [
                            BarChartRodData(
                              toY: _dailyMinutes[day] ?? 0,
                              color: Colors.blue,
                              width: 6,
                              borderRadius:
                              BorderRadius.circular(3),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (val, meta) =>
                                Text(val.toInt().toString(),
                                    style: const TextStyle(
                                        fontSize: 10)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final day = val.toInt();
                              if (day % 5 == 0 || day == 1) {
                                return Text('$day',
                                    style: const TextStyle(
                                        fontSize: 10));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles:
                            SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles:
                            SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Top tracks
            const Text('Most listened tracks',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: _topTracks.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tracks played yet.'),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _topTracks.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1),
                itemBuilder: (context, index) {
                  final track = _topTracks[index];
                  return ListTile(
                    leading: CircleAvatar(
                        child: Text('${index + 1}')),
                    title: Text(track['name']),
                    trailing: Text('${track['count']} plays'),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PlayerPage()),
                  );
                  _loadStats();
                },
                icon: const Icon(Icons.music_note),
                label: const Text('Go to Audio Player'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return _buildDashboard();
      case 1:
        return const PlayerPage();
      case 2:
        return const FavouritesPage();
      case 3:
        return const ProfilePage();
      default:
        return _buildDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ['Dashboard', 'Player', 'Favourites', 'Profile'][_currentTab],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() => _currentTab = index);
          if (index == 0) _loadStats();
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.music_note), label: 'Player'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favourites'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}