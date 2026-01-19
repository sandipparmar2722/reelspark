import 'package:flutter/material.dart';

import '../../core/utils/dimensions.dart';

class AppCircularProgressIndicator extends StatefulWidget {
  const AppCircularProgressIndicator({Key? key}) : super(key: key);

  @override
  State<AppCircularProgressIndicator> createState() =>
      _AppCircularProgressIndicatorState();
}

class _AppCircularProgressIndicatorState
    extends State<AppCircularProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(
      strokeWidth: Dimens.border_width_xlarge,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
      backgroundColor: Colors.white,
    );
  }
}
