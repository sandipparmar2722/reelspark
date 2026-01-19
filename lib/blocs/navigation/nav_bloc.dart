import '../../core/base_bloc.dart';
import '../../core/event_bus.dart';
import '../../core/error/failures.dart';

import 'nav_contract.dart';
import '../../ui/bottom_nav/modern_bottom_nav.dart';

class NavBloc extends BaseBloc<NavEvent, NavData> {
  final CustomErrorHandler _errorHandler;
  final EventBus _eventBus;

  NavBloc(this._errorHandler, this._eventBus) : super(initState) {
    on<InitNavEvent>(_init);
    on<ChangeTabEvent>(_changeTab);
    on<DeepLinkTabEvent>(_deepLinkTab);

    _eventBus.events.listen(_handleBusEvents).bindToLifecycle(this);
  }

  // --------------------------------------------------
  // INITIAL STATE
  // --------------------------------------------------

  static NavData get initState => (NavDataBuilder()
    ..currentTab = BottomNavItem.home)
      .build();

  // --------------------------------------------------
  // INIT
  // --------------------------------------------------

  void _init(InitNavEvent event, emit) {
    emit(state);
  }

  // --------------------------------------------------
  // TAB CHANGE (OPTIMIZED)
  // --------------------------------------------------

  void _changeTab(ChangeTabEvent event, emit) {
    /// 🔒 Prevent duplicate rebuilds
    if (state.currentTab == event.tab) return;

    emit(
      state.rebuild((b) => b..currentTab = event.tab),
    );

    /// 🔥 Analytics only when tab actually changes
    _logAnalytics(event.tab);
  }

  // --------------------------------------------------
  // DEEP LINK HANDLING (SAFE)
  // --------------------------------------------------

  void _deepLinkTab(DeepLinkTabEvent event, emit) {
    final BottomNavItem targetTab;

    switch (event.route) {
      case '/template':
        targetTab = BottomNavItem.template;
        break;
      case '/premium':
        targetTab = BottomNavItem.premium;
        break;
      default:
        targetTab = BottomNavItem.home;
    }

    /// 🔒 Avoid unnecessary emit
    if (state.currentTab == targetTab) return;

    emit(
      state.rebuild((b) => b..currentTab = targetTab),
    );

    _logAnalytics(targetTab);
  }

  // --------------------------------------------------
  // ANALYTICS
  // --------------------------------------------------

  void _logAnalytics(BottomNavItem tab) {
    // Example:
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'tab_opened',
    //   parameters: {'tab': tab.name},
    // );
  }

  // --------------------------------------------------
  // GLOBAL BUS EVENTS (OPTIONAL)
  // --------------------------------------------------

  void _handleBusEvents(BusEvent event) {
    // Example future use:
    // if (event is ForceHomeTabEvent) {
    //   add(ChangeTabEvent(BottomNavItem.home));
    // }
  }
}
