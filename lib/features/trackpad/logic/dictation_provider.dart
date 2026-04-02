import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../settings/logic/settings_provider.dart';
import '../../../utils/network_manager.dart';

class DictationState {
  final bool isListening;
  final bool hasPermission;
  final String lastWords;
  final List<LocaleName> systemLocales;

  DictationState({
    this.isListening = false,
    this.hasPermission = false,
    this.lastWords = '',
    this.systemLocales = const [],
  });

  DictationState copyWith({
    bool? isListening,
    bool? hasPermission,
    String? lastWords,
    List<LocaleName>? systemLocales,
  }) {
    return DictationState(
      isListening: isListening ?? this.isListening,
      hasPermission: hasPermission ?? this.hasPermission,
      lastWords: lastWords ?? this.lastWords,
      systemLocales: systemLocales ?? this.systemLocales,
    );
  }
}

class DictationNotifier extends Notifier<DictationState> {
  final SpeechToText _speechToText = SpeechToText();

  @override
  DictationState build() {
    _initSpeech();
    return DictationState();
  }

  Future<void> _initSpeech() async {
    bool hasPermission = await _speechToText.initialize();
    if (hasPermission) {
      final locales = await _speechToText.locales();
      state = state.copyWith(
        hasPermission: hasPermission,
        systemLocales: locales,
      );
    } else {
      state = state.copyWith(hasPermission: false);
    }
  }

  Future<void> startListening() async {
    if (!state.hasPermission) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;
      await _initSpeech();
      if (!state.hasPermission) return;
    }

    final localeId = ref.read(settingsProvider).languageCode;

    await _speechToText.listen(
      onResult: (result) {
        state = state.copyWith(lastWords: result.recognizedWords);
        if (result.finalResult) {
          NetworkManager().sendDictation(result.recognizedWords);
          state = state.copyWith(isListening: false);
        }
      },
      localeId: localeId.isNotEmpty ? localeId : null,
      listenMode: ListenMode.dictation,
    );
    state = state.copyWith(isListening: true);
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false);
  }

  void toggleListening() {
    if (state.isListening) {
      stopListening();
    } else {
      startListening();
    }
  }
}

final dictationProvider = NotifierProvider<DictationNotifier, DictationState>(
  () {
    return DictationNotifier();
  },
);
