import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuestionCountInputRow extends StatelessWidget {
  const QuestionCountInputRow({
    super.key,
    required this.label,
    required this.helperText,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String label;
  final String helperText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocused = focusNode.hasFocus;
    final controls = _CountControls(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onIncrement: onIncrement,
      onDecrement: onDecrement,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFocused
              ? theme.colorScheme.primary
              : const Color(0xFFD0D5DD),
          width: isFocused ? 1.4 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useStackedLayout = constraints.maxWidth < 360;
          if (useStackedLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleMedium, softWrap: true),
                const SizedBox(height: 4),
                Text(helperText, style: theme.textTheme.bodySmall, softWrap: true),
                const SizedBox(height: 12),
                controls,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleMedium, softWrap: true),
                    const SizedBox(height: 4),
                    Text(helperText, style: theme.textTheme.bodySmall, softWrap: true),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class _CountControls extends StatelessWidget {
  const _CountControls({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 188, minWidth: 168),
      child: Row(
        children: [
          _CountButton(
            icon: Icons.remove_rounded,
            onPressed: onDecrement,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;
                  if (text.isEmpty || RegExp(r'^-?\d+$').hasMatch(text)) {
                    return newValue;
                  }
                  return oldValue;
                }),
              ],
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
              onChanged: onChanged,
              onSubmitted: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          _CountButton(
            icon: Icons.add_rounded,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
