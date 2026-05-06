import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_localizations.dart';

// ── Design tokens (shared with the rest of the app) ───────────────────────────
const _bg         = Color(0xFFFAF9F7);
const _accent     = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);
const _textMain   = Color(0xFF1A1A2E);
const _textSub    = Color(0xFF8A8A9A);
const _cardBg     = Colors.white;
const _divider    = Color(0xFFEEECE8);
const kRadius     = 16.0;

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _resetPassword() async {
    final l = AppLocalizations.of(context);
    if (_emailCtrl.text.isEmpty) { _showMsg(l.insertEmail); return; }

    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: _emailCtrl.text.trim());
      if (mounted) setState(() { _emailSent = true; _isLoading = false; });
      _showMsg(l.resetEmailSent);
    } catch (e) {
      _showMsg('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _accentMild,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: _accent.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: _accent, size: 34),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  l.resetPassword,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _textMain,
                      letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l.insertEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _textSub),
                ),
              ),
              const SizedBox(height: 36),

              // ── Email card ───────────────────────────────────────────────────
              if (!_emailSent) ...[
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kRadius),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: _accentMild,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.email_rounded,
                            color: _accent, size: 18),
                      ),
                      title: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _textMain),
                        decoration: InputDecoration(
                          labelText: l.email,
                          labelStyle: const TextStyle(
                              fontSize: 13,
                              color: _textSub,
                              fontWeight: FontWeight.w500),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Send button ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadius)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                        : Text(l.sendResetEmail,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],

              // ── Success state ────────────────────────────────────────────────
              if (_emailSent) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _accentMild,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(
                        color: _accent.withOpacity(0.25), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_read_rounded,
                          color: _accent, size: 48),
                      const SizedBox(height: 14),
                      Text(l.resetEmailSent,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textMain)),
                      const SizedBox(height: 6),
                      Text(_emailCtrl.text.trim(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: _textSub)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadius)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.login,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // ── Back to login ─────────────────────────────────────────────
              if (!_emailSent)
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: _accent),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.login,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}