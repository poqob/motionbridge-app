import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/network_manager.dart';
import '../../../constants/app_haptics.dart';
import '../../settings/logic/settings_provider.dart';

class TrackpadState {
  final Offset pointerPosition;
  final bool isInteracting;

  TrackpadState({required this.pointerPosition, required this.isInteracting});

  TrackpadState copyWith({Offset? pointerPosition, bool? isInteracting}) {
    return TrackpadState(
      pointerPosition: pointerPosition ?? this.pointerPosition,
      isInteracting: isInteracting ?? this.isInteracting,
    );
  }
}

class TrackpadNotifier extends Notifier<TrackpadState> {
  Timer? _inertiaTimer;
  Offset _currentVelocity = Offset.zero;

  int _activePointers = 0;
  int _maxPointersInSequence = 0;
  bool _movedSignificantly = false;
  DateTime _lastScaleStartTime = DateTime.now();

  DateTime _lastPointerUpTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isDragMode = false;
  bool _dragStartSent = false;

  // Throttling state
  DateTime _lastSendTime = DateTime.now();
  double _accumulatedDx = 0;
  double _accumulatedDy = 0;
  int _lastPointerCount = 1;

  @override
  TrackpadState build() {
    return TrackpadState(pointerPosition: Offset.zero, isInteracting: false);
  }

  void _send(String type, Map<String, dynamic> data) {
    final Map<String, dynamic> payload = {"t": type};
    data.forEach((key, value) {
      if (value is double) {
        payload[key] = double.parse(value.toStringAsFixed(1));
      } else {
        payload[key] = value;
      }
    });
    NetworkManager().sendPacket(payload);
  }

  void _flushAccumulated() {
    if (_accumulatedDx != 0 || _accumulatedDy != 0) {
      if (_lastPointerCount == 1) {
        if (_isDragMode) {
          _send("DRAG", {"x": _accumulatedDx, "y": _accumulatedDy});
        } else {
          _send("M", {"x": _accumulatedDx, "y": _accumulatedDy});
        }
      } else if (_lastPointerCount == 2) {
        final reverse = ref.read(settingsProvider).reverseScroll;
        final multiplier = reverse ? -1.0 : 1.0;
        _send("S", {
          "x": _accumulatedDx * multiplier,
          "y": _accumulatedDy * multiplier,
        });
      }
      _accumulatedDx = 0;
      _accumulatedDy = 0;
    }
  }

  void onPointerDown(PointerDownEvent event) {
    if (_activePointers == 0) {
      _maxPointersInSequence = 0;
      _movedSignificantly = false;

      final timeSinceLastUp = DateTime.now()
          .difference(_lastPointerUpTime)
          .inMilliseconds;
      if (timeSinceLastUp < 300) {
        _isDragMode = true;
        _dragStartSent = true;
        _send("DRAG_START", {});
      } else {
        _isDragMode = false;
      }

      _lastScaleStartTime = DateTime.now();
    }
    _activePointers++;
    if (_activePointers > _maxPointersInSequence) {
      _maxPointersInSequence = _activePointers;
    }
  }

  void onPointerUp(PointerUpEvent event) {
    _activePointers--;
    if (_activePointers <= 0) {
      _activePointers = 0;
      _lastPointerUpTime = DateTime.now();

      final duration = DateTime.now()
          .difference(_lastScaleStartTime)
          .inMilliseconds;
      // Eğer drag modundaysak ve anlamlı bir şekilde sürüklendiysek tap yapma
      if (duration < 250 && !_movedSignificantly && !_dragStartSent) {
        if (_maxPointersInSequence == 1) {
          onLeftTap();
        } else if (_maxPointersInSequence == 2) {
          onRightTap();
        }
      }
    }
  }

  void onPointerCancel(PointerCancelEvent event) {
    _activePointers--;
    if (_activePointers < 0) _activePointers = 0;
  }

  void onScaleStart(ScaleStartDetails details) {
    _inertiaTimer?.cancel();
    _lastScaleStartTime = DateTime.now();
    _flushAccumulated();

    state = state.copyWith(
      pointerPosition: details.localFocalPoint,
      isInteracting: true,
    );
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    state = state.copyWith(pointerPosition: details.localFocalPoint);

    int pointers = details.pointerCount;
    if (pointers == 0) pointers = _activePointers;

    // If pointer count changes, flush the old accumulated data
    if (pointers != _lastPointerCount) {
      _flushAccumulated();
      _lastPointerCount = pointers;
    }

    _accumulatedDx += details.focalPointDelta.dx;
    if (details.focalPointDelta.distance > 1.5) {
      _movedSignificantly = true;
    }
    _accumulatedDy += details.focalPointDelta.dy;

    final now = DateTime.now();
    final maxFps = ref.read(settingsProvider).maxFps;
    final intervalMs = 1000 ~/ maxFps;

    if (now.difference(_lastSendTime).inMilliseconds >= intervalMs) {
      _flushAccumulated();
      _lastSendTime = now;
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    _flushAccumulated();

    bool wasDragMode = _isDragMode;
    if (_isDragMode && _dragStartSent) {
      _send("DRAG_END", {});
      _dragStartSent = false;
    }
    if (details.pointerCount == 0 || _activePointers <= 0) {
      _isDragMode = false;
    }

    state = state.copyWith(isInteracting: false);

    if (details.pointerCount == 0 && _activePointers > 0) {
      _activePointers = 0;
    }

    _currentVelocity = details.velocity.pixelsPerSecond / 60;
    if (_currentVelocity.distance < 1.0 || wasDragMode) return;

    _startInertia();
  }

  void _startInertia() {
    _inertiaTimer?.cancel();

    final maxFps = ref.read(settingsProvider).maxFps;
    final intervalMs = 1000 ~/ maxFps;

    _inertiaTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_currentVelocity.distance < 0.5) {
        timer.cancel();
        return;
      }
      final decayMultiplier = intervalMs / 16.0;
      final actualDecay = 1.0 - ((1.0 - 0.90) * decayMultiplier);

      _currentVelocity = _currentVelocity * actualDecay.clamp(0.0, 0.99);
      _send("M", {"x": _currentVelocity.dx, "y": _currentVelocity.dy});
    });
  }

  void onLeftTap() {
    AppHaptics.mediumImpact();
    _send("C", {"b": 0});
  }

  void onRightTap() {
    AppHaptics.mediumImpact();
    _send("C", {"b": 1});
  }
}

final trackpadProvider = NotifierProvider<TrackpadNotifier, TrackpadState>(
  TrackpadNotifier.new,
);
