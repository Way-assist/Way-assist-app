import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckAuthStatusScreen extends ConsumerStatefulWidget {
  const CheckAuthStatusScreen({super.key});

  @override
  ConsumerState<CheckAuthStatusScreen> createState() =>
      _CheckAuthStatusScreenState();
}

class _CheckAuthStatusScreenState extends ConsumerState<CheckAuthStatusScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox.expand(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/loading.gif',
                    width: constraints.maxWidth,
                    height: constraints.maxWidth,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    'Way Assist',
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          color: colors.secondary.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
