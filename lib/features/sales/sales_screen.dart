
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';
import '../../widgets/activity_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/info_panel.dart';
import '../../widgets/page_header.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
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
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Product? _selected(List<Product> products) {
    for (final product in products) {
      if (product.id == _productId) {
        return product;
      }
    }

    return null;
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantity.text.trim());

    if (_productId == null || quantity == null || quantity <= 0) {
      _toast('Select a product and enter a valid quantity.');
      return;
    }

    final selectedProduct =
        SupabaseService.instance.findProduct(_productId!);

    if (selectedProduct == null) {
      _toast('Selected product was not found.');
      return;
    }

    if (quantity > selectedProduct.quantity) {
      _toast('Not enough stock available.');
      return;
    }

    setState(() => _saving = true);

    try {
      final store = SupabaseService.instance;
      final price = selectedProduct.sellingPrice;

      await store.recordSale(_productId!, quantity);

      _quantity.clear();

      if (mounted) {
        setState(() => _productId = null);
      }

      _toast(
        'Sale recorded: ${Formatters.money(price * quantity)}',
      );
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
        final available = selected?.quantity ?? 0;
        final tooMany =
            selected != null && quantity > available;
        final recent = store.sales.take(5).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PageHeader(
              title: 'Sales',
              subtitle:
                  'Record a sale. Stock is reduced automatically.',
            ),

            if (products.isEmpty)
              const EmptyState(
                icon: Icons.point_of_sale_outlined,
                title: 'Nothing to sell yet',
                message:
                    'Add a product first, then record sales here.',
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey('sales-${selected?.id}'),
                        initialValue: selected?.id,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Product',
                        ),
                        items: [
                          for (final product in products)
                            DropdownMenuItem<String>(
                              value: product.id,
                              enabled: product.quantity > 0,
                              child: Text(
                                '${product.name} • '
                                '${product.quantity} available',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  _productId = value;
                                });
                              },
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Quantity sold',
                          prefixIcon: const Icon(
                            Icons.shopping_cart_outlined,
                          ),
                          errorText: tooMany
                              ? 'Only $available available'
                              : null,
                        ),
                      ),

                      if (selected != null) ...[
                        const SizedBox(height: 16),
                        InfoPanel(
                          rows: [
                            (
                              'Unit price',
                              Formatters.money(
                                selected.sellingPrice,
                              ),
                            ),
                            (
                              'Available',
                              '${selected.quantity}',
                            ),
                            (
                              'Sale total',
                              Formatters.money(
                                selected.sellingPrice * quantity,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      FilledButton.icon(
                        onPressed: _saving ||
                                tooMany ||
                                selected == null ||
                                quantity <= 0
                            ? null
                            : _save,
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                        ),
                        label: Text(
                          _saving ? 'Saving...' : 'Record sale',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (recent.isNotEmpty) ...[
              const SectionTitle('Recent sales'),
              ActivityCard(
                rows: [
                  for (final sale in recent)
                    ActivityRow(
                      isSale: true,
                      title:
                          sale.productName ?? 'Unknown product',
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
