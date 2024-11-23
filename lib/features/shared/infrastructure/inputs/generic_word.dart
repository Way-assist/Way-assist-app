import 'package:formz/formz.dart';

// Define input validation errors
enum GenericWordError { tooShort }

// Extend FormzInput and provide the input type and error type.
class GenericWord extends FormzInput<String, GenericWordError> {
  // Call super.pure to represent an unmodified form input.
  const GenericWord.pure() : super.pure('');

  // Call super.dirty to represent a modified form input.
  const GenericWord.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == GenericWordError.tooShort) {
      return 'El campo debe tener mínimo 1 caracter';
    }

    return null;
  }

  // Override validator to handle validating a given input value.
  @override
  GenericWordError? validator(String value) {
    if (value.length < 1) return GenericWordError.tooShort;

    return null;
  }
}
