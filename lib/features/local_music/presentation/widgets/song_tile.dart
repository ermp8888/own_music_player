import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/metadata_cleaner.dart';
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
        margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppTheme.primaryAccent.withOpacity(0.12)
              : AppTheme.backgroundCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppTheme.thumbnailRadius),
          border: Border.all(
            color: isPlaying
                ? AppTheme.primaryAccent.withOpacity(0.3)
                : AppTheme.divider.withOpacity(0.5),
          ),
          boxShadow: isPlaying ? [
            BoxShadow(
              color: AppTheme.primaryAccent.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            // Album art
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: isPlaying
                      ? [AppTheme.primaryAccent, AppTheme.primaryAccentLight]
                      : [AppTheme.backgroundCard, AppTheme.backgroundPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isPlaying ? AppTheme.activeShadow : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    color: isPlaying ? Colors.white : AppTheme.textSecondary,
                    size: 24,
                  ),
                  if (isPlaying)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
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
                    MetadataCleaner.cleanTitle(song.title),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isPlaying
                          ? AppTheme.primaryAccentLight
                          : AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          MetadataCleaner.cleanArtist(song.artist),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showDuration && song.duration > 0) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          Formatters.formatDuration(
                            Duration(milliseconds: song.duration),
                          ),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
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
                color: AppTheme.textSecondary,
                iconSize: 20,
              ),
          ],
        ),
      ),
    );
  }
}
