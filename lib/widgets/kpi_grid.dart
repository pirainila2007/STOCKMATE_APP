import 'package:flutter/material.dart';

/// Lays summary cards out in 2 columns on phones and 4 on wide screens.
class KpiGrid extends StatelessWidget {
  final List<Widget> children;

  const KpiGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth > 850 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}