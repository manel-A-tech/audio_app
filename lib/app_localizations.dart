import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  // ── Auth & Navigation ──────────────────────────────────────────────────────

  String get appName => _t(en: 'Tarteel', fr: 'Tarteel');

  String get login => _t(en: 'Login', fr: 'Connexion');
  String get signup => _t(en: 'Sign Up', fr: "S'inscrire");
  String get logout => _t(en: 'Log Out', fr: 'Se déconnecter');
  String get logoutConfirmTitle => _t(en: 'Log Out', fr: 'Déconnexion');
  String get logoutConfirmMsg =>
      _t(en: 'Are you sure you want to log out?', fr: 'Voulez-vous vraiment vous déconnecter ?');
  String get cancel => _t(en: 'Cancel', fr: 'Annuler');
  String get email => _t(en: 'Email', fr: 'E-mail');
  String get password => _t(en: 'Password', fr: 'Mot de passe');
  String get confirmEmail => _t(en: 'Confirm Email', fr: 'Confirmer l\'e-mail');
  String get confirmPassword => _t(en: 'Confirm Password', fr: 'Confirmer le mot de passe');
  String get firstName => _t(en: 'First Name', fr: 'Prénom');
  String get lastName => _t(en: 'Last Name', fr: 'Nom de famille');
  String get dateOfBirth => _t(en: 'Date of Birth', fr: 'Date de naissance');
  String get forgotPassword => _t(en: 'Forgot Password?', fr: 'Mot de passe oublié ?');
  String get resetPassword => _t(en: 'Reset Password', fr: 'Réinitialiser le mot de passe');
  String get sendResetEmail =>
      _t(en: 'Send Reset Email', fr: 'Envoyer l\'e-mail de réinitialisation');
  String get alreadyHaveAccount =>
      _t(en: 'Already have an account?', fr: 'Vous avez déjà un compte ?');
  String get dontHaveAccount =>
      _t(en: "Don't have an account?", fr: "Vous n'avez pas de compte ?");
  String get createAccount => _t(en: 'Create Account', fr: 'Créer un compte');

  // ── Validation messages ────────────────────────────────────────────────────

  String get insertEmail => _t(en: 'Please enter your email', fr: 'Veuillez saisir votre e-mail');
  String get insertPassword => _t(en: 'Please enter your password', fr: 'Veuillez saisir votre mot de passe');
  String get insertAllFields => _t(en: 'Please fill in all fields', fr: 'Veuillez remplir tous les champs');
  String get weakPassword =>
      _t(en: 'Weak password — use at least 6 characters', fr: 'Mot de passe faible — utilisez au moins 6 caractères');
  String get selectDob => _t(en: 'Please select your date of birth', fr: 'Veuillez sélectionner votre date de naissance');
  String get must13 => _t(en: 'You must be at least 13 years old', fr: 'Vous devez avoir au moins 13 ans');
  String get emailsDoNotMatch => _t(en: 'Emails do not match', fr: 'Les e-mails ne correspondent pas');
  String get passwordsDoNotMatch =>
      _t(en: 'Passwords do not match', fr: 'Les mots de passe ne correspondent pas');
  String get userNotFound => _t(en: 'No user found for that email.', fr: 'Aucun utilisateur trouvé pour cet e-mail.');
  String get wrongPassword => _t(en: 'Wrong password provided.', fr: 'Mot de passe incorrect.');
  String get resetEmailSent =>
      _t(en: 'Password reset email sent! Check your inbox.', fr: 'E-mail de réinitialisation envoyé ! Vérifiez votre boîte de réception.');

  // ── Home / Player ──────────────────────────────────────────────────────────

  String get home => _t(en: 'Home', fr: 'Accueil');
  String get favourites => _t(en: 'Favourites', fr: 'Favoris');
  String get profile => _t(en: 'Profile', fr: 'Profil');
  String get selectReciter => _t(en: 'Select Reciter', fr: 'Choisir un récitateur');
  String get surahs => _t(en: 'Surahs', fr: 'Sourates');
  String get searchSurahs => _t(en: 'Search surahs...', fr: 'Rechercher des sourates...');
  String get nowPlaying => _t(en: 'Now Playing', fr: 'En cours de lecture');
  String get addedToFavourites => _t(en: 'Added to favourites', fr: 'Ajouté aux favoris');
  String get removedFromFavourites =>
      _t(en: 'Removed from favourites', fr: 'Retiré des favoris');
  String get errorPlaying => _t(en: 'Error playing track', fr: 'Erreur lors de la lecture');

  // ── Favourites page ────────────────────────────────────────────────────────

  String get noFavouritesYet => _t(en: 'No favourites yet', fr: 'Pas encore de favoris');
  String get noFavouritesHint =>
      _t(en: 'Tap the heart icon on any surah\nto add it here', fr: 'Appuyez sur l\'icône cœur d\'une sourate\npour l\'ajouter ici');
  String get fingerprintRequired =>
      _t(en: 'Fingerprint required to remove favourites', fr: 'Empreinte digitale requise pour supprimer les favoris');
  String get remove => _t(en: 'Remove', fr: 'Retirer');

  // ── Biometric ─────────────────────────────────────────────────────────────

  String get authRequired => _t(en: 'Authentication required', fr: 'Authentification requise');
  String get fingerprintReason =>
      _t(en: 'Verify your identity with fingerprint', fr: 'Vérifiez votre identité par empreinte digitale');
  String get tryAgain => _t(en: 'Try Again', fr: 'Réessayer');

  // ── Profile ────────────────────────────────────────────────────────────────

  String get dob => _t(en: 'Date of Birth', fr: 'Date de naissance');

  // ── Settings / Language ───────────────────────────────────────────────────

  String get language => _t(en: 'Language', fr: 'Langue');
  String get settings => _t(en: 'Settings', fr: 'Paramètres');

  // ── Dashboard / Home Page ─────────────────────────────────────────────────

  String get welcome => _t(en: 'Welcome', fr: 'Bienvenue');
  String get totalListeningTime => _t(en: 'Total Listening Time', fr: "Temps d'écoute total");
  String get monthlyGoal => _t(en: 'Monthly Goal', fr: 'Objectif mensuel');
  String get minutesPerDay => _t(en: 'Minutes per day', fr: 'Minutes par jour');
  String get mostListened => _t(en: 'Most Listened', fr: 'Les plus écoutés');
  String get change => _t(en: 'Change', fr: 'Changer');
  String get refreshStats => _t(en: 'Refresh stats', fr: 'Actualiser les statistiques');
  String get statsRefreshed => _t(en: 'Stats refreshed', fr: 'Statistiques actualisées');
  String get ofGoalReached => _t(en: '% of goal reached', fr: '% de l\'objectif atteint');
  String get noTracksPlayed => _t(en: 'No tracks played yet.', fr: 'Aucun morceau joué pour le moment');
  String get plays => _t(en: 'plays', fr: 'lectures');
  String get noStatsHint => _t(en: 'Play some audio to see your\nlistening stats here.', fr: 'Écoutez de l\'audio pour voir vos\nstatistiques ici');

  // ── Player Page ───────────────────────────────────────────────────────────

  String get resultsFound => _t(en: 'results found', fr: 'résultats trouvés');
  String get noResultsFound => _t(en: 'No results found for', fr: 'Aucun résultat trouvé pour');

  // ── Internal helper ────────────────────────────────────────────────────────

  String _t({required String en, required String fr}) {
    return locale.languageCode == 'fr' ? fr : en;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}