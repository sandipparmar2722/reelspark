import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import '../utils/transition_duration.dart';


extension BuildContextNavigation on BuildContext {
  void pop<T extends Object>([T? result]) => Navigator.of(this).pop(result);

  void popUntil(RoutePredicate predicate) {
    return Navigator.of(this).popUntil(predicate);
  }

  Future<T?> push<T extends Object>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
    bool rootNavigator = false,
  }) {
    return Navigator.of(this, rootNavigator: rootNavigator).push(
      MaterialPageRoute<T>(
        builder: builder,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  Future<T?> pushTransparent<T extends Object>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    Color? overlayColor,
    bool maintainState = true,
    bool fullscreenDialog = false,
    bool rootNavigator = false,
  }) {
    return Navigator.of(this, rootNavigator: rootNavigator).push(
      TransparentRoute<T>(
        builder: builder,
        settings: settings,
        overlayColor: overlayColor,
        updatedFullscreenDialog: fullscreenDialog,
      ),
    );
  }

  Future<T?> pushReplacementTransparent<T extends Object>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    Color? overlayColor,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(this).pushReplacement(
      TransparentRoute<T>(
        builder: builder,
        settings: settings,
        overlayColor: overlayColor,
        updatedFullscreenDialog: fullscreenDialog,
      ),
    );
  }

  Future<T?> pushReplacement<T extends Object>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) =>
      Navigator.of(this).pushReplacement(
        MaterialPageRoute<T>(
            builder: builder,
            settings: settings,
            maintainState: maintainState,
            fullscreenDialog: fullscreenDialog),
      );

  Future<T?> pushAndRemoveUntil<T extends Object>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(this).pushAndRemoveUntil(
      MaterialPageRoute<T>(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog),
      (route) => false,
    );
  }

  Future<bool> maybePop<T extends Object?>([T? result]) =>
      Navigator.of(this).maybePop(result);

  void showToast(Widget child) {
    showToastWidget(
      child,
      context: this,
      duration: TransitionDuration.verySlow,
      animDuration: TransitionDuration.fast,
      animation: StyledToastAnimation.none,
      reverseAnimation: StyledToastAnimation.none,
      position: StyledToastPosition.center,
    );
  }

  void presentModalBottomSheet(Widget child, {Function(dynamic)? callback}) {
    showModalBottomSheet(
      context: this,
      builder: (context) {
        return child;
      },
    );
  }
}

class TransparentRoute<T> extends PageRoute<T> {
  TransparentRoute(
      {required this.builder,
      required this.updatedFullscreenDialog,
      required this.overlayColor,
      RouteSettings? settings})
      : super(settings: settings, fullscreenDialog: updatedFullscreenDialog);

  final WidgetBuilder builder;
  final bool updatedFullscreenDialog;
  final Color? overlayColor;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => TransitionDuration.medium;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final result = builder(context);
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end);
    final offsetAnimation = animation.drive(tween);

    return Container(
      color: overlayColor ?? Colors.blue.shade200,
      child: SlideTransition(
        position: offsetAnimation,
        child: result,
      ),
    );
  }
}
