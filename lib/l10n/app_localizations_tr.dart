// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get controllers => 'KONTROLCÜLER';

  @override
  String get settings => 'Ayarlar';

  @override
  String get deviceName => 'Cihaz Adı';

  @override
  String get trackpad => 'İzleme Dörtgeni';

  @override
  String get dimmer => 'Karartıcı';

  @override
  String get volume => 'Ses';

  @override
  String get gentlyMove => 'Yavaşça dokunun veya kaydırın';

  @override
  String get autoDimSync => 'Oto-Parlaklık Senkronu';

  @override
  String get maxPacketRate => 'Maksimum Paket Hızı (FPS)';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get aboutApp => 'Uygulama Hakkında';

  @override
  String get licenses => 'Lisanslar';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageRussian => 'Русский';

  @override
  String get reverseScroll => 'Kaydırmayı Tersine Çevir';

  @override
  String version(Object version) {
    return 'Sürüm: $version';
  }
}
