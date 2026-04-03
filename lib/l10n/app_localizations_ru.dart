// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get controllers => 'КОНТРОЛЛЕРЫ';

  @override
  String get settings => 'Настройки';

  @override
  String get deviceName => 'Имя устройства';

  @override
  String get trackpad => 'Трекпад';

  @override
  String get dimmer => 'Диммер';

  @override
  String get volume => 'Звук';

  @override
  String get gentlyMove => 'Аккуратно двигайте или используйте жесты';

  @override
  String get autoDimSync => 'Авто-яркость';

  @override
  String get maxPacketRate => 'Макс. частота пакетов (FPS)';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Темная';

  @override
  String get aboutApp => 'О приложении';

  @override
  String get licenses => 'Лицензии';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Система';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageRussian => 'Русский';

  @override
  String get reverseScroll => 'Обратная прокрутка';

  @override
  String version(Object version) {
    return 'Версия: $version';
  }
}
