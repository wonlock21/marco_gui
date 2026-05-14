import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'agv_settings.dart';
import 'services/connection_controller.dart';
import 'services/joystick_command_throttler.dart';
import 'widgets/control_lock_overlay.dart';

class LiftJoystick extends StatefulWidget {
  const LiftJoystick({super.key});

  @override
  State<LiftJoystick> createState() => _LiftJoystickState();
}

class _LiftJoystickState extends State<LiftJoystick> {
  final ValueNotifier<Offset> _knobOffset = ValueNotifier(Offset.zero);
  final LiftCommandThrottler _commandThrottler = LiftCommandThrottler();
  final _connection = ConnectionController.instance;

  @override
  void initState() {
    super.initState();
    _connection.state.addListener(_onConnectionChanged);
  }

  @override
  void dispose() {
    _connection.state.removeListener(_onConnectionChanged);
    _knobOffset.dispose();
    super.dispose();
  }

  void _onConnectionChanged() {
    if (_connection.state.value.status != AgvConnectionStatus.connected) {
      if (_knobOffset.value != Offset.zero) {
        _knobOffset.value = Offset.zero;
        _commandThrottler.onOffset(Offset.zero, deadZone: double.infinity);
        _commandThrottler.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: SettingsManager.joystickScaleNotifier,
      builder: (context, scale, _) {
        final screenHeight = MediaQuery.of(context).size.height;
        final radius = (screenHeight * 0.18) * scale;
        final deadZone = radius * 0.1;
        final knobSize = radius * 0.5;

        final lift = GestureDetector(
          onPanUpdate: (details) {
            final newY =
                (_knobOffset.value.dy + details.delta.dy).clamp(-radius, radius);
            final next = Offset(0, newY);
            _knobOffset.value = next;
            _commandThrottler.onOffset(next, deadZone: deadZone);
          },
          onPanEnd: (_) {
            _knobOffset.value = Offset.zero;
            _commandThrottler.onOffset(Offset.zero, deadZone: deadZone);
          },
          child: Container(
            width: knobSize * 1.5,
            height: radius * 2.2,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(50.r),
              border: Border.all(color: Colors.white10, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 2.w,
                  height: radius * 1.8,
                  color: Colors.white24,
                ),
                ValueListenableBuilder<Offset>(
                  valueListenable: _knobOffset,
                  builder: (context, offset, _) {
                    return Transform.translate(
                      offset: offset,
                      child: Container(
                        width: knobSize,
                        height: knobSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orangeAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          offset.dy < -deadZone
                              ? Icons.arrow_upward
                              : (offset.dy > deadZone
                                    ? Icons.arrow_downward
                                    : Icons.unfold_more),
                          color: Colors.black,
                          size: 20.r,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );

        return ControlLockOverlay(child: lift);
      },
    );
  }
}
