import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic> _profile = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final data = await _authService.getProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              _profile['firstName'] != null &&
                  (_profile['firstName'] as String).isNotEmpty
                  ? (_profile['firstName'] as String)
                  .substring(0, 1)
                  .toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Full name
          Text(
            '${_profile['firstName'] ?? ''} ${_profile['lastName'] ?? ''}'
                .trim(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Info card
          Card(
            child: Column(
              children: [
                _infoTile(
                    context: context,
                    icon: Icons.person,
                    label: 'First Name',
                    value: _profile['firstName'] ?? '-'),
                const Divider(height: 1),
                _infoTile(
                    context: context,
                    icon: Icons.person_outline,
                    label: 'Last Name',
                    value: _profile['lastName'] ?? '-'),
                const Divider(height: 1),
                _infoTile(
                    context: context,
                    icon: Icons.email,
                    label: 'Email',
                    value: _profile['email'] ?? user?.email ?? '-'),
                const Divider(height: 1),
                _infoTile(
                    context: context,
                    icon: Icons.cake,
                    label: 'Date of Birth',
                    value: _profile['dob'] ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Log Out', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title:
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 16, color: Colors.black87)),
    );
  }
}