import 'package:flutter/material.dart';
import 'package:zapac/dashboard/models/chat_message.dart';
import 'package:zapac/dashboard/models/user_interaction.dart';
import 'package:zapac/dashboard/time_utils.dart';

class InsightCard extends StatelessWidget {
  final ChatMessage message;
  final UserInteraction interaction;
  final bool isCurrentUserSender;
  final String? categoryLabel;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  const InsightCard({
    super.key,
    required this.message,
    required this.interaction,
    required this.isCurrentUserSender,
    this.categoryLabel,
    this.onLike,
    this.onDislike,
    this.onReport,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const iconSize = 20.0;
    final dividerColor = Theme.of(context).dividerColor;

    final timeDisplay = timeAgoSinceDate(message.createdAt);
    final hasImageUrl = message.imageUrl.isNotEmpty;
    final initials =
        message.sender.isNotEmpty ? message.sender[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    hasImageUrl ? Colors.transparent : colorScheme.primary,
                backgroundImage:
                    hasImageUrl ? NetworkImage(message.imageUrl) : null,
                child: hasImageUrl
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.sender,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (message.isMostHelpful)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6CA89A).withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '💡 Most Helpful',
                              style: TextStyle(
                                color: Color(0xFF6CA89A),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'report') {
                              onReport?.call();
                            } else if (value == 'delete') {
                              onDelete?.call();
                            }
                          },
                          itemBuilder: (context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('Report'),
                            ),
                            if (isCurrentUserSender)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                          icon: Icon(Icons.more_horiz, color: dividerColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Route: ${message.route}  |  $timeDisplay',
                      style: TextStyle(
                        color: textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    if (categoryLabel != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6CA89A).withAlpha(40),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          categoryLabel!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6CA89A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 61),
            child: Row(
              children: [
                InkWell(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        interaction.isLiked
                            ? Icons.thumb_up
                            : Icons.thumb_up_alt_outlined,
                        color:
                            interaction.isLiked ? Colors.blue : dividerColor,
                        size: iconSize,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.likes.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: onDislike,
                  child: Row(
                    children: [
                      Icon(
                        interaction.isDisliked
                            ? Icons.thumb_down
                            : Icons.thumb_down_alt_outlined,
                        color:
                            interaction.isDisliked ? Colors.red : dividerColor,
                        size: iconSize,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.dislikes.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}