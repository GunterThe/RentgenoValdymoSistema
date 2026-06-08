import 'package:flutter/material.dart';

class PagePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const PagePanel({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 20)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}
