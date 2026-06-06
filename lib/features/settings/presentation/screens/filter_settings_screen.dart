import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/providers/filter_settings_provider.dart';
import '../../../../shared/widgets/gradient_background.dart';

/// Screen for managing content filtering options.
class FilterSettingsScreen extends ConsumerWidget {
  const FilterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(filterSettingsProvider);
    final notifier = ref.read(filterSettingsProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Content Filtering',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Header description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Shield',
                      style: TextStyle(
                        color: ThemeConstants.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0.0),
                    const SizedBox(height: 6),
                    Text(
                      'Automatically hide unwanted, low-quality, or non-mainstream content from your library and downloads.',
                      style: TextStyle(
                        color: ThemeConstants.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter tiles
              _buildFilterGroup(
                title: 'Default Filters (Highly Recommended)',
                children: [
                  _buildSwitchTile(
                    icon: Icons.brightness_high_rounded,
                    title: 'Block Devotional Content',
                    subtitle: 'Hide Bhajans, Aartis, Mantras, and religious tracks.',
                    value: settings.blockDevotional,
                    onChanged: (val) => notifier.toggleDevotional(val),
                  ),
                  _buildSwitchTile(
                    icon: Icons.mic_external_off_rounded,
                    title: 'Block Karaoke & Covers',
                    subtitle: 'Hide karaoke backing tracks and amateur vocal covers.',
                    value: settings.blockKaraoke,
                    onChanged: (val) => notifier.toggleKaraoke(val),
                  ),
                  _buildSwitchTile(
                    icon: Icons.hourglass_bottom_rounded,
                    title: 'Block Shorts & Clips',
                    subtitle: 'Hide short audio clips and video shorts under 1 minute.',
                    value: settings.blockShorts,
                    onChanged: (val) => notifier.toggleShorts(val),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0.0),

              const SizedBox(height: 20),

              _buildFilterGroup(
                title: 'Optional Filters',
                children: [
                  _buildSwitchTile(
                    icon: Icons.library_music_rounded,
                    title: 'Block Remixes',
                    subtitle: 'Hide unofficial remixes, speed-up, and slowed versions.',
                    value: settings.blockRemixes,
                    onChanged: (val) => notifier.toggleRemixes(val),
                  ),
                  _buildSwitchTile(
                    icon: Icons.piano_off_rounded,
                    title: 'Block Instrumentals',
                    subtitle: 'Hide BGM tracks, theme music, and instrumental covers.',
                    value: settings.blockInstrumentals,
                    onChanged: (val) => notifier.toggleInstrumentals(val),
                  ),
                ],
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, end: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
        Card(
          color: ThemeConstants.cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: ThemeConstants.cardColorLight.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ThemeConstants.cardColorLight.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeConstants.cardColorLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: value ? ThemeConstants.primaryColor : ThemeConstants.textMuted,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: ThemeConstants.textMuted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          activeColor: ThemeConstants.primaryColor,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
