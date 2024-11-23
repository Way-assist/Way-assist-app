import 'package:formz/formz.dart';

// Define input validation errors
enum IntnError { empty, value, format }

// Extend FormzInput and provide the input type and error type.
class Intn extends FormzInput<int, IntnError> {
  // Call super.pure to represent an unmodified form input.
  const Intn.pure() : super.pure(0);

  // Call super.dirty to represent a modified form input.
  const Intn.dirty(int value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == IntnError.empty) return 'El campo es requerido';
    if (displayError == IntnError.value) {
      return 'Tiene que ser mayor o igual 0';
    }
    if (displayError == IntnError.format) {
      return 'Tiene que ser un numero entero y mayor o igual 0';
    }

    return null;
  }

  // Override validator to handle validating a given input value.
  @override
  IntnError? validator(int value) {
    if (value.toString().isEmpty || value.toString().trim().isEmpty) {
      return IntnError.empty;
    }
    final isInterger = int.tryParse(value.toString()) ?? -1;
    if (isInterger == -1) return IntnError.format;
    if (value <= 0) return IntnError.value;
    return null;
  }
}
