import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// A consistent loading indicator widget used throughout the app.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 50, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: color ?? Theme.of(context).colorScheme.primary,
        size: size,
      ),
    );
  }
}

/// A small loading indicator for inline use.
class SmallLoadingIndicator extends StatelessWidget {
  const SmallLoadingIndicator({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LoadingIndicator(size: 24, color: color);
  }
}
