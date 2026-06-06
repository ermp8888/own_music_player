import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../features/player/presentation/providers/player_provider.dart';

/// Sleep timer state
class SleepTimerState {
  final bool isActive;
  final Duration remaining;
  final Duration total;

  const SleepTimerState({
    this.isActive = false,
    this.remaining = Duration.zero,
    this.total = Duration.zero,
  });

  double get progress => total.inSeconds > 0
      ? remaining.inSeconds / total.inSeconds
      : 0.0;

  String get remainingLabel {
    final mins = remaining.inMinutes;
    final secs = remaining.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  SleepTimerState copyWith({
    bool? isActive,
    Duration? remaining,
    Duration? total,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      remaining: remaining ?? this.remaining,
      total: total ?? this.total,
    );
  }
}

/// Manages a countdown timer that fades audio and stops playback.
class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  Timer? _timer;

  /// Callback to set audio volume (0.0 to 1.0)
  final Future<void> Function(double volume)? onVolumeChange;

  /// Callback to pause/stop playback
  final Future<void> Function()? onStop;

  SleepTimerNotifier({
    this.onVolumeChange,
    this.onStop,
  }) : super(const SleepTimerState());

  /// Start the sleep timer with given duration in minutes.
  void start(int minutes) {
    cancel(); // Cancel any existing timer

    final total = Duration(minutes: minutes);
    state = SleepTimerState(
      isActive: true,
      remaining: total,
      total: total,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remaining - const Duration(seconds: 1);

      if (remaining.inSeconds <= 0) {
        // Timer expired — stop playback
        _stopPlayback();
        return;
      }

      // Fade volume over last 5 seconds
      if (remaining.inSeconds <= 5) {
        final fadeVolume = remaining.inSeconds / 5.0;
        onVolumeChange?.call(fadeVolume.clamp(0.0, 1.0));
      }

      state = state.copyWith(remaining: remaining);
    });
  }

  /// Cancel the timer and restore volume.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    onVolumeChange?.call(1.0); // Restore volume
    state = const SleepTimerState();
  }

  Future<void> _stopPlayback() async {
    _timer?.cancel();
    _timer = null;
    await onVolumeChange?.call(0.0);
    await onStop?.call();
    // Restore volume for next session
    await onVolumeChange?.call(1.0);
    state = const SleepTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for the sleep timer.
final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  return SleepTimerNotifier(
    onVolumeChange: (volume) async {
      // just_audio volume control through the audio handler
      await audioHandler.setVolume(volume);
    },
    onStop: () async {
      await audioHandler.pause();
    },
  );
});

/// Available sleep timer durations.
const sleepTimerOptions = AppConstants.sleepTimerOptions;

/// Shows a bottom sheet for selecting sleep timer duration.
void showSleepTimerSheet(BuildContext context, WidgetRef ref) {
  final timerState = ref.read(sleepTimerProvider);
  final notifier = ref.read(sleepTimerProvider.notifier);

  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Sleep Timer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (timerState.isActive)
            ListTile(
              leading: const Icon(Icons.timer_off_rounded, color: Colors.red),
              title: Text('Cancel Timer (${timerState.remainingLabel} left)'),
              onTap: () {
                notifier.cancel();
                Navigator.pop(context);
              },
            ),
          ...sleepTimerOptions.map((minutes) => ListTile(
                leading: const Icon(Icons.timer_rounded),
                title: Text('$minutes minutes'),
                trailing: timerState.isActive &&
                        timerState.total.inMinutes == minutes
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  notifier.start(minutes);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sleep timer set for $minutes minutes'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              )),
        ],
      ),
    ),
  );
}
