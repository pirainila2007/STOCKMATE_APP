import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/stock_movement.dart';
import '../../services/supabase_service.dart';
import '../../widgets/activity_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_header.dart';

enum _HistoryFilter { all, sales, stockIn }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final store = SupabaseService.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.movements;

        final items = all.where((m) {
          return switch (_filter) {
            _HistoryFilter.all => true,
            _HistoryFilter.sales => m.type == 'SALE',
            _HistoryFilter.stockIn => m.type == 'STOCK_IN',
          };
        }).toList();

        // Newest first, grouped by day.
        final groups = <String, List<StockMovement>>{};
        for (final movement in items) {
          groups
              .putIfAbsent(Formatters.dayLabel(movement.createdAt), () => [])
              .add(movement);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PageHeader(
              title: 'Stock History',
              subtitle: 'Every sale and every delivery, newest first.',
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == _HistoryFilter.all,
                  onSelected: (_) => setState(() => _filter = _HistoryFilter.all),
                ),
                ChoiceChip(
                  label: const Text('Sales'),
                  selected: _filter == _HistoryFilter.sales,
                  onSelected: (_) =>
                      setState(() => _filter = _HistoryFilter.sales),
                ),
                ChoiceChip(
                  label: const Text('Stock in'),
                  selected: _filter == _HistoryFilter.stockIn,
                  onSelected: (_) =>
                      setState(() => _filter = _HistoryFilter.stockIn),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              EmptyState(
                icon: Icons.history_rounded,
                title: all.isEmpty ? 'No activity yet' : 'Nothing here',
                message: all.isEmpty
                    ? 'Sales and stock-in entries will appear here as you record them.'
                    : 'No entries match this filter.',
              ),
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              ActivityCard(
                rows: [
                  for (final m in entry.value)
                    ActivityRow(
                      isSale: m.type == 'SALE',
                      title: m.productName,
                      subtitle:
                          '${m.type == 'SALE' ? 'Sale' : 'Stock in'} • ${m.quantity} units • ${Formatters.time(m.createdAt)}',
                      amount: Formatters.money(m.total),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}