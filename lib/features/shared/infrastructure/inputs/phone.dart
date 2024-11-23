import 'package:formz/formz.dart';

// Define los posibles errores de validación
enum PhoneValidationError { empty, invalid, length }

class Phone extends FormzInput<String, PhoneValidationError> {
  // Constructor para un campo "puro" (sin modificar)
  const Phone.pure() : super.pure('');

  // Constructor para un campo "sucio" (modificado)
  const Phone.dirty([String value = '']) : super.dirty(value);

  // Método para devolver el mensaje de error correspondiente
  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == PhoneValidationError.empty) {
      return 'El campo teléfono no puede estar vacío';
    }
    if (displayError == PhoneValidationError.length) {
      return 'El teléfono debe tener exactamente 9 dígitos';
    }
    if (displayError == PhoneValidationError.invalid) {
      return 'El teléfono solo puede contener números';
    }

    return null;
  }

  // Método de validación del valor ingresado
  @override
  PhoneValidationError? validator(String value) {
    if (value.isEmpty) return PhoneValidationError.empty;
    if (value.length != 9) return PhoneValidationError.length;
    if (!_isNumeric(value)) return PhoneValidationError.invalid;

    return null;
  }

  // Método para verificar si la cadena contiene solo números
  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }
}
