import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  /// Decimal number (prices).
  final bool isNumber;

  /// Whole number (quantities).
  final bool isInteger;
  final bool requiredField;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isNumber = false,
    this.isInteger = false,
    this.requiredField = false,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final numeric = isNumber || isInteger;

    return TextFormField(
      controller: controller,
      textInputAction: textInputAction ?? TextInputAction.next,
      keyboardType: isInteger
          ? TextInputType.number
          : isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textCapitalization: numeric
          ? TextCapitalization.none
          : TextCapitalization.words,
      inputFormatters: [
        if (isInteger) FilteringTextInputFormatter.digitsOnly,
        if (isNumber) FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (requiredField && text.isEmpty) {
          return 'Enter $label';
        }

        if (isInteger && text.isNotEmpty && int.tryParse(text) == null) {
          return 'Enter a whole number';
        }

        if (isNumber && text.isNotEmpty) {
          final number = double.tryParse(text);

          if (number == null || number < 0) {
            return 'Enter a valid amount';
          }
        }

        return null;
      },
    );
  }
}