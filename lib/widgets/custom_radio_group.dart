import 'package:flutter/material.dart';

class RadioItem<T> {
  final T value;
  final String label;
  const RadioItem({required this.value, required this.label});
}

class CustomRadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final List<RadioItem<T>> items;
  final ValueChanged<T> onChanged;

  const CustomRadioGroup({
    super.key,
    required this.groupValue,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (it) => RadioListTile<T>(
              title: Text(it.label),
              value: it.value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
            ),
          )
          .toList(),
    );
  }
}
