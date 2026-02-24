// lib/presentation/widgets/form_widgets.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class TField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final bool readOnly;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;

  const TField({
    super.key, required this.label,
    this.controller, this.hint, this.maxLines = 1,
    this.readOnly = false, this.validator,
    this.keyboardType, this.obscureText = false,
    this.suffixIcon, this.prefixIcon, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w600,
          color: AppTheme.textMuted, letterSpacing: 0.6)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13.5, color: AppTheme.textColor),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
        ),
      ),
    ]);
  }
}

class TDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const TDropdown({
    super.key, required this.label,
    required this.value, required this.items,
    required this.onChanged, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w600,
          color: AppTheme.textMuted, letterSpacing: 0.6)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        dropdownColor: AppTheme.inkSoft,
        style: const TextStyle(fontSize: 13.5, color: AppTheme.textColor),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppTheme.textDim, size: 18),
        items: items.map((i) => DropdownMenuItem(
          value: i,
          child: Text(i, style: const TextStyle(fontSize: 13.5)),
        )).toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(),
      ),
    ]);
  }
}

class TDatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final void Function(DateTime?) onChanged;

  const TDatePicker({
    super.key, required this.label,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w600,
          color: AppTheme.textMuted, letterSpacing: 0.6)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.accent, onPrimary: AppTheme.ink,
                  surface: AppTheme.inkSoft,
                ),
              ),
              child: child!,
            ),
          );
          onChanged(picked);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.inkSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
              size: 15, color: AppTheme.textDim),
            const SizedBox(width: 8),
            Text(
              value != null
                  ? DateFormat('dd MMM yyyy').format(value!)
                  : 'Select date',
              style: TextStyle(
                fontSize: 13.5,
                color: value != null ? AppTheme.textColor : AppTheme.textDim)),
            const Spacer(),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close, size: 15, color: AppTheme.textDim)),
          ]),
        ),
      ),
    ]);
  }
}

class FormSection extends StatelessWidget {
  final String title;
  final String emoji;
  final Widget child;
  final Widget? footer;

  const FormSection({
    super.key, required this.title, required this.emoji,
    required this.child, this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(title,
              style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600,
                color: AppTheme.textColor)),
          ]),
        ),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.all(20), child: child),
        if (footer != null) ...[
          const Divider(height: 1),
          footer!,
        ],
      ]),
    );
  }
}
