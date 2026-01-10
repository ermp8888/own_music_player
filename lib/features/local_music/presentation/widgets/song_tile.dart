import 'package:flutter/material.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/scale_tap_animation.dart';

/// Song tile widget for list display
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool isPlaying;
  final bool showDuration;
  final Widget? trailing;

  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onMoreTap,
    this.isPlaying = false,
    this.showDuration = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTapAnimation(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPlaying
              ? ThemeConstants.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Album art
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: isPlaying
                    ? ThemeConstants.primaryGradient
                    : ThemeConstants.cardGradient,
                boxShadow: isPlaying ? ThemeConstants.glowShadow : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    color: isPlaying ? Colors.white : ThemeConstants.textMuted,
                    size: 24,
                  ),
                  if (isPlaying)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.equalizer_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isPlaying
                          ? ThemeConstants.primaryColor
                          : ThemeConstants.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          song.artist,
                          style: TextStyle(
                            color: ThemeConstants.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showDuration && song.duration > 0) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: ThemeConstants.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          Formatters.formatDuration(
                            Duration(milliseconds: song.duration),
                          ),
                          style: TextStyle(
                            color: ThemeConstants.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Trailing widget or more button
            if (trailing != null)
              trailing!
            else
              IconButton(
                onPressed: onMoreTap,
                icon: const Icon(Icons.more_vert_rounded),
                color: ThemeConstants.textMuted,
                iconSize: 20,
              ),
          ],
        ),
      ),
    );
  }
}
