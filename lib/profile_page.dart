/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

const _accent     = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);
const _terracotta = Color(0xFFC4735A);
const _terracottaMild = Color(0xFFF7EBE7);
const _textMain   = Color(0xFF1A1A2E);
const _textSub    = Color(0xFF8A8A9A);
const _divider    = Color(0xFFEEECE8);
const _cardBg     = Colors.white;
const kRadius     = 16.0;

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
      if (mounted) setState(() { _profile = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w800, color: _textMain)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: _textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
            },
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    final initials = _profile['firstName'] != null &&
        (_profile['firstName'] as String).isNotEmpty
        ? (_profile['firstName'] as String).substring(0, 1).toUpperCase()
        : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        children: [
          // Avatar with soft shadow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _accent.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: _accentMild,
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: _accent)),
            ),
          ),
          const SizedBox(height: 18),

          // Name
          Text(
            '${_profile['firstName'] ?? ''} ${_profile['lastName'] ?? ''}'.trim(),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textMain,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Text(user?.email ?? '',
              style: const TextStyle(fontSize: 13, color: _textSub)),
          const SizedBox(height: 32),

          // Info card
          Container(
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
            child: Column(
              children: [
                _infoTile(icon: Icons.person_rounded,
                    label: 'First Name',
                    value: _profile['firstName'] ?? '-',
                    isFirst: true),
                const Divider(height: 1, color: _divider),
                _infoTile(icon: Icons.person_outline_rounded,
                    label: 'Last Name',
                    value: _profile['lastName'] ?? '-'),
                const Divider(height: 1, color: _divider),
                _infoTile(icon: Icons.email_rounded,
                    label: 'Email',
                    value: _profile['email'] ?? user?.email ?? '-'),
                const Divider(height: 1, color: _divider),
                _infoTile(icon: Icons.cake_rounded,
                    label: 'Date of Birth',
                    value: _profile['dob'] ?? '-',
                    isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout button — terracotta
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadius)),
                elevation: 0,
              ),
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log Out',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(kRadius) : Radius.zero,
        bottom: isLast ? const Radius.circular(kRadius) : Radius.zero,
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _accentMild,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _accent, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: _textSub,
                fontWeight: FontWeight.w500)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 15,
                color: _textMain,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'app_localizations.dart';
import 'language_picker.dart';

const _accent         = Color(0xFF7C6FA0);
const _accentMild     = Color(0xFFEDE9F5);
const _terracotta     = Color(0xFFC4735A);
const _textMain       = Color(0xFF1A1A2E);
const _textSub        = Color(0xFF8A8A9A);
const _divider        = Color(0xFFEEECE8);
const _cardBg         = Colors.white;
const kRadius         = 16.0;

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
      if (mounted) setState(() { _profile = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmLogout(AppLocalizations l) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
        title: Text(l.logoutConfirmTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _textMain)),
        content: Text(l.logoutConfirmMsg,
            style: const TextStyle(color: _textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel,
                style: const TextStyle(color: _accent, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
            },
            child: Text(l.logout,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = _auth.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    final initials = _profile['firstName'] != null &&
        (_profile['firstName'] as String).isNotEmpty
        ? (_profile['firstName'] as String).substring(0, 1).toUpperCase()
        : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _accent.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: _accentMild,
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 42, fontWeight: FontWeight.w800, color: _accent)),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${_profile['firstName'] ?? ''} ${_profile['lastName'] ?? ''}'.trim(),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: _textMain),
          ),
          const SizedBox(height: 4),
          Text(user?.email ?? '',
              style: const TextStyle(fontSize: 13, color: _textSub)),
          const SizedBox(height: 32),

          // Info card
          Container(
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
            child: Column(
              children: [
                _infoTile(icon: Icons.person_rounded,         label: l.firstName,  value: _profile['firstName'] ?? '-',          isFirst: true),
                const Divider(height: 1, color: _divider),
                _infoTile(icon: Icons.person_outline_rounded, label: l.lastName,   value: _profile['lastName'] ?? '-'),
                const Divider(height: 1, color: _divider),
                _infoTile(icon: Icons.email_rounded,          label: l.email,      value: _profile['email'] ?? user?.email ?? '-'),
                const Divider(height: 1, color: _divider),
                _infoTile(icon: Icons.cake_rounded,           label: l.dob,        value: _profile['dob'] ?? '-',                isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Language picker button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadius)),
              ),
              onPressed: () => showLanguagePicker(context),
              icon: const Icon(Icons.language_rounded, size: 20),
              label: Text(l.language,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadius)),
                elevation: 0,
              ),
              onPressed: () => _confirmLogout(l),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(l.logout,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast  = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top:    isFirst ? const Radius.circular(kRadius) : Radius.zero,
        bottom: isLast  ? const Radius.circular(kRadius) : Radius.zero,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: _accentMild, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _accent, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(
                fontSize: 11, color: _textSub, fontWeight: FontWeight.w500)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 15, color: _textMain, fontWeight: FontWeight.w600)),
      ),
    );
  }
}