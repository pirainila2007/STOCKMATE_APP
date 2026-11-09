import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_header.dart';

enum _StockFilter { all, low }

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  _StockFilter _filter = _StockFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showForm([Product? product]) async {
    final result = await showDialog<_ProductFormResult>(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );

    if (result == null || !mounted) return;

    final store = SupabaseService.instance;

    try {
      if (product == null) {
        await store.addProduct(
          name: result.name,
          sku: result.sku,
          category: result.category,
          costPrice: result.costPrice,
          sellingPrice: result.sellingPrice,
          quantity: result.quantity,
          lowStockLimit: result.lowStockLimit,
        );
        _toast('${result.name} added.');
      } else {
        await store.updateProduct(
          product.copyWith(
            name: result.name,
            sku: result.sku,
            category: result.category,
            costPrice: result.costPrice,
            sellingPrice: result.sellingPrice,
            quantity: result.quantity,
            lowStockLimit: result.lowStockLimit,
          ),
        );
        _toast('Changes saved.');
      }
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          '${product.name} will be removed from your catalogue. '
          'Past sales and history are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.instance.deleteProduct(product.id);
      _toast('${product.name} deleted.');
    } catch (e) {
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SupabaseService.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final query = _search.text.trim().toLowerCase();
        final all = store.products;
        final lowCount = all.where((p) => p.isLowStock).length;

        final products = all.where((product) {
          final matches =
              query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              product.sku.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query);
          final passes = _filter == _StockFilter.all || product.isLowStock;
          return matches && passes;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add product'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              PageHeader(
                title: 'Products',
                subtitle: all.isEmpty
                    ? 'Your catalogue is empty.'
                    : '${all.length} ${all.length == 1 ? 'item' : 'items'} in your catalogue',
              ),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search by name, SKU or category',
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('All (${all.length})'),
                    selected: _filter == _StockFilter.all,
                    onSelected: (_) =>
                        setState(() => _filter = _StockFilter.all),
                  ),
                  ChoiceChip(
                    label: Text('Low stock ($lowCount)'),
                    selected: _filter == _StockFilter.low,
                    onSelected: (_) =>
                        setState(() => _filter = _StockFilter.low),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (all.isEmpty)
                EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products yet',
                  message: 'Add your first product to start tracking stock.',
                  actionLabel: 'Add product',
                  onAction: () => _showForm(),
                )
              else if (products.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching products',
                  message: 'Try a different word or switch the filter to All.',
                )
              else
                for (final product in products)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProductCard(
                      product: product,
                      onEdit: () => _showForm(product),
                      onDelete: () => _delete(product),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final statusColor = p.isOutOfStock
        ? AppColors.danger
        : p.isLowStock
        ? AppColors.warningText
        : AppColors.success;
    final statusLabel = p.isOutOfStock
        ? 'Out of stock'
        : p.isLowStock
        ? 'Low stock'
        : 'In stock';
    final name = p.name.trim();
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.inkSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.sku.isEmpty ? p.category : '${p.category} • SKU ${p.sku}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Sell ${Formatters.money(p.sellingPrice)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFeatures: AppTheme.tabular,
                          ),
                        ),
                        Text(
                          'Cost ${Formatters.money(p.costPrice)}',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontFeatures: AppTheme.tabular,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p.quantity}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 1.1,
                      fontFeatures: AppTheme.tabular,
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
                tooltip: 'More',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data returned from the add / edit dialog.
class _ProductFormResult {
  final String name;
  final String sku;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final int lowStockLimit;

  const _ProductFormResult({
    required this.name,
    required this.sku,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.lowStockLimit,
  });
}

/// The dialog's own State owns the controllers, so they are disposed only
/// after the dialog is fully gone (this avoids the `_dependents.isEmpty`
/// assertion that happens when controllers are disposed too early).
class _ProductFormDialog extends StatefulWidget {
  final Product? product;

  const _ProductFormDialog({this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _category;
  late final TextEditingController _cost;
  late final TextEditingController _selling;
  late final TextEditingController _quantity;
  late final TextEditingController _lowLimit;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _category = TextEditingController(text: p?.category ?? 'General');
    _cost = TextEditingController(text: p == null ? '' : '${p.costPrice}');
    _selling = TextEditingController(
      text: p == null ? '' : '${p.sellingPrice}',
    );
    _quantity = TextEditingController(text: p == null ? '0' : '${p.quantity}');
    _lowLimit = TextEditingController(
      text: p == null ? '5' : '${p.lowStockLimit}',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _category.dispose();
    _cost.dispose();
    _selling.dispose();
    _quantity.dispose();
    _lowLimit.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _ProductFormResult(
        name: _name.text.trim(),
        sku: _sku.text.trim(),
        category: _category.text.trim().isEmpty
            ? 'General'
            : _category.text.trim(),
        costPrice: double.parse(_cost.text.trim()),
        sellingPrice: double.parse(_selling.text.trim()),
        quantity: int.parse(_quantity.text.trim()),
        lowStockLimit: int.parse(_lowLimit.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;

    return AlertDialog(
      title: Text(editing ? 'Edit product' : 'Add product'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _name,
                  label: 'Product name',
                  requiredField: true,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(controller: _sku, label: 'SKU / code'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _category,
                        label: 'Category',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _cost,
                        label: 'Cost (LKR)',
                        isNumber: true,
                        requiredField: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _selling,
                        label: 'Selling (LKR)',
                        isNumber: true,
                        requiredField: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _quantity,
                        label: 'Quantity',
                        isInteger: true,
                        requiredField: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _lowLimit,
                        label: 'Low-stock limit',
                        isInteger: true,
                        requiredField: true,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _save,
          child: Text(editing ? 'Save changes' : 'Add product'),
        ),
      ],
    );
  }
}