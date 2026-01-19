// ignore_for_file: type_annotate_public_apis

import 'package:flutter/material.dart';

abstract class ViewAction {}

enum DisplayMessageType { toast, dialog }

class DisplayMessage extends ViewAction {
  final String? message;
  final String? title;
  final DisplayMessageType type;
  final dynamic data;

  DisplayMessage({
    this.message,
    this.title,
    this.type = DisplayMessageType.dialog,
    this.data,
  });

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, hash_and_equals
  bool operator ==(Object other) {
    return other is DisplayMessage &&
        other.message == message &&
        other.type == type &&
        other.data == data;
  }
}

class CloseScreen extends ViewAction {}

class ChangeTheme extends ViewAction {}

@immutable
class NavigateScreen extends ViewAction {
  final String target;
  final Object? data;

  NavigateScreen(this.target, {this.data});

  @override
  // ignore: hash_and_equals
  bool operator ==(other) {
    if (other is NavigateScreen) {
      return other.target == target && other.data == data;
    } else {
      return false;
    }
  }
}

@immutable
class PrefillData extends ViewAction {
  final Object? data;

  PrefillData({this.data});

  @override
  // ignore: hash_and_equals
  bool operator ==(other) {
    if (other is NavigateScreen) {
      return other.data == data;
    } else {
      return false;
    }
  }
}
