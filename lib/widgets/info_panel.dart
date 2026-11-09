import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Tinted summary box. The last row is emphasised.
class InfoPanel extends StatelessWidget {
  final List<(String, String)> rows;

  const InfoPanel({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inkSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: i == rows.length - 1 ? 19 : 15,
                        fontFeatures: AppTheme.tabular,
                      ),
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