import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'signup_page.dart';
import 'reset_password_page.dart';
import 'app_localizations.dart';
import 'language_picker.dart';

// ── Design tokens (shared with the rest of the app) ───────────────────────────
const _bg         = Color(0xFFFAF9F7);
const _accent     = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);
const _textMain   = Color(0xFF1A1A2E);
const _textSub    = Color(0xFF8A8A9A);
const _cardBg     = Colors.white;
const _divider    = Color(0xFFEEECE8);
const kRadius     = 16.0;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _service = AuthService();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pwdCtrl   = TextEditingController();

  bool _obscurePwd = true;
  bool _isLoading  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _login() async {
    final l = AppLocalizations.of(context);
    if (_emailCtrl.text.isEmpty) { _showMsg(l.insertEmail); return; }
    if (_pwdCtrl.text.isEmpty)   { _showMsg(l.insertPassword); return; }

    setState(() => _isLoading = true);
    try {
      await _service.login(_emailCtrl.text.trim(), _pwdCtrl.text);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showMsg(l.userNotFound);
      } else if (e.code == 'wrong-password') {
        _showMsg(l.wrongPassword);
      } else {
        _showMsg('Error: ${e.message}');
      }
    } catch (e) {
      _showMsg('Error: $e');
    } finally {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded, color: _accent),
            tooltip: l.language,
            onPressed: () => showLanguagePicker(context),
          ),
        ],
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
                  child: const Icon(Icons.headphones_rounded,
                      color: _accent, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  l.login,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _textMain,
                      letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  l.dontHaveAccount,
                  style: const TextStyle(fontSize: 13, color: _textSub),
                ),
              ),
              const SizedBox(height: 32),

              // ── Form card ───────────────────────────────────────────────────
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
                    _inputTile(
                      icon: Icons.email_rounded,
                      controller: _emailCtrl,
                      label: l.email,
                      keyboardType: TextInputType.emailAddress,
                      isFirst: true,
                    ),
                    const Divider(height: 1, color: _divider),
                    _inputTile(
                      icon: Icons.lock_rounded,
                      controller: _pwdCtrl,
                      label: l.password,
                      obscureText: _obscurePwd,
                      isLast: true,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePwd
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: _textSub,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePwd = !_obscurePwd),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Forgot password ─────────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ResetPasswordPage())),
                  style: TextButton.styleFrom(
                      foregroundColor: _accent,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(l.forgotPassword,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Login button ────────────────────────────────────────────────
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
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                      : Text(l.login,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Sign up link ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.dontHaveAccount,
                      style:
                      const TextStyle(fontSize: 13, color: _textSub)),
                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: _accent,
                        padding: const EdgeInsets.only(left: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SignupPage())),
                    child: Text(l.signup,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputTile({
    required IconData icon,
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isFirst = false,
    bool isLast = false,
    Widget? suffix,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(kRadius) : Radius.zero,
        bottom: isLast ? const Radius.circular(kRadius) : Radius.zero,
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: _accentMild, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _accent, size: 18),
        ),
        title: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: _textMain),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
            const TextStyle(fontSize: 13, color: _textSub, fontWeight: FontWeight.w500),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            suffixIcon: suffix,
          ),
        ),
      ),
    );
  }
}