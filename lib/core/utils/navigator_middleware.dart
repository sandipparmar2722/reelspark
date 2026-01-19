import 'package:flutter/material.dart';

typedef OnRouteChange<R extends Route<dynamic>> = void Function(
  Route<dynamic> route,
  Route<dynamic>? previousRoute,
);

class NavigatorMiddleware<R extends Route<dynamic>> extends NavigatorObserver {
  NavigatorMiddleware({
    this.enableLogger = true,
    this.onPush,
    this.onPop,
    this.onReplace,
    this.onRemove,
  }) : _stack = [];

  final List<Route<dynamic>> _stack;
  final bool enableLogger;

  final OnRouteChange<R>? onPush;
  final OnRouteChange<R>? onPop;
  final OnRouteChange<R>? onReplace;
  final OnRouteChange<R>? onRemove;

  //create clone list from stack
  List<R> get stack => List<R>.from(_stack);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    if (onPush != null) {
      onPush!(route, previousRoute);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    if (onPop != null) {
      onPop!(route, previousRoute);
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      if (_stack.contains(oldRoute)) {
        final oldItemIndex = _stack.indexOf(oldRoute);
        if (newRoute != null) {
          _stack[oldItemIndex] = newRoute;
        }
      }
    }
    if (onReplace != null && newRoute != null) {
      onReplace!(newRoute, oldRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
    if (onRemove != null) {
      onRemove!(route, previousRoute);
    }
    super.didRemove(route, previousRoute);
  }

  @override
  void didStartUserGesture(
      Route<dynamic> route, Route<dynamic>? previousRoute) {
  }

  @override
  void didStopUserGesture() {
  }
}
