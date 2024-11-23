import 'package:formz/formz.dart';

enum DNIValidationError { invalid, length, empty }

class DNI extends FormzInput<String, DNIValidationError> {
  const DNI.pure() : super.pure('');
  const DNI.dirty([String value = '']) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == DNIValidationError.empty) {
      return 'El campo DNI no puede estar vacío';
    }
    if (displayError == DNIValidationError.length) {
      return 'El DNI debe tener exactamente 8 dígitos';
    }
    if (displayError == DNIValidationError.invalid) {
      return 'El DNI solo puede contener números';
    }

    return null;
  }

  @override
  DNIValidationError? validator(String? value) {
    final dni = value ?? '';
    if (dni.isEmpty)
      return DNIValidationError.empty; // Validación de campo vacío
    if (dni.length != 8) return DNIValidationError.length;
    if (!_isNumeric(dni)) return DNIValidationError.invalid;
    return null;
  }

  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }
}
