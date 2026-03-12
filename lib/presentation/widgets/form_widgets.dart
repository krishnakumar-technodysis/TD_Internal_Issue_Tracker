// lib/presentation/widgets/form_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────
// Character limits — single source of truth
// ─────────────────────────────────────────────────────────
class FieldLimits {
  static const int processName  = 80;
  static const int summary      = 300;
  static const int actionTaken  = 1000;
  static const int assignedTo   = 60;
}

// ─────────────────────────────────────────────────────────
// TField  — text input with optional char counter
// ─────────────────────────────────────────────────────────
class TField extends StatefulWidget {
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
  final int? maxLength;        // shows counter when set
  final bool isRequired;       // appends * to label
  final FocusNode? focusNode;

  const TField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.readOnly = false,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.maxLength,
    this.isRequired = false,
    this.focusNode,
  });

  @override
  State<TField> createState() => _TFieldState();
}

class _TFieldState extends State<TField> {
  int _len = 0;

  @override
  void initState() {
    super.initState();
    _len = widget.controller?.text.length ?? 0;
    widget.controller?.addListener(_update);
  }

  void _update() => setState(() => _len = widget.controller?.text.length ?? 0);

  @override
  void dispose() {
    widget.controller?.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCounter = widget.maxLength != null && !widget.readOnly;
    final nearLimit  = hasCounter && _len >= (widget.maxLength! * 0.85).floor();
    final atLimit    = hasCounter && _len >= widget.maxLength!;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Label row
      Row(children: [
        RichText(text: TextSpan(
          text: widget.label.toUpperCase(),
          style: const TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w700,
              color: AppTheme.textMuted, letterSpacing: 0.7,
              fontFamily: 'DMSans'),
          children: widget.isRequired
              ? [const TextSpan(
              text: ' *',
              style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700))]
              : [],
        )),
        if (hasCounter) ...[
          const Spacer(),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: atLimit
                  ? AppTheme.red
                  : nearLimit
                  ? AppTheme.orange
                  : AppTheme.textDim,
            ),
            child: Text('$_len / ${widget.maxLength}'),
          ),
        ],
      ]),
      const SizedBox(height: 6),
      TextFormField(
        controller: widget.controller,
        maxLines: widget.maxLines,
        minLines: widget.maxLines > 1 ? (widget.maxLines < 3 ? widget.maxLines : 3) : null,
        readOnly: widget.readOnly,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        focusNode: widget.focusNode,
        inputFormatters: widget.maxLength != null
            ? [LengthLimitingTextInputFormatter(widget.maxLength)]
            : null,
        onChanged: (v) {
          setState(() => _len = v.length);
          widget.onChanged?.call(v);
        },
        style: TextStyle(
          fontSize: 13.5,
          color: widget.readOnly ? AppTheme.textMuted : AppTheme.textColor,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixIcon: widget.suffixIcon,
          prefixIcon: widget.prefixIcon,
          filled: true,
          fillColor: widget.readOnly
              ? AppTheme.cardAlt.withOpacity(0.6)
              : AppTheme.cardAlt,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.red)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.red, width: 1.5)),
          hintStyle: const TextStyle(
              color: AppTheme.textDim, fontSize: 13),
        ),
      ),
      // Limit hint below textarea
      if (widget.maxLength != null && widget.maxLines > 1) ...[
        const SizedBox(height: 4),
        Text(
          'Max ${widget.maxLength} characters',
          style: const TextStyle(fontSize: 10.5, color: AppTheme.textDim),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────
// TDropdown
// ─────────────────────────────────────────────────────────
class TDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final List<String>? displayItems; // optional display labels (parallel to items)
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;
  final bool isRequired;
  final String? hint;

  const TDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.displayItems,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(text: TextSpan(
        text: label.toUpperCase(),
        style: const TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w700,
            color: AppTheme.textMuted, letterSpacing: 0.7,
            fontFamily: 'DMSans'),
        children: isRequired
            ? [const TextSpan(
            text: ' *',
            style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700))]
            : [],
      )),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        dropdownColor: AppTheme.card,
        style: const TextStyle(fontSize: 13.5, color: AppTheme.textColor),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textDim, size: 18),
        items: items.asMap().entries.map((e) {
          final display = (displayItems != null && displayItems!.length > e.key)
              ? displayItems![e.key] : e.value;
          return DropdownMenuItem(
              value: e.value,
              child: Text(display, style: const TextStyle(
                  fontSize: 13.5, color: AppTheme.textColor)));
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.cardAlt,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderLight)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.red)),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────
// TDatePicker
// ─────────────────────────────────────────────────────────
class TDatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final void Function(DateTime?) onChanged;
  final bool isRequired;
  final DateTime? firstDate; // optional override; defaults to today

  const TDatePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final earliest = firstDate ?? DateTime(today.year, today.month, today.day);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(text: TextSpan(
        text: label.toUpperCase(),
        style: const TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w700,
            color: AppTheme.textMuted, letterSpacing: 0.7,
            fontFamily: 'DMSans'),
        children: isRequired
            ? [const TextSpan(
            text: ' *',
            style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700))]
            : [],
      )),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () async {
          // If current value is before today, reset initialDate to today
          final initial = (value != null && !value!.isBefore(earliest))
              ? value!
              : earliest;
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: earliest,
            lastDate: DateTime(2035),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppTheme.accent,
                  onPrimary: Colors.white,
                  surface: AppTheme.card,
                  onSurface: AppTheme.textColor,
                ),
                dialogBackgroundColor: AppTheme.card,
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
            color: AppTheme.cardAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 15,
                color: value != null ? AppTheme.accent : AppTheme.textDim),
            const SizedBox(width: 8),
            Text(
              value != null
                  ? DateFormat('dd MMM yyyy').format(value!)
                  : 'Select date',
              style: TextStyle(
                  fontSize: 13.5,
                  color: value != null ? AppTheme.textColor : AppTheme.textDim),
            ),
            const Spacer(),
            if (value != null)
              GestureDetector(
                  onTap: () => onChanged(null),
                  child: const Icon(Icons.close_rounded,
                      size: 15, color: AppTheme.textDim)),
          ]),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────
// FormSection  — card wrapper with title + optional footer
// ─────────────────────────────────────────────────────────
class FormSection extends StatelessWidget {
  final String title;
  final String emoji;
  final Widget child;
  final Widget? footer;

  const FormSection({
    super.key,
    required this.title,
    required this.emoji,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppTheme.textColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppTheme.border),
        Padding(padding: const EdgeInsets.all(20), child: child),
        if (footer != null) ...[
          const Divider(height: 1, color: AppTheme.border),
          footer!,
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Responsive row helper
// ─────────────────────────────────────────────────────────
class FormRow extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final double gap;

  const FormRow({
    super.key,
    required this.children,
    this.breakpoint = 520,
    this.gap = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      if (box.maxWidth >= breakpoint) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.expand((w) sync* {
            if (w != children.first) yield SizedBox(width: gap);
            yield Expanded(child: w);
          }).toList(),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.expand((w) sync* {
          if (w != children.first) yield SizedBox(height: gap);
          yield w;
        }).toList(),
      );
    });
  }
}