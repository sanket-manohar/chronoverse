import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/chrono_format.dart';
import '../core/date_availability.dart';
import '../core/date_extensions.dart';
import '../core/natural_date.dart';
import '../l10n/chrono_locale.dart';
import 'dialogs.dart';
import 'theme.dart';

/// Inserts the separators of a numeric date pattern while typing, so
/// `25122026` becomes `25/12/2026` for `dd/MM/yyyy`.
class ChronoDateMaskFormatter extends TextInputFormatter {
  /// Creates a formatter for an all-numeric [pattern].
  ChronoDateMaskFormatter(this.pattern);

  /// Pattern such as `dd/MM/yyyy` or `yyyy-MM-dd`.
  final String pattern;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Deleting: leave the text alone so separators can be removed naturally.
    if (newValue.text.length < oldValue.text.length) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final out = StringBuffer();
    var di = 0;
    for (var i = 0; i < pattern.length && di < digits.length; i++) {
      final c = pattern[i];
      if ('yMdHhms'.contains(c)) {
        out.write(digits[di++]);
      } else {
        out.write(c);
      }
    }
    // Add the next separator right away for a smoother feel.
    var text = out.toString();
    if (text.length < pattern.length && !'yMdHhms'.contains(pattern[text.length])) {
      text += pattern[text.length];
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// A text field for dates that people can type or pick.
///
/// * Numeric patterns get an automatic mask (`25/12/2026`).
/// * With [allowNaturalLanguage], typing "tomorrow", "next fri" or
///   "25 dec" also works; the text is normalised when the field loses focus.
/// * Invalid, impossible (31/02) and out-of-range dates show an error.
/// * The calendar button opens [showChronoDatePicker].
class ChronoDateField extends StatefulWidget {
  /// Creates a date field.
  const ChronoDateField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.pattern,
    this.firstDate,
    this.lastDate,
    this.availability,
    this.allowNaturalLanguage = true,
    this.showPickerButton = true,
    this.pickerPresentation = ChronoPresentation.dialog,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.decoration,
    this.locale,
    this.theme,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  /// Starting value.
  final DateTime? initialValue;

  /// Called with each valid date (or null when cleared).
  final ValueChanged<DateTime?>? onChanged;

  /// Display/input pattern (defaults to the locale's, e.g. `dd/MM/yyyy`).
  final String? pattern;

  /// Earliest allowed date.
  final DateTime? firstDate;

  /// Latest allowed date.
  final DateTime? lastDate;

  /// Blocked days.
  final DateAvailability? availability;

  /// Understand "tomorrow", "next friday", "in 3 days", "25 dec".
  final bool allowNaturalLanguage;

  /// Show the calendar button.
  final bool showPickerButton;

  /// How the picker opens.
  final ChronoPresentation pickerPresentation;

  /// False disables the field.
  final bool enabled;

  /// Read-only (still shows the value and can be copied).
  final bool readOnly;

  /// Show an error when empty.
  final bool required;

  /// Input decoration (label, hint, border...).
  final InputDecoration? decoration;

  /// Locale override.
  final ChronoLocale? locale;

  /// Theme override for the picker.
  final ChronoThemeData? theme;

  /// Extra validation; return an error string or null.
  final String? Function(DateTime? value)? validator;

  /// When to validate.
  final AutovalidateMode autovalidateMode;

  @override
  State<ChronoDateField> createState() => _ChronoDateFieldState();
}

class _ChronoDateFieldState extends State<ChronoDateField> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  DateTime? _value;
  bool _didInit = false;

  ChronoLocale get _locale => ChronoTheme.localeOf(context, widget.locale);
  ChronoFormat get _format => ChronoFormat(widget.pattern ?? _locale.defaultDatePattern, locale: _locale);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _value = widget.initialValue?.dateOnly;
      if (_value != null) _text.text = _format.format(_value!);
      _focus.addListener(() {
        if (!_focus.hasFocus) _normalise();
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  DateTime? _parse(String s) {
    if (s.trim().isEmpty) return null;
    final strict = _format.tryParse(s);
    if (strict != null || !widget.allowNaturalLanguage) return strict;
    return NaturalDateParser(locale: _locale, firstDayOfWeek: _locale.firstDayOfWeek).parse(s);
  }

  String? _error(String? s) {
    final text = s ?? '';
    if (text.trim().isEmpty) return widget.required ? _locale.strings.enterDate : widget.validator?.call(null);
    final d = _parse(text);
    if (d == null) return _locale.strings.invalidDate;
    if ((widget.firstDate != null && d.isBefore(widget.firstDate!.dateOnly)) ||
        (widget.lastDate != null && d.isAfter(widget.lastDate!)) ||
        !(widget.availability?.isAvailable(d) ?? true)) {
      return _locale.strings.outOfRange;
    }
    return widget.validator?.call(d);
  }

  void _changed(String s) {
    final d = _parse(s);
    if (d == _value) return;
    if (d == null && s.trim().isNotEmpty) return; // incomplete input
    _value = d;
    if (_error(s) == null) widget.onChanged?.call(d);
  }

  void _normalise() {
    final d = _parse(_text.text);
    if (d != null && _error(_text.text) == null) {
      final formatted = _format.format(d);
      if (formatted != _text.text) _text.text = formatted;
      if (d != _value) {
        _value = d;
        widget.onChanged?.call(d);
      }
    }
  }

  Future<void> _pick() async {
    final d = await showChronoDatePicker(
      context: context,
      initialDate: _value,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      availability: widget.availability,
      presentation: widget.pickerPresentation,
      locale: widget.locale,
      theme: widget.theme,
      inputPattern: widget.pattern,
    );
    if (d == null || !mounted) return;
    setState(() {
      _value = d;
      _text.text = _format.format(d);
    });
    widget.onChanged?.call(d);
  }

  @override
  Widget build(BuildContext context) {
    final f = _format;
    final numeric = f.isNumericOnly && !widget.allowNaturalLanguage;
    final pattern = widget.pattern ?? _locale.defaultDatePattern;
    final base = widget.decoration ?? const InputDecoration(border: OutlineInputBorder());
    return TextFormField(
      controller: _text,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      keyboardType: numeric ? TextInputType.datetime : TextInputType.text,
      inputFormatters: f.isNumericOnly && !widget.allowNaturalLanguage ? [ChronoDateMaskFormatter(pattern)] : null,
      autovalidateMode: widget.autovalidateMode,
      validator: _error,
      onChanged: _changed,
      onFieldSubmitted: (_) => _normalise(),
      decoration: base.copyWith(
        hintText: base.hintText ?? pattern.toLowerCase(),
        labelText: base.labelText ?? _locale.strings.enterDate,
        suffixIcon: base.suffixIcon ??
            (widget.showPickerButton && widget.enabled && !widget.readOnly
                ? IconButton(
                    tooltip: _locale.strings.selectDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    onPressed: _pick,
                  )
                : null),
      ),
    );
  }
}
