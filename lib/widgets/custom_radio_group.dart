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
      children: items.map((item) {
        final isSelected = groupValue == item.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: double.infinity, // Full width
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 12,
                ),
                backgroundColor: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15) // ✅ fixed
                    : null,
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  width: 2,
                ),
              ),
              onPressed: () => onChanged(item.value),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
