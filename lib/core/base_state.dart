import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../inject/injector.dart';
import 'base_bloc.dart';
import 'view_actions.dart';

abstract class BaseState<Q extends BaseBloc, T extends StatefulWidget>
    extends State<T> {
  late Q bloc;
  bool _initialized = false;

  BaseState() {
    // Try to resolve from injector in constructor as fallback
    bloc = Injector.resolve();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize view events only once
    if (!_initialized) {
      _initialized = true;

      // Try to get BloC from context (when using BlocProvider in routes)
      try {
        bloc = BlocProvider.of<Q>(context, listen: false);
      } catch (e) {
        // Already resolved in constructor, use that
      }

      _initViewEvents();
    }
  }

  void _initViewEvents() {
    bloc.viewActions.listen(onViewEvent);
  }

  void onViewEvent(ViewAction event) {
    if (event is NavigateScreen) {
      onNavigationEvent(event.target);
    } else if (event is CloseScreen) {
      Navigator.pop(context);
    } else if (event is DisplayMessage) {
    } else if (event is ChangeTheme) {
      _forceRebuildWidgets();
    }
  }

  void _forceRebuildWidgets() {
    void rebuild(Element widget) {
      widget.markNeedsBuild();
      widget.visitChildren(rebuild);
    }


    (context as Element).visitChildren(rebuild);
  }

  void onNavigationEvent(dynamic target) {}

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }
}
