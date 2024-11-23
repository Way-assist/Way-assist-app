import 'package:formz/formz.dart';

// Define input validation errors
enum PasswordError { empty, length, format }

class Password extends FormzInput<String, PasswordError> {
  static final RegExp passwordRegExp = RegExp(
    r'(?:(?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$',
  );

  final bool
      fullValidation; // Parámetro booleano para determinar el tipo de validación

  // Call super.pure to represent an unmodified form input.
  const Password.pure({this.fullValidation = true}) : super.pure('');

  // Call super.dirty to represent a modified form input.
  const Password.dirty(String value, {this.fullValidation = true})
      : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == PasswordError.empty) return 'El campo es requerido';
    if (displayError == PasswordError.length) return 'Mínimo 6 caracteres';
    if (displayError == PasswordError.format)
      return 'Debe de tener Mayúscula, letras y un número';

    return null;
  }

  @override
  PasswordError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return PasswordError.empty;

    // Si fullValidation es falso, termina la validación después de verificar si el campo está vacío
    if (!fullValidation) return null;

    // Resto de la validación si fullValidation es verdadero
    if (value.length < 6) return PasswordError.length;
    if (!passwordRegExp.hasMatch(value)) return PasswordError.format;

    return null;
  }
}
