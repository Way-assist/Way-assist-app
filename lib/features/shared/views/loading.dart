import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;

    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 700,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          AnimatedContainer(
            duration: Duration(seconds: 2),
            curve: Curves.easeInOut,
            child: Image.asset(
              'assets/images/Refresh.gif',
              width: 250,
              height: 250,
            ),
          ),
          SizedBox(height: 30),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ).createShader(bounds);
            },
            child: Text(
              'Cargando...',
              style: texts.headlineSmall!.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 20),
          LoadingIndicator(),
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatefulWidget {
  @override
  _LoadingIndicatorState createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      index * 0.2,
                      0.6 + index * 0.2,
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                child: Dot(),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
