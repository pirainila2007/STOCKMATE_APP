import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';
import '../../widgets/activity_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/kpi_grid.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/summary_card.dart';
import '../history/history_screen.dart';
import '../products/products_screen.dart';
import '../reports/reports_screen.dart';
import '../sales/sales_screen.dart';
import '../stock_in/stock_in_screen.dart';

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _Destination(this.label, this.icon, this.selectedIcon);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  static const _destinations = [
    _Destination('Home', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
    _Destination('Products', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
    _Destination('Stock In', Icons.move_to_inbox_outlined, Icons.move_to_inbox_rounded),
    _Destination('Sales', Icons.point_of_sale_outlined, Icons.point_of_sale_rounded),
    _Destination('Reports', Icons.insights_outlined, Icons.insights_rounded),
    _Destination('History', Icons.history_rounded, Icons.history_rounded),
  ];

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final pages = <Widget>[
      _DashboardBody(onNavigate: _go),
      const ProductsScreen(),
      const StockInScreen(),
      const SalesScreen(),
      const ReportsScreen(),
      const HistoryScreen(),
    ];

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: IndexedStack(
          index: _index,
          sizing: StackFit.expand,
          children: pages,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const _Brand(),
        actions: const [_SyncBadge(), SizedBox(width: 12)],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _go,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _go,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            size: 18,
            color: AppColors.brassSoft,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
      ],
    );
  }
}

/// Shows where the data lives and lets the owner retry the cloud connection.
class _SyncBadge extends StatelessWidget {
  const _SyncBadge();

  @override
  Widget build(BuildContext context) {
    final store = SupabaseService.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        late final IconData icon;
        late final String label;
        late final Color color;
        late final String tip;

        if (!store.cloudEnabled) {
          icon = Icons.cloud_off_outlined;
          label = 'This device';
          color = AppColors.muted;
          tip = 'Saved on this device only. Add Supabase keys to sync devices.';
        } else if (store.syncing) {
          icon = Icons.cloud_sync_outlined;
          label = 'Syncing';
          color = AppColors.muted;
          tip = 'Syncing with the cloud...';
        } else if (store.cloudReady && store.syncError == null) {
          icon = Icons.cloud_done_outlined;
          label = 'Synced';
          color = AppColors.success;
          tip = 'All changes are saved to the cloud. Tap to refresh.';
        } else {
          icon = Icons.cloud_off_outlined;
          label = 'Offline';
          color = AppColors.danger;
          tip = 'Cloud not reachable. Tap to retry.';
        }

        return Tooltip(
          message: tip,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: store.cloudEnabled ? store.refresh : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _DashboardBody({required this.onNavigate});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final store = SupabaseService.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final products = store.products;
        final low = store.lowStockProducts;
        final recent = store.movements.take(5).toList();

        return RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              PageHeader(
                title: 'Shop Overview',
                subtitle: '${_greeting()}. Here is how the shop is doing.',
              ),
              _TodayHero(
                onSale: () => onNavigate(3),
                onStockIn: () => onNavigate(2),
              ),
              const SizedBox(height: 16),
              KpiGrid(
                children: [
                  SummaryCard(
                    title: 'Total Products',
                    value: '${products.length}',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.ink,
                  ),
                  SummaryCard(
                    title: 'Stock Units',
                    value: Formatters.number(store.stockUnits),
                    icon: Icons.warehouse_outlined,
                    color: AppColors.success,
                  ),
                  SummaryCard(
                    title: 'Stock value (cost)',
                    value: Formatters.moneyShort(store.stockCostValue),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.brassText,
                  ),
                  SummaryCard(
                    title: 'Low Stock',
                    value: '${low.length}',
                    icon: Icons.warning_amber_rounded,
                    color: low.isEmpty ? AppColors.success : AppColors.danger,
                  ),
                ],
              ),
              if (products.isEmpty) ...[
                const SectionTitle('Get started'),
                EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Add your first product',
                  message:
                      'List what you stock, then record sales to see your numbers here.',
                  actionLabel: 'Add product',
                  onAction: () => onNavigate(1),
                ),
              ] else ...[
                const SectionTitle('Needs restocking'),
                if (low.isEmpty)
                  const _AllStocked()
                else
                  _LowStockCard(
                    items: low.take(6).toList(),
                    onTap: () => onNavigate(2),
                  ),
              ],
              if (recent.isNotEmpty) ...[
                SectionTitle(
                  'Recent activity',
                  trailing: TextButton(
                    onPressed: () => onNavigate(5),
                    child: const Text('View all'),
                  ),
                ),
                ActivityCard(
                  rows: [
                    for (final m in recent)
                      ActivityRow(
                        isSale: m.type == 'SALE',
                        title: m.productName,
                        subtitle:
                            '${m.type == 'SALE' ? 'Sold' : 'Received'} ${m.quantity} • ${Formatters.dayLabel(m.createdAt)}, ${Formatters.time(m.createdAt)}',
                        amount: Formatters.money(m.total),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TodayHero extends StatelessWidget {
  final VoidCallback onSale;
  final VoidCallback onStockIn;

  const _TodayHero({required this.onSale, required this.onStockIn});

  @override
  Widget build(BuildContext context) {
    final store = SupabaseService.instance;
    final count = store.todaySalesCount;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.inkDeep,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's sales",
            style: TextStyle(
              color: Color(0xB3FFFFFF),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.money(store.todayRevenue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                fontFeatures: AppTheme.tabular,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count == 0
                ? 'No sales recorded yet today.'
                : '$count ${count == 1 ? 'sale' : 'sales'} • ${store.todayUnits} units • profit ${Formatters.moneyShort(store.todayProfit)}',
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSale,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brass,
                    foregroundColor: AppColors.inkDeep,
                  ),
                  icon: const Icon(Icons.point_of_sale_rounded, size: 20),
                  label: const Text('Record sale'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStockIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x59FFFFFF)),
                  ),
                  icon: const Icon(Icons.move_to_inbox_rounded, size: 20),
                  label: const Text('Stock in'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllStocked extends StatelessWidget {
  const _AllStocked();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Every product is above its low-stock limit.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final List<Product> items;
  final VoidCallback onTap;

  const _LowStockCard({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(),
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].sku.isEmpty
                                ? 'Limit ${items[i].lowStockLimit}'
                                : 'SKU ${items[i].sku} • Limit ${items[i].lowStockLimit}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (items[i].isOutOfStock)
                      const StatusPill(
                        label: 'Out of stock',
                        color: AppColors.danger,
                        background: AppColors.dangerSoft,
                      )
                    else
                      StatusPill(
                        label: '${items[i].quantity} left',
                        color: AppColors.warningText,
                        background: AppColors.warningSoft,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}