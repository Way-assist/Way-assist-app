import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorMessage;
  final TextEditingController? controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final IconButton? suffixIcon;
  final Icon? suffixIconS;
  final String? initialvalue;
  final bool modeDark;
  final FocusNode? focusNode;
  final bool enabled;

  CustomTextFormField({
    super.key,
    this.label,
    this.icon = Icons.supervised_user_circle_outlined,
    this.hint,
    this.controller,
    this.errorMessage,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.suffixIcon,
    this.suffixIconS,
    this.initialvalue,
    this.modeDark = false,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color backgroundColor = colors.primary.withOpacity(0.005);
    Color borderColor = colors.primary;
    Color shadowColor = colors.primary.withOpacity(0.005);

    const radius = Radius.circular(6);
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: borderColor),
      borderRadius: const BorderRadius.all(radius),
    );

    final errorBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red.shade800, width: 2),
      borderRadius: const BorderRadius.all(radius),
    );

    final disabledBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
      borderRadius: const BorderRadius.all(radius),
    );

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(radius),
        boxShadow: [
          BoxShadow(
              color: shadowColor, blurRadius: 5, offset: const Offset(0, 5))
        ],
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        focusNode: focusNode,
        validator: validator,
        obscureText: obscureText,
        initialValue: initialvalue,
        onFieldSubmitted: onFieldSubmitted,
        keyboardType: keyboardType,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 17,
              color: enabled ? null : Colors.grey.shade600,
            ),
        enabled: enabled,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          floatingLabelStyle: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(fontSize: 18, color: colors.onSurface.withOpacity(0.9)),
          enabledBorder: border,
          focusedBorder: border,
          errorBorder: errorBorder,
          focusedErrorBorder: errorBorder,
          disabledBorder: disabledBorder,
          isDense: true,
          label: label != null
              ? Text(
                  label!,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 15,
                        color: enabled
                            ? colors.onSurface.withOpacity(0.9)
                            : Colors.grey.shade600,
                      ),
                )
              : null,
          hintText: hint,
          errorText: errorMessage,
          suffixIcon: suffixIcon ?? suffixIconS,
          focusColor: colors.primary,
          fillColor: enabled ? null : Colors.grey[200],
          filled: !enabled,
        ),
      ),
    );
  }
}
