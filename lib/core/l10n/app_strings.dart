import 'package:flutter/widgets.dart';

///App-level user-facing strings (launcher, settings, shared dialogs).
///Each game keeps its own strings next to its code.
///
///English only for now. To add a language: subclass with the same getters,
///return it from [_AppStringsDelegate.load] for that locale and list the
///locale in `MaterialApp.supportedLocales`.
class AppStrings {
  const AppStrings();

  static const AppStrings en = AppStrings();

  static const LocalizationsDelegate<AppStrings> delegate = _AppStringsDelegate();

  static AppStrings of(BuildContext context) => Localizations.of<AppStrings>(context, AppStrings) ?? en;

  //Launcher
  String get appName => 'Khelora';
  String get tagline => 'Play Your Way.';
  String get homeGreeting => 'Ready to play?';
  String get homeEyebrow => 'Game room';
  String get play => 'Play';
  String get continueMatch => 'Continue';
  String get newMatch => 'New match';
  String get howToPlay => 'How to play';
  String get moreGames => 'More games on the way';
  String get comingSoon => 'Coming soon';
  String comingSoonMessage(String game) => '$game is coming soon!';
  String get records => 'Records';
  String get settings => 'Settings';
  String get about => 'About';
  String get exit => 'Exit';
  String get exitTitle => 'Exit Khelora?';
  String get exitBody => 'Are you sure you want to exit the game?';
  String get stay => 'Stay';
  String get exitButton => 'Exit';
  String get featuredGame => 'Featured game';

  //Settings
  String get general => 'General';
  String get sound => 'Sound';
  String get soundHint => 'Dice, moves, captures and wins';
  String get vibration => 'Vibration';
  String get vibrationHint => 'Rolls, landings, captures and wins';
  String get gameSpeed => 'Game speed';
  String get speedNormal => 'Normal';
  String get speedFast => 'Fast';
  String get resetSettings => 'Reset settings';
  String get resetSettingsTitle => 'Reset settings?';
  String get resetSettingsBody => 'Sound, vibration, game speed and board theme go back to their defaults.';
  String get aboutBody => 'Classic board games to play offline with friends or against the computer.';
  String get developedBy => 'Developed by';
  String get companyName => 'Innovatex Technology Pvt. Ltd.';
  String get companyWebsite => 'innovatex-technology.com';
  String get companyEmail => 'info@innovatex-technology.com';
  String get companyPhone => '+91-9664361738';
  String get companyAddress => 'Jaipur, Rajasthan, India';
  String get privacyTitle => 'Your privacy';
  String get privacyBody =>
      'This game works fully offline. It does not collect, store or share any personal data. '
      'Your game progress, settings and records stay on this device.';
  String get openSourceLicenses => 'Open-source licenses';
  String legalese(int year) => '© $year Innovatex Technology Pvt. Ltd.';
  String version(String v) => 'Version $v';

  //Pause
  String get paused => 'Paused';
  String get resume => 'Resume';
  String get restart => 'Restart';
  String get quit => 'Quit';
  String get restartTitle => 'Restart match?';
  String get restartBody => 'The current match will start over from the beginning.';
  String get quitTitle => 'Quit match?';
  String get quitBody => 'This match will end and its progress will be lost.';

  //Common
  String get cancel => 'Cancel';
  String get confirm => 'Confirm';
  String get reset => 'Reset';
  String get close => 'Close';
  String get back => 'Back';
  String get on => 'On';
  String get off => 'Off';
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings.en;

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
