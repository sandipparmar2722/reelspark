import 'package:flutter/material.dart';

import '../utils/transition_duration.dart';

extension Util on ScrollController {
  bool hasReachedBottom() {
    return position.pixels >= position.maxScrollExtent;
  }

  bool hasScrolled({int minScroll = 0}) {
    return position.pixels > minScroll;
  }

  void scrollToTop() {
    animateTo(0.0, curve: Curves.easeOut, duration: TransitionDuration.medium);
  }

  void scrollToBottom() {
    animateTo(position.maxScrollExtent,
        curve: Curves.easeOut, duration: TransitionDuration.medium);
  }
}
