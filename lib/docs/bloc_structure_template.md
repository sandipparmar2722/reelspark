# BLoC Structure Template

This document serves as a reference for creating new screens with BLoC pattern following the project's architecture.

## File Structure

```
lib/
├── blocs/
│   └── [feature]/
│       ├── [feature]_bloc.dart        # BLoC implementation
│       ├── [feature]_contract.dart    # Events and Data models
│       └── [feature]_contract.g.dart  # Generated file (auto-generated)
├── services/
│   └── [feature]/
│       └── [feature]_service.dart     # Service layer (API calls)
├── api/
│   └── [feature]/
│       └── [feature]_api.dart         # API client calls
└── ui/
    └── [feature]/
        └── [feature]_screen.dart      # UI screen
```

## 1. Contract File (`[feature]_contract.dart`)

### Data Model (using built_value)

```dart
import 'package:built_value/built_value.dart';
import '../../core/screen_state.dart';

part '[feature]_contract.g.dart';

abstract class FeatureData implements Built<FeatureData, FeatureDataBuilder> {
  factory FeatureData([void Function(FeatureDataBuilder) updates]) = _$FeatureData;

  FeatureData._();

  ScreenState get state;
  String? get errorMessage;
  
  // Add your feature-specific fields here
  String? get someField;
  List<String> get someList;
}

abstract class FeatureTarget {
  static const String success = 'success';
  static const String failure = 'failure';
}

abstract class FeatureEvent {}

class InitEvent extends FeatureEvent {}

class SomeActionEvent extends FeatureEvent {
  SomeActionEvent({required this.param});
  
  final String param;
}
```

### Initial State

```dart
static FeatureData get initState => (FeatureDataBuilder()
  ..state = ScreenState.content
  ..someField = ''
  ..someList = [])
  .build();
```

## 2. BLoC File (`[feature]_bloc.dart`)

```dart
import '../../api/entities/common.dart';
import '../../core/base_bloc.dart';
import '../../core/screen_state.dart';
import '../../core/view_actions.dart';
import '../../services/[feature]/[feature]_service.dart';
import '[feature]_contract.dart';

class FeatureBloc extends BaseBloc<FeatureEvent, FeatureData> {
  final FeatureService _featureService;

  FeatureBloc(this._featureService) : super(initState) {
    on<InitEvent>(_initEvent);
    on<SomeActionEvent>(_someActionEvent);
  }

  static FeatureData get initState => (FeatureDataBuilder()
    ..state = ScreenState.content
    ..someField = ''
    ..someList = [])
    .build();

  Future<void> _initEvent(InitEvent event, emit) async {
    emit(
      state.rebuild(
        (u) {
          u.state = ScreenState.content;
        },
      ),
    );
  }

  Future<void> _someActionEvent(SomeActionEvent event, emit) async {
    emit(
      state.rebuild(
        (u) => u.state = ScreenState.loading,
      ),
    );

    final response = await _featureService.someMethod(
      param: event.param,
    );

    if (response.errorResult == null && response.data != null) {
      emit(
        state.rebuild(
          (u) {
            u.state = ScreenState.content;
            u.someField = response.data!['someField'];
          },
        ),
      );

      dispatchViewEvent(
        NavigateScreen(FeatureTarget.success),
      );

      dispatchViewEvent(
        DisplayMessage(
          type: DisplayMessageType.toast,
          title: 'Success',
          message: 'Action completed successfully',
        ),
      );
    } else {
      final errorMessage = response.errorResult?.errorMessage ?? 'Failed';
      dispatchViewEvent(
        DisplayMessage(
          type: DisplayMessageType.dialog,
          title: 'Error',
          message: errorMessage,
        ),
      );
      emit(
        state.rebuild(
          (u) {
            u.state = ScreenState.error;
            u.errorMessage = errorMessage;
          },
        ),
      );
    }
  }
}
```

## 3. Screen File (`[feature]_screen.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/[feature]/[feature]_bloc.dart';
import '../../blocs/[feature]/[feature]_contract.dart';
import '../../core/base_state.dart';
import '../../core/screen_state.dart';
import '../../core/view_actions.dart';
import '../common/app_loader.dart';

class FeatureScreen extends StatefulWidget {
  const FeatureScreen({super.key});

  @override
  State<FeatureScreen> createState() => _FeatureScreenState();
}

class _FeatureScreenState extends BaseState<FeatureBloc, FeatureScreen> {
  @override
  void initState() {
    super.initState();
    bloc.add(InitEvent());
  }

  @override
  void onViewEvent(ViewAction event) async {
    switch (event.runtimeType) {
      case DisplayMessage:
        final displayMessage = event as DisplayMessage;
        if (displayMessage.type == DisplayMessageType.dialog) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(displayMessage.title ?? ''),
              content: Text(displayMessage.message ?? ''),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (displayMessage.type == DisplayMessageType.toast) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMessage.message ?? ''),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
      case NavigateScreen:
        final navigateScreen = event as NavigateScreen;
        if (navigateScreen.target == FeatureTarget.success) {
          Navigator.pop(context);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Screen'),
      ),
      body: BlocProvider<FeatureBloc>(
        create: (BuildContext context) => bloc,
        child: BlocBuilder<FeatureBloc, FeatureData>(
          builder: (BuildContext context, FeatureData data) {
            if (data.state == ScreenState.loading) {
              return const AppLoader();
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Your UI here
                    Text(data.someField ?? ''),
                    
                    ElevatedButton(
                      onPressed: () {
                        bloc.add(SomeActionEvent(param: 'some value'));
                      },
                      child: const Text('Do Action'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

## 4. Service File (`[feature]_service.dart`)

```dart
import '../../api/entities/common.dart';
import '../../api/[feature]/[feature]_api.dart';

class FeatureService {
  FeatureService(this._featureApi);

  final FeatureApi _featureApi;

  Future<ResponseEntity<Map<String, dynamic>>> someMethod({
    required String param,
  }) async {
    return _featureApi.someMethod(param: param);
  }
}
```

## 5. API File (`[feature]_api.dart`)

```dart
import '../../core/error/failures.dart';
import '../../core/network/rest_api_client.dart';
import '../api_names.dart';
import '../entities/common.dart';

class FeatureApi {
  FeatureApi(this._apiClient);

  final RestApiClient _apiClient;

  Future<ResponseEntity<Map<String, dynamic>>> someMethod({
    required String param,
  }) async {
    try {
      final response = await _apiClient.request(
        path: Apis.someEndpoint,
        data: RequestData(
          data: {'param': param},
          type: RequestDataType.body,
        ),
        requestMethod: RequestMethod.post,
      );

      if (response.errorResult == null && response.data != null) {
        return ResponseEntity(response.data, null);
      }
      return ResponseEntity(null, response.errorResult);
    } catch (e, stackTrace) {
      print('Error in someMethod: $e');
      return ResponseEntity(
        null,
        ErrorResult(
          errorMessage: 'An unexpected error occurred: $e',
          type: ErrorResultType.response,
        ),
      );
    }
  }
}
```

## Key Points

1. **Always extend BaseState**: Use `BaseState<FeatureBloc, FeatureScreen>` for automatic bloc resolution
2. **Use BlocProvider and BlocBuilder**: Wrap your UI with BlocProvider and use BlocBuilder to react to state changes
3. **Handle ViewActions**: Override `onViewEvent` to handle navigation and messages
4. **Screen States**: Use `ScreenState.loading`, `ScreenState.content`, `ScreenState.error`
5. **Error Handling**: Always check `response.errorResult == null` before accessing data
6. **Build Runner**: Run `flutter pub run build_runner build` after adding new fields to contract
7. **State Management**: Use `state.rebuild()` to update state immutably
8. **View Events**: Use `dispatchViewEvent()` for navigation and messages

## Example: Loading with Overlay

```dart
Stack(
  children: [
    // Main content
    SingleChildScrollView(...),
    
    // Loading overlay
    if (data.state == ScreenState.loading)
      Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: const AppLoader(),
        ),
      ),
  ],
)
```

