import 'package:formz/formz.dart';

// Define input validation errors
enum DecimalInputError { invalidFormat }

// Extend FormzInput and provide the input type and error type.
class Decimal extends FormzInput<String, DecimalInputError> {
  // Call super.pure to represent an unmodified form input.
  const Decimal.pure() : super.pure('');

  // Call super.dirty to represent a modified form input.
  const Decimal.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == DecimalInputError.invalidFormat) {
      return 'El valor debe ser un número decimal válido';
    }

    return null;
  }

  @override
  DecimalInputError? validator(String value) {
    final parsedValue = double.tryParse(value);

    if (parsedValue == null) return DecimalInputError.invalidFormat;

    return null;
  }
}
