import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_localizations.dart';
import 'language_provider.dart';

const _accent = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);
const _textMain = Color(0xFF1A1A2E);
const _textSub = Color(0xFF8A8A9A);

/// Call this from anywhere to open the language picker sheet.
void showLanguagePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _LanguagePickerSheet(),
  );
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet();

  static const _options = [
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
    {'code': 'fr', 'label': 'Français', 'flag': '🇫🇷'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();
    final l = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l.language,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _textMain)),
            const SizedBox(height: 16),
            ..._options.map((opt) {
              final selected = provider.locale.languageCode == opt['code'];
              return GestureDetector(
                onTap: () {
                  provider.setLocale(Locale(opt['code']!));
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? _accentMild : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? _accent.withOpacity(0.4)
                          : Colors.grey.shade200,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(opt['flag']!,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Text(opt['label']!,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? _accent : _textMain)),
                      const Spacer(),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: _accent, size: 22),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}