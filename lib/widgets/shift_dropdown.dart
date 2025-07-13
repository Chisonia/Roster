import 'package:flutter/material.dart';

class ShiftDropdown extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const ShiftDropdown({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedValue,
      items: ['Morning', 'Night']
          .map((shift) => DropdownMenuItem<String>(
        value: shift,
        child: Text(shift),
      ))
          .toList(),
      onChanged: (String? value) {
        if (value != null) {
          onChanged(value); // safely call the non-null handler
        }
      },
    );
  }
}
