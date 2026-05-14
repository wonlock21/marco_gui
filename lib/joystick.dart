import 'package:flutter/material.dart';

import 'agv_settings.dart';
import 'services/autonomy_controller.dart';
import 'services/connection_controller.dart';
import 'services/joystick_command_throttler.dart';
import 'widgets/control_lock_overlay.dart';

class Joystick extends StatefulWidget {
  final bool isCameraOn;

  const Joystick({super.key, this.isCameraOn = false});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  final ValueNotifier<Offset> _knobOffset = ValueNotifier(Offset.zero);
  final JoystickCommandThrottler _commandThrottler = JoystickCommandThrottler();
  final _connection = ConnectionController.instance;
  final _autonomy = AutonomyController.instance;

  @override
  void initState() {
    super.initState();
    _connection.state.addListener(_onLockChanged);
    _autonomy.isAuto.addListener(_onLockChanged);
  }

  @override
  void dispose() {
    _connection.state.removeListener(_onLockChanged);
    _autonomy.isAuto.removeListener(_onLockChanged);
    _knobOffset.dispose();
    super.dispose();
  }

  void _onLockChanged() {
    final conn = _connection.state.value;
    final locked = conn.status != AgvConnectionStatus.connected ||
        _autonomy.isAuto.value;
    if (locked && _knobOffset.value != Offset.zero) {
      _knobOffset.value = Offset.zero;
      _commandThrottler.onOffset(Offset.zero, deadZone: double.infinity);
      _commandThrottler.reset();
    }
  }

  void _resetKnob() {
    _knobOffset.value = Offset.zero;
    _commandThrottler.reset();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: SettingsManager.joystickScaleNotifier,
      builder: (context, scale, _) {
        final screenHeight = MediaQuery.of(context).size.height;
        final radius = (screenHeight * 0.18) * scale;
        final deadZone = radius * 0.05;
        final knobSize = radius * 0.5;

        final joystick = GestureDetector(
          onPanUpdate: (details) {
            var next = _knobOffset.value + details.delta;
            if (next.distance > radius) {
              next = Offset.fromDirection(next.direction, radius);
            }
            _knobOffset.value = next;
            _commandThrottler.onOffset(next, deadZone: deadZone);
          },
          onPanEnd: (_) {
            _resetKnob();
            _commandThrottler.onOffset(Offset.zero, deadZone: deadZone);
          },
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isCameraOn
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
              boxShadow: widget.isCameraOn
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: radius * 1.4,
                  height: radius * 1.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                ValueListenableBuilder<Offset>(
                  valueListenable: _knobOffset,
                  builder: (context, offset, _) {
                    final strength =
                        (offset.distance / radius).clamp(0.0, 1.0);
                    final knobColor = Color.fromARGB(
                      255,
                      (150 * strength).toInt(),
                      0,
                      (150 * (1 - strength)).toInt(),
                    );

                    return Transform.translate(
                      offset: offset,
                      child: Container(
                        width: knobSize,
                        height: knobSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: knobColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 5,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );

        return ControlLockOverlay(
          lockOnAutonomy: true,
          child: joystick,
        );
      },
    );
  }
}
