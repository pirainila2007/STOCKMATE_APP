import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const PageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final subtitleWidgets = subtitle == null
        ? null
        : <Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          ...?subtitleWidgets,
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
