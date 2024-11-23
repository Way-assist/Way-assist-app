import 'package:formz/formz.dart';

enum RepeatPasswordError { empty, mismatch }

class RepeatPassword extends FormzInput<String, RepeatPasswordError> {
  final String originalPassword;

  // Constructor para inicializar RepeatPassword con la contraseña original
  const RepeatPassword.pure({this.originalPassword = ''}) : super.pure('');
  const RepeatPassword.dirty(
      {String value = '', required this.originalPassword})
      : super.dirty(value);

  // Método para devolver el mensaje de error correspondiente
  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == RepeatPasswordError.empty) {
      return 'El campo no puede estar vacío';
    }
    if (displayError == RepeatPasswordError.mismatch) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  // Método de validación
  @override
  RepeatPasswordError? validator(String? value) {
    if (value == null || value.isEmpty) return RepeatPasswordError.empty;
    if (value != originalPassword) return RepeatPasswordError.mismatch;

    return null;
  }
}
