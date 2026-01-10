import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/player_provider.dart';

/// Full screen player with visualizer
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final positionData = ref.watch(positionDataProvider);
    final playerState = ref.watch(playerStateProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeConstants.playerGradient,
        ),
        child: SafeArea(
          child: currentSong.when(
            data: (song) {
              if (song == null) {
                return const Center(
                  child: Text('No song playing'),
                );
              }

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          iconSize: 32,
                        ),
                        Column(
                          children: [
                            Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                color: ThemeConstants.primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              song.album,
                              style: TextStyle(
                                color: ThemeConstants.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            // TODO: More options
                          },
                          icon: const Icon(Icons.more_vert_rounded),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Album art with visualizer
                  _buildAlbumArt(ref, isPlaying),

                  const Spacer(),

                  // Song info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          song.artist,
                          style: TextStyle(
                            fontSize: 16,
                            color: ThemeConstants.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Progress bar
                  positionData.when(
                    data: (data) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: data.position.inMilliseconds.toDouble(),
                              max: data.duration.inMilliseconds > 0
                                  ? data.duration.inMilliseconds.toDouble()
                                  : 1,
                              onChanged: (value) {
                                ref
                                    .read(playerStateProvider.notifier)
                                    .seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  Formatters.formatDuration(data.position),
                                  style: TextStyle(
                                    color: ThemeConstants.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  Formatters.formatDuration(data.duration),
                                  style: TextStyle(
                                    color: ThemeConstants.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Shuffle
                        IconButton(
                          onPressed: () {
                            ref.read(playerStateProvider.notifier).toggleShuffle();
                          },
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: playerState.shuffleEnabled
                                ? ThemeConstants.primaryColor
                                : ThemeConstants.textMuted,
                          ),
                        ),
                        // Previous
                        IconButton(
                          onPressed: () {
                            ref.read(playerStateProvider.notifier).previous();
                          },
                          icon: const Icon(Icons.skip_previous_rounded),
                          iconSize: 40,
                        ),
                        // Play/Pause
                        isPlaying.when(
                          data: (playing) => Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: ThemeConstants.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: ThemeConstants.glowShadow,
                            ),
                            child: IconButton(
                              onPressed: () {
                                ref.read(playerStateProvider.notifier).togglePlay();
                              },
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              iconSize: 36,
                            ),
                          ).animate().scale(delay: 200.ms, duration: 300.ms),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Icon(Icons.error),
                        ),
                        // Next
                        IconButton(
                          onPressed: () {
                            ref.read(playerStateProvider.notifier).next();
                          },
                          icon: const Icon(Icons.skip_next_rounded),
                          iconSize: 40,
                        ),
                        // Repeat
                        IconButton(
                          onPressed: () {
                            ref.read(playerStateProvider.notifier).cycleRepeatMode();
                          },
                          icon: Icon(
                            playerState.repeatMode == RepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: playerState.repeatMode != RepeatMode.off
                                ? ThemeConstants.primaryColor
                                : ThemeConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading player')),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(WidgetRef ref, AsyncValue<bool> isPlaying) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visualizer rings (simplified)
          ...List.generate(3, (index) {
            return isPlaying.when(
              data: (playing) => AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 240 + (index * 40),
                height: 240 + (index * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ThemeConstants.primaryColor.withValues(
                      alpha: playing ? 0.3 - (index * 0.1) : 0.1,
                    ),
                    width: 2,
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          }),
          // Album art container
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              gradient: ThemeConstants.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: ThemeConstants.glowShadow,
            ),
            child: isPlaying.when(
              data: (playing) => AnimatedRotation(
                duration: const Duration(seconds: 10),
                turns: playing ? 1 : 0,
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 100,
                ),
              ),
              loading: () => const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 100,
              ),
              error: (_, __) => const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 100,
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}

/// Audio visualizer widget (simplified version)
class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;

  const AudioVisualizer({
    super.key,
    this.isPlaying = false,
    this.barCount = 20,
    this.height = 60,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + _random.nextInt(400)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.2,
        end: 0.3 + _random.nextDouble() * 0.7,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Start animations with random offsets
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: _random.nextInt(300)), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      for (var controller in _controllers) {
        if (widget.isPlaying) {
          controller.repeat(reverse: true);
        } else {
          controller.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: 4,
                height: widget.isPlaying
                    ? widget.height * _animations[index].value
                    : 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      ThemeConstants.primaryColor,
                      ThemeConstants.accentColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
