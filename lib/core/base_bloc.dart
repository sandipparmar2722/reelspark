// ignore_for_file: avoid_catches_without_on_clauses, avoid_function_literals_in_foreach_calls, depend_on_referenced_packages
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'logging.dart';
import 'view_actions.dart';

abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(State state) : super(state);

  final PublishSubject<ViewAction> _sideEffects = PublishSubject();

  Stream<ViewAction> get viewActions => _sideEffects.stream;

  final List<StreamSubscription> _subscriptions = [];
  final List<CancelToken> _tokens = [];

  @protected
  void dispatchViewEvent(ViewAction target) {
    _sideEffects.add(target);
  }

  @override
  Future<void> close() {
    _tokens.forEach((t) {
      try {
        t.cancel();
      } catch (e) {
        log(error: e);
      }
    });
    _subscriptions.forEach((f) => f.cancel());
    _sideEffects.close();
    return super.close();
  }
}

extension StreamLifecycle on StreamSubscription {
  void bindToLifecycle(BaseBloc<dynamic, dynamic> bloc) {
    bloc._subscriptions.add(this);
  }
}

extension ApiLifecycle on CancelToken {
  void bindToLifecycle(BaseBloc<dynamic, dynamic> bloc) {
    bloc._tokens.add(this);
  }
}
