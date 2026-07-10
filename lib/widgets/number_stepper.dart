import 'package:flutter/material.dart';

class NumberStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final double size;

  const NumberStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(
          context,
          Icons.remove,
          value > min,
          () => onChanged(value - 1),
          scheme,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        _btn(
          context,
          Icons.add,
          value < max,
          () => onChanged(value + 1),
          scheme,
        ),
      ],
    );
  }

  Widget _btn(
    BuildContext context,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
    ColorScheme scheme,
  ) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: enabled ? scheme.onPrimaryContainer : scheme.outline,
        ),
      ),
    );
  }
}
