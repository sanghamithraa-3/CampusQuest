import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../theme/campus_theme.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    required this.achievement,
    this.actions = const [],
    this.showStudent = false,
    this.dense = false,
    super.key,
  });

  final Achievement achievement;
  final List<Widget> actions;
  final bool showStudent;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final date = achievement.date;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(dense ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: CampusColors.lavender,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: CampusColors.indigo,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${achievement.category}  ·  '
                        '${date.day.toString().padLeft(2, '0')} '
                        '${_month(date.month)} ${date.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (actions.isNotEmpty)
                  PopupMenuButton<String>(
                    tooltip: 'Achievement actions',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (value) {
                      final index = value == 'edit' ? 0 : 1;
                      if (index < actions.length &&
                          actions[index] is IconButton) {
                        (actions[index] as IconButton).onPressed?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (actions.isNotEmpty)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      if (actions.length > 1)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (showStudent && achievement.studentName != null) ...[
              const SizedBox(height: 10),
              Text(
                'Submitted by ${achievement.studentName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (achievement.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                achievement.description,
                maxLines: dense ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (achievement.certificateUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 17,
                    color: CampusColors.indigo,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SelectableText(
                      achievement.certificateUrl,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: CampusColors.indigo),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
