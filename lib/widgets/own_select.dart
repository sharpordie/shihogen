import 'package:flutter/material.dart';

class OwnSelect extends StatelessWidget {
  const OwnSelect({
    required this.items,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<DropdownMenuItem<Object>>? items;
  final Object? value;
  final Function(Object?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      items: items,
      value: value,
      onChanged: onChanged,
      dropdownColor: Theme.of(context).colorScheme.onSecondary,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
        // contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      ),
    );
  }
}
