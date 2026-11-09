import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';
import '../../widgets/activity_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/info_panel.dart';
import '../../widgets/page_header.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  String? _productId;
  final _quantity = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Product? _selected(List<Product> products) {
    for (final product in products) {
      if (product.id == _productId) return product;
    }
    return null;
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantity.text.trim());

    if (_productId == null || quantity == null || quantity <= 0) {
      _toast('Select a product and enter a valid quantity.');
      return;
    }

    setState(() => _saving = true);

    try {
      await SupabaseService.instance.addStock(_productId!, quantity);

      _quantity.clear();
      if (mounted) setState(() => _productId = null);
      _toast('Stock added.');
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SupabaseService.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final products = store.products;
        final selected = _selected(products);
        final quantity = int.tryParse(_quantity.text.trim()) ?? 0;
        final recent = store.movements
            .where((m) => m.type == 'STOCK_IN')
            .take(5)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PageHeader(
              title: 'Stock In',
              subtitle: 'Record goods received from your supplier.',
            ),
            if (products.isEmpty)
              const EmptyState(
                icon: Icons.move_to_inbox_outlined,
                title: 'No products to restock',
                message: 'Add a product first, then record stock you receive.',
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        // New key = the field resets after a save or when the
                        // selected product disappears.
                        key: ValueKey('stockin-${selected?.id}'),
                        initialValue: selected?.id,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Product'),
                        items: [
                          for (final p in products)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.name}  •  ${p.quantity} in stock',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _productId = value),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Quantity received',
                          prefixIcon: Icon(Icons.add_box_outlined),
                        ),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 16),
                        InfoPanel(
                          rows: [
                            ('In stock now', '${selected.quantity}'),
                            ('Cost per unit', Formatters.money(selected.costPrice)),
                            (
                              'New stock level',
                              '${selected.quantity + quantity}',
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(_saving ? 'Saving...' : 'Save stock in'),
                      ),
                    ],
                  ),
                ),
              ),
            if (recent.isNotEmpty) ...[
              const SectionTitle('Recently received'),
              ActivityCard(
                rows: [
                  for (final m in recent)
                    ActivityRow(
                      isSale: false,
                      title: m.productName,
                      subtitle:
                          '${m.quantity} units • ${Formatters.dayLabel(m.createdAt)}, ${Formatters.time(m.createdAt)}',
                      amount: Formatters.money(m.total),
                      amountNote: 'at cost',
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