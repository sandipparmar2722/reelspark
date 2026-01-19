// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main_app_contract.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MainAppData extends MainAppData {
  @override
  final ScreenState state;
  @override
  final String? errorMessage;
  @override
  final ThemeData appThemeData;

  factory _$MainAppData([void Function(MainAppDataBuilder)? updates]) =>
      (new MainAppDataBuilder()..update(updates))._build();

  _$MainAppData._(
      {required this.state, this.errorMessage, required this.appThemeData})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(state, r'MainAppData', 'state');
    BuiltValueNullFieldError.checkNotNull(
        appThemeData, r'MainAppData', 'appThemeData');
  }

  @override
  MainAppData rebuild(void Function(MainAppDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MainAppDataBuilder toBuilder() => new MainAppDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MainAppData &&
        state == other.state &&
        errorMessage == other.errorMessage &&
        appThemeData == other.appThemeData;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, errorMessage.hashCode);
    _$hash = $jc(_$hash, appThemeData.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MainAppData')
          ..add('state', state)
          ..add('errorMessage', errorMessage)
          ..add('appThemeData', appThemeData))
        .toString();
  }
}

class MainAppDataBuilder implements Builder<MainAppData, MainAppDataBuilder> {
  _$MainAppData? _$v;

  ScreenState? _state;
  ScreenState? get state => _$this._state;
  set state(ScreenState? state) => _$this._state = state;

  String? _errorMessage;
  String? get errorMessage => _$this._errorMessage;
  set errorMessage(String? errorMessage) => _$this._errorMessage = errorMessage;

  ThemeData? _appThemeData;
  ThemeData? get appThemeData => _$this._appThemeData;
  set appThemeData(ThemeData? appThemeData) =>
      _$this._appThemeData = appThemeData;

  MainAppDataBuilder();

  MainAppDataBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _state = $v.state;
      _errorMessage = $v.errorMessage;
      _appThemeData = $v.appThemeData;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MainAppData other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$MainAppData;
  }

  @override
  void update(void Function(MainAppDataBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MainAppData build() => _build();

  _$MainAppData _build() {
    final _$result = _$v ??
        new _$MainAppData._(
            state: BuiltValueNullFieldError.checkNotNull(
                state, r'MainAppData', 'state'),
            errorMessage: errorMessage,
            appThemeData: BuiltValueNullFieldError.checkNotNull(
                appThemeData, r'MainAppData', 'appThemeData'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
