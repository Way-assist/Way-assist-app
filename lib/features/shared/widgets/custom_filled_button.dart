import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomFilledButton extends StatelessWidget {
  final void Function()? onPressed;
  final String text;
  final String? svgSrc;
  final String? leadingIconSvg;
  final Color? buttonColor;
  final Color? textColor;
  final Color? iconColor;
  final Color? borderColor;
  final double? iconSize;
  final double? sizeradius;
  final double? sizeText;

  const CustomFilledButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.iconSize,
    this.sizeradius = 7.5,
    required this.text,
    this.svgSrc,
    this.sizeText= 16,
    this.leadingIconSvg,
    this.buttonColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Radius radius = Radius.circular(sizeradius ?? 7.5);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.only(
            bottomLeft: radius,
            bottomRight: radius,
            topLeft: radius,
            topRight: radius,
          ),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1)
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.only(
            bottomLeft: radius,
            bottomRight: radius,
            topLeft: radius,
            topRight: radius,
          ),
          onTap: onPressed,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIconSvg != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: iconColor != null
                          ? SvgPicture.asset(
                              leadingIconSvg!,
                              width: iconSize ?? 24,
                              colorFilter: ColorFilter.mode(
                                iconColor ?? Colors.transparent,
                                BlendMode.srcIn,
                              ),
                              height: 17,
                            )
                          : SvgPicture.asset(
                              leadingIconSvg!,
                              width: iconSize ?? 24,
                              height: 17,
                            ),
                    ),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: textColor ?? Colors.white, fontSize: sizeText ?? 16),
                  ),
                  if (svgSrc != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SvgPicture.asset(
                        svgSrc!,
                        theme: SvgTheme(
                          currentColor: iconColor ?? Colors.red,
                        ),
                        width: iconSize ?? 24,
                        height: 17,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
