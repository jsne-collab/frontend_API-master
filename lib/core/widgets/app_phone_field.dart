import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

/// saisit d'un numéro de téléphone international, avec indicatif et validation.
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.errorText,
    this.validator,
  });

  final String label;
  final String? initialValue;
  final String? errorText;
  final ValueChanged<PhoneNumber> onChanged;
  final String? Function(PhoneNumber?)? validator;

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      initialCountryCode: 'TG',
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label, errorText: errorText),
      dropdownTextStyle: Theme.of(context).textTheme.bodyMedium,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
