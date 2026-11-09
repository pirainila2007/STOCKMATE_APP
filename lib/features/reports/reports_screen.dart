import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/sale.dart';
import '../../services/supabase_service.dart';
import '../../widgets/activity_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/kpi_grid.dart';
import '../../widgets/page_header.dart';
import '../../widgets/summary_card.dart';

enum _Period { today, week, month, all }

class _TopProduct {
  final String name;
  int units = 0;
  double revenue = 0;

  _TopProduct(this.name);
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Period _period = _Period.week;

  static const _labels = {
    _Period.today: 'Today',
    _Period.week: '7 days',
    _Period.month: '30 days',
    _Period.all: 'All time',
  };

  DateTime? _from() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (_period) {
      _Period.today => today,
      _Period.week => today.subtract(const Duration(days: 6)),
      _Period.month => today.subtract(const Duration(days: 29)),
      _Period.all => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = SupabaseService.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final from = _from();
        final allSales = store.sales;

        final sales = allSales.where((sale) {
          return from == null || !sale.createdAt.toLocal().isBefore(from);
        }).toList();

        final revenue = sales.fold<double>(0, (sum, sale) => sum + sale.total);

        final profit = sales.fold<double>(0, (sum, sale) => sum + sale.profit);

        final units = sales.fold<int>(0, (sum, sale) => sum + sale.quantity);

        final byProduct = <String, _TopProduct>{};

        for (final sale in sales) {
          final entry = byProduct.putIfAbsent(
            sale.productId,
            () => _TopProduct(sale.productName ?? 'Unknown product'),
          );

          entry.units += sale.quantity;
          entry.revenue += sale.total;
        }

        final top = byProduct.values.toList()
          ..sort((a, b) => b.revenue.compareTo(a.revenue));

        final costValue = store.stockCostValue;
        final retailValue = store.stockRetailValue;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PageHeader(
              title: 'Reports',
              subtitle: 'Sales performance and the value of your stock.',
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final period in _Period.values)
                  ChoiceChip(
                    label: Text(_labels[period]!),
                    selected: _period == period,
                    onSelected: (_) {
                      setState(() => _period = period);
                    },
                  ),
              ],
            ),

            const SizedBox(height: 16),

            KpiGrid(
              children: [
                SummaryCard(
                  title: 'Revenue',
                  value: Formatters.moneyShort(revenue),
                  icon: Icons.payments_outlined,
                  color: AppColors.ink,
                ),
                SummaryCard(
                  title: 'Profit',
                  value: Formatters.moneyShort(profit),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
                SummaryCard(
                  title: 'Units sold',
                  value: Formatters.number(units),
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.brassText,
                ),
                SummaryCard(
                  title: 'Number of sales',
                  value: '${sales.length}',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.muted,
                ),
              ],
            ),

            const SectionTitle('Last 7 days'),
            _WeekChart(sales: allSales),

            const SectionTitle('Top products'),

            if (top.isEmpty)
              const EmptyState(
                icon: Icons.insights_outlined,
                title: 'No sales in this period',
                message:
                    'Record a sale and your best sellers will '
                    'show up here.',
              )
            else
              _TopProductsCard(items: top.take(5).toList()),

            const SectionTitle('Stock value'),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _ValueLine('At cost price', Formatters.money(costValue)),
                    const SizedBox(height: 10),
                    _ValueLine(
                      'At selling price',
                      Formatters.money(retailValue),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    _ValueLine(
                      'Potential profit',
                      Formatters.money(retailValue - costValue),
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),

            if (sales.isNotEmpty) ...[
              const SectionTitle('Sales in this period'),

              ActivityCard(
                rows: [
                  for (final Sale sale in sales.take(15))
                    ActivityRow(
                      isSale: true,
                      title: sale.productName ?? 'Unknown product',
                      subtitle:
                          '${sale.quantity} units • '
                          '${Formatters.dayLabel(sale.createdAt)}, '
                          '${Formatters.time(sale.createdAt)}',
                      amount: Formatters.money(sale.total),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ValueLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _ValueLine(this.label, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: strong ? AppColors.text : AppColors.muted,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: strong ? 18 : 15,
              color: strong ? AppColors.success : AppColors.text,
              fontFeatures: AppTheme.tabular,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<_TopProduct> items;

  const _TopProductsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final best = items.first.revenue <= 0 ? 1.0 : items.first.revenue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      items[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Formatters.money(items[i].revenue),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFeatures: AppTheme.tabular,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                '${items[i].units} units sold',
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (items[i].revenue / best).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.inkSoft,
                  color: i == 0 ? AppColors.ink : AppColors.brass,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Seven bars, one per day, ending today.
class _WeekChart extends StatelessWidget {
  final List<Sale> sales;

  const _WeekChart({required this.sales});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    final totals = [
      for (final day in days)
        sales
            .where((sale) {
              final date = sale.createdAt.toLocal();

              return date.year == day.year &&
                  date.month == day.month &&
                  date.day == day.day;
            })
            .fold<double>(0, (sum, sale) => sum + sale.total),
    ];

    final maxTotal = totals.fold<double>(
      0,
      (maximum, value) => value > maximum ? value : maximum,
    );
const chartHeight = 116.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Formatters.money(
                totals.fold<double>(0, (sum, value) => sum + value),
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFeatures: AppTheme.tabular,
              ),
            ),

            const Text(
              'sold in the last 7 days',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: chartHeight + 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${Formatters.dayLabel(days[i])}: '
                            '${Formatters.money(totals[i])}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: maxTotal <= 0
                                  ? 4
                                  : (totals[i] / maxTotal * chartHeight).clamp(
                                      4.0,
                                      chartHeight,
                                    ),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: i == days.length - 1
                                    ? AppColors.ink
                                    : AppColors.inkSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              Formatters.weekday(days[i]),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: i == days.length - 1
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: i == days.length - 1
                                    ? AppColors.ink
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
