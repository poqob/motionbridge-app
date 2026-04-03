import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/network_manager.dart';
import '../../../constants/app_haptics.dart';

class VolumeState {
  final double value;
  final bool isMuted;

  VolumeState({required this.value, required this.isMuted});

  VolumeState copyWith({double? value, bool? isMuted}) {
    return VolumeState(
      value: value ?? this.value,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

final volumeProvider = NotifierProvider<VolumeNotifier, VolumeState>(() {
  return VolumeNotifier();
});

class VolumeNotifier extends Notifier<VolumeState> {
  DateTime _lastSendTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  VolumeState build() {
    return VolumeState(
      value: 50.0,
      isMuted: false,
    ); // Varsayılan olarak %50 ve sessiz değil
  }

  void updateVolume(double value) {
    state = state.copyWith(value: value.clamp(0.0, 100.0), isMuted: false);

    // Küçük titreşim hissi
    if (value.toInt() % 10 == 0) {
      AppHaptics.lightImpact();
    }

    // Throttle the sending a bit to avoid flooding, but volume should be fairly responsive
    final now = DateTime.now();
    if (now.difference(_lastSendTime).inMilliseconds > 50) {
      _lastSendTime = now;
      NetworkManager().sendPacket({"t": "VOL", "v": value.toInt()});
    }
  }

  void flushVolume() {
    // Sürükleme bittiğinde son değeri tam olarak gönder
    NetworkManager().sendPacket({"t": "VOL", "v": state.value.toInt()});
  }

  void toggleMute() {
    final newState = !state.isMuted;
    state = state.copyWith(isMuted: newState);
    AppHaptics.mediumImpact();

    NetworkManager().sendPacket({"t": "MUTE"});
  }
}
