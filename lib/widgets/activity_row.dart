import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// One line in a sales / stock movement list.
class ActivityRow extends StatelessWidget {
  final bool isSale;
  final String title;
  final String subtitle;
  final String amount;
  final String? amountNote;

  const ActivityRow({
    super.key,
    required this.isSale,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.amountNote,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSale ? AppColors.success : AppColors.ink;
    final background = isSale ? AppColors.successSoft : AppColors.inkSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSale ? Icons.north_east_rounded : Icons.south_west_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isSale ? AppColors.success : AppColors.text,
                  fontFeatures: AppTheme.tabular,
                ),
              ),
              if (amountNote != null)
                Text(
                  amountNote!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card that stacks [ActivityRow]s with dividers between them.
class ActivityCard extends StatelessWidget {
  final List<Widget> rows;

  const ActivityCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(),
            rows[i],
          ],
        ],
      ),
    );
  }
}