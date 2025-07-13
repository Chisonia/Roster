import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumber;
  final VoidCallback? onChanged;

  const InputField({
    super.key,
    required this.controller,
    required this.label,
    this.isNumber = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => onChanged?.call(),
    );
  }
}
