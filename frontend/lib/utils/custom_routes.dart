import 'package:flutter/material.dart';

class NoTransitionPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  NoTransitionPageRoute({required this.child, RouteSettings? settings})
      : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}