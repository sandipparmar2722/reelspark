// ignore_for_file: constant_identifier_names
import 'package:built_value/built_value.dart';
import '../../ui/bottom_nav/modern_bottom_nav.dart';

part 'nav_contract.g.dart';

/// --------------------------------------------------
/// STATE
/// --------------------------------------------------

abstract class NavData implements Built<NavData, NavDataBuilder> {
  factory NavData([void Function(NavDataBuilder) updates]) = _$NavData;
  NavData._();

  /// Currently selected bottom tab
  BottomNavItem get currentTab;
}

/// --------------------------------------------------
/// EVENTS
/// --------------------------------------------------

abstract class NavEvent {}

class InitNavEvent extends NavEvent {}

/// User taps a bottom tab
class ChangeTabEvent extends NavEvent {
  final BottomNavItem tab;
  ChangeTabEvent(this.tab);
}

/// App opened via deep link
class DeepLinkTabEvent extends NavEvent {
  final String route;
  DeepLinkTabEvent(this.route);
}

/// --------------------------------------------------
/// TARGETS (OPTIONAL)
/// --------------------------------------------------

abstract class NavTarget {
  static const String ROOT = 'root';
}
