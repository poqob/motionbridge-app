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
  bool _lastActionWasTap = false;
  bool _waitingForDrag = false;
  Timer? _dragWaitTimer;
  DateTime _lastScrollTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Throttling state
  DateTime _lastSendTime = DateTime.now();
  double _accumulatedDx = 0;
  double _accumulatedDy = 0;
  int _lastPointerCount = 1;

  final Map<int, Offset> _currentPositions = {};
  final Map<int, Offset> _threeFingerStartPoints = {};
  bool _threeFingerGestureTriggered = false;

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
    if (_waitingForDrag &&
        (_accumulatedDx.abs() > 1 || _accumulatedDy.abs() > 1)) {
      _dragWaitTimer?.cancel();
      _waitingForDrag = false;
      _isDragMode = true;
      _dragStartSent = true;
      _send("DRAG_START", {});
    }

    if (_accumulatedDx != 0 || _accumulatedDy != 0) {
      if (_lastPointerCount == 1) {
        if (DateTime.now().difference(_lastScrollTime).inMilliseconds < 300) {
          _accumulatedDx = 0;
          _accumulatedDy = 0;
          return;
        }
        if (_isDragMode) {
          _send("DRAG", {"x": _accumulatedDx, "y": _accumulatedDy});
        } else {
          _send("M", {"x": _accumulatedDx, "y": _accumulatedDy});
        }
      } else if (_lastPointerCount == 2) {
        _lastScrollTime = DateTime.now();
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
    _currentPositions[event.pointer] = event.position;

    if (_activePointers == 0) {
      _maxPointersInSequence = 0;
      _movedSignificantly = false;

      final timeSinceLastUp = DateTime.now()
          .difference(_lastPointerUpTime)
          .inMilliseconds;
      final timeSinceScroll = DateTime.now()
          .difference(_lastScrollTime)
          .inMilliseconds;
      // 300ms window for double tap or drag, ignoring right after a scroll
      if (timeSinceLastUp < 300 &&
          _lastActionWasTap &&
          timeSinceScroll >= 300) {
        _waitingForDrag = true;
        _isDragMode = false;
        _dragStartSent = false;

        _dragWaitTimer?.cancel();
        // Wait 150ms to see if user holds the finger (Drag) or releases quickly (Double Tap)
        _dragWaitTimer = Timer(const Duration(milliseconds: 150), () {
          if (_waitingForDrag && _activePointers == 1) {
            _waitingForDrag = false;
            _isDragMode = true;
            _dragStartSent = true;
            _send("DRAG_START", {});
          }
        });
      } else {
        _isDragMode = false;
        _dragStartSent = false;
        _lastActionWasTap = false;
        _waitingForDrag = false;
      }

      _lastScaleStartTime = DateTime.now();
    }
    _activePointers++;
    if (_activePointers > _maxPointersInSequence) {
      _maxPointersInSequence = _activePointers;
    }

    if (_activePointers == 3) {
      _threeFingerStartPoints.clear();
      _threeFingerStartPoints.addAll(_currentPositions);
      _threeFingerGestureTriggered = false;
    }
  }

  void onPointerUp(PointerUpEvent event) {
    _currentPositions.remove(event.pointer);
    _threeFingerStartPoints.remove(event.pointer);
    _activePointers--;
    if (_activePointers <= 0) {
      _activePointers = 0;
      _lastPointerUpTime = DateTime.now();

      _dragWaitTimer?.cancel();

      if (_waitingForDrag) {
        // Quick release on the second tap -> Double Tap!
        _waitingForDrag = false;
        _lastActionWasTap = false;
        onDoubleTap();
      } else {
        final duration = DateTime.now()
            .difference(_lastScaleStartTime)
            .inMilliseconds;
        final timeSinceScroll = DateTime.now()
            .difference(_lastScrollTime)
            .inMilliseconds;

        if (duration < 250 &&
            !_movedSignificantly &&
            !_dragStartSent &&
            timeSinceScroll >= 300) {
          if (_maxPointersInSequence == 1) {
            onLeftTap();
            _lastActionWasTap = true;
          } else if (_maxPointersInSequence == 2) {
            onRightTap();
            _lastActionWasTap = false;
          } else {
            _lastActionWasTap = false;
          }
        } else {
          _lastActionWasTap = false;
        }
      }
    }
  }

  void onPointerCancel(PointerCancelEvent event) {
    _currentPositions.remove(event.pointer);
    _threeFingerStartPoints.remove(event.pointer);
    _activePointers--;
    if (_activePointers < 0) _activePointers = 0;
  }

  void onPointerMove(PointerMoveEvent event) {
    if (_currentPositions.containsKey(event.pointer)) {
      _currentPositions[event.pointer] = event.position;
    }

    if (_activePointers == 3 && !_threeFingerGestureTriggered) {
      if (_threeFingerStartPoints.length == 3) {
        double sumDx = 0;
        double sumDy = 0;
        int validCount = 0;
        for (final id in _threeFingerStartPoints.keys) {
          if (_currentPositions.containsKey(id)) {
            sumDx +=
                _currentPositions[id]!.dx - _threeFingerStartPoints[id]!.dx;
            sumDy +=
                _currentPositions[id]!.dy - _threeFingerStartPoints[id]!.dy;
            validCount++;
          }
        }

        if (validCount == 3) {
          final avgDx = sumDx / 3;
          final avgDy = sumDy / 3;

          // 25 pixels average distance for trigger
          if (avgDx.abs() > 25 || avgDy.abs() > 25) {
            String dir = "";
            if (avgDx.abs() > avgDy.abs()) {
              dir = avgDx > 0 ? "RIGHT" : "LEFT";
            } else {
              dir = avgDy > 0 ? "DOWN" : "UP";
            }
            _send("SWIPE_3", {"dir": dir});
            _threeFingerGestureTriggered = true;
          }
        }
      }
    }
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

  void onDoubleTap() {
    AppHaptics.mediumImpact();
    _send("DOUBLE_CLICK", {}); // or "DOUBLE_TAP" depending on backend
  }
}

final trackpadProvider = NotifierProvider<TrackpadNotifier, TrackpadState>(
  TrackpadNotifier.new,
);
