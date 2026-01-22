import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Mixin providing reusable form validators.
///
/// Use this mixin in StatefulWidget states that contain forms.
///
/// ## Example:
/// ```dart
/// class _MyFormState extends State<MyForm> with FormValidationMixin {
///   final _formKey = GlobalKey<FormState>();
///
///   @override
///   Widget build(BuildContext context) {
///     return Form(
///       key: _formKey,
///       child: TextFormField(
///         validator: (value) => validateRequired(context, value, 'Title'),
///       ),
///     );
///   }
/// }
/// ```
mixin FormValidationMixin<T extends StatefulWidget> on State<T> {
  /// Validate that field is not empty.
  ///
  /// Returns error message if empty, null if valid.
  String? validateRequired(
    BuildContext context,
    String? value,
    String fieldName,
  ) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired(fieldName);
    }
    return null;
  }

  /// Validate minimum length.
  ///
  /// Returns error message if too short, null if valid.
  String? validateMinLength(
    BuildContext context,
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null; // Use validateRequired separately for empty check
    }

    final l10n = AppLocalizations.of(context);
    if (value.length < minLength) {
      return l10n.fieldTooShort(fieldName, minLength);
    }
    return null;
  }

  /// Validate maximum length.
  ///
  /// Returns error message if too long, null if valid.
  String? validateMaxLength(
    BuildContext context,
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final l10n = AppLocalizations.of(context);
    if (value.length > maxLength) {
      return l10n.fieldTooLong(fieldName, maxLength);
    }
    return null;
  }

  /// Validate email format.
  ///
  /// Returns error message if invalid format, null if valid.
  String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return null; // Use validateRequired separately
    }

    final l10n = AppLocalizations.of(context);
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return l10n.invalidEmailFormat;
    }
    return null;
  }

  /// Validate phone number format.
  ///
  /// Accepts various international formats.
  String? validatePhone(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final l10n = AppLocalizations.of(context);
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');

    if (!phoneRegex.hasMatch(value)) {
      return l10n.invalidPhoneFormat;
    }
    return null;
  }

  /// Validate numeric input.
  ///
  /// Returns error message if not a number, null if valid.
  String? validateNumeric(
    BuildContext context,
    String? value,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final l10n = AppLocalizations.of(context);
    if (double.tryParse(value) == null) {
      return l10n.fieldMustBeNumeric(fieldName);
    }
    return null;
  }

  /// Validate range (for numeric fields).
  ///
  /// Returns error message if out of range, null if valid.
  String? validateRange(
    BuildContext context,
    String? value,
    double min,
    double max,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return validateNumeric(context, value, fieldName);
    }

    final l10n = AppLocalizations.of(context);
    if (numValue < min || numValue > max) {
      return l10n.fieldOutOfRange(fieldName, min, max);
    }
    return null;
  }

  /// Combine multiple validators.
  ///
  /// Returns the first error encountered, null if all pass.
  ///
  /// ## Example:
  /// ```dart
  /// validator: (value) => combineValidators(context, value, [
  ///   (v) => validateRequired(context, v, 'Email'),
  ///   (v) => validateEmail(context, v),
  /// ]),
  /// ```
  String? combineValidators(
    BuildContext context,
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  /// Validate ticket title (common use case).
  ///
  /// Combines required, min length (3), and max length (100).
  String? validateTicketTitle(BuildContext context, String? value) {
    return combineValidators(context, value, [
      (v) => validateRequired(context, v, 'Title'),
      (v) => validateMinLength(context, v, 3, 'Title'),
      (v) => validateMaxLength(context, v, 100, 'Title'),
    ]);
  }

  /// Validate ticket description (common use case).
  ///
  /// Optional field with max length of 2000 characters.
  String? validateTicketDescription(BuildContext context, String? value) {
    return validateMaxLength(context, value, 2000, 'Description');
  }

  /// Validate that a selection has been made.
  ///
  /// For dropdown/selection fields.
  String? validateSelection(
    BuildContext context,
    dynamic value,
    String fieldName,
  ) {
    final l10n = AppLocalizations.of(context);
    if (value == null) {
      return l10n.fieldRequired(fieldName);
    }
    return null;
  }
}
