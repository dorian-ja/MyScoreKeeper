import 'package:flutter/services.dart';

/// N'autorise que des entiers signés en cours de saisie : "", "-", "-12", "42".
class SignedIntTextInputFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^-?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
