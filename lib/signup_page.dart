import 'package:flutter/material.dart';
import 'auth_service.dart';
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

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _service = AuthService();

  final TextEditingController _firstName       = TextEditingController();
  final TextEditingController _lastName        = TextEditingController();
  final TextEditingController _email           = TextEditingController();
  final TextEditingController _confirmEmail    = TextEditingController();
  final TextEditingController _password        = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  DateTime? _dob;
  bool _obscurePwd        = true;
  bool _obscureConfirmPwd = true;
  bool _isLoading         = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _confirmEmail.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _accent,
            onSurface: _textMain,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _signup() async {
    final l = AppLocalizations.of(context);
    if (_firstName.text.isEmpty ||
        _lastName.text.isEmpty ||
        _email.text.isEmpty) {
      _showMsg(l.insertAllFields);
      return;
    }
    if (_password.text.length < 6) { _showMsg(l.weakPassword); return; }
    if (_dob == null)               { _showMsg(l.selectDob); return; }
    if (!_service.isValid13(_dob!)) { _showMsg(l.must13); return; }
    if (_email.text != _confirmEmail.text) { _showMsg(l.emailsDoNotMatch); return; }
    if (_password.text != _confirmPassword.text) {
      _showMsg(l.passwordsDoNotMatch);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _service.signup(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        dob: _dob!,
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) Navigator.pop(context);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
                  child: const Icon(Icons.person_add_rounded,
                      color: _accent, size: 34),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  l.signup,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _textMain,
                      letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 32),

              // ── Personal info card ──────────────────────────────────────────
              _sectionLabel(l.firstName.split(' ').first), // reuse as "Personal Info" section header
              _buildSectionLabel('Personal Info'),
              const SizedBox(height: 8),
              _card(children: [
                _inputTile(
                  icon: Icons.person_rounded,
                  controller: _firstName,
                  label: l.firstName,
                  isFirst: true,
                ),
                const Divider(height: 1, color: _divider),
                _inputTile(
                  icon: Icons.person_outline_rounded,
                  controller: _lastName,
                  label: l.lastName,
                  isLast: true,
                ),
              ]),
              const SizedBox(height: 16),

              // ── Date of birth card ──────────────────────────────────────────
              _buildSectionLabel(l.dateOfBirth),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: _accentMild,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.cake_rounded,
                          color: _accent, size: 18),
                    ),
                    title: Text(
                      _dob == null
                          ? l.dateOfBirth
                          : '${_dob!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _dob == null ? _textSub : _textMain),
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded,
                        color: _accent, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Account info card ───────────────────────────────────────────
              _buildSectionLabel(l.email),
              const SizedBox(height: 8),
              _card(children: [
                _inputTile(
                  icon: Icons.email_rounded,
                  controller: _email,
                  label: l.email,
                  keyboardType: TextInputType.emailAddress,
                  isFirst: true,
                ),
                const Divider(height: 1, color: _divider),
                _inputTile(
                  icon: Icons.mark_email_read_rounded,
                  controller: _confirmEmail,
                  label: l.confirmEmail,
                  keyboardType: TextInputType.emailAddress,
                  isLast: true,
                ),
              ]),
              const SizedBox(height: 16),

              // ── Password card ───────────────────────────────────────────────
              _buildSectionLabel(l.password),
              const SizedBox(height: 8),
              _card(children: [
                _inputTile(
                  icon: Icons.lock_rounded,
                  controller: _password,
                  label: l.password,
                  obscureText: _obscurePwd,
                  isFirst: true,
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
                const Divider(height: 1, color: _divider),
                _inputTile(
                  icon: Icons.lock_outline_rounded,
                  controller: _confirmPassword,
                  label: l.confirmPassword,
                  obscureText: _obscureConfirmPwd,
                  isLast: true,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirmPwd
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: _textSub,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirmPwd = !_obscureConfirmPwd),
                  ),
                ),
              ]),
              const SizedBox(height: 28),

              // ── Create account button ───────────────────────────────────────
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
                  onPressed: _isLoading ? null : _signup,
                  child: _isLoading
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                      : Text(l.createAccount,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),

              // ── Already have account link ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.alreadyHaveAccount,
                      style: const TextStyle(fontSize: 13, color: _textSub)),
                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: _accent,
                        padding: const EdgeInsets.only(left: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.login,
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

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 0),
    child: Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textSub,
            letterSpacing: 0.4)),
  );

  // ignore: unused_element
  Widget _sectionLabel(String text) => const SizedBox.shrink();

  Widget _card({required List<Widget> children}) => Container(
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
    child: Column(children: children),
  );

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
            labelStyle: const TextStyle(
                fontSize: 13, color: _textSub, fontWeight: FontWeight.w500),
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