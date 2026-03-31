// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get controllers => 'CONTROLLERS';

  @override
  String get settings => 'Settings';

  @override
  String get deviceName => 'Device Name';

  @override
  String get trackpad => 'Trackpad';

  @override
  String get dimmer => 'Dimmer';

  @override
  String get gentlyMove => 'Gently move or gesture';

  @override
  String get autoDimSync => 'Auto-Dim Sync';

  @override
  String get maxPacketRate => 'Max Packet Rate (FPS)';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get aboutApp => 'About App';

  @override
  String get licenses => 'Licenses';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageRussian => 'Русский';

  @override
  String version(Object version) {
    return 'Version: $version';
  }
}
