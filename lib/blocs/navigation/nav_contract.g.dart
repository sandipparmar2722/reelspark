// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nav_contract.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NavData extends NavData {
  @override
  final BottomNavItem currentTab;

  factory _$NavData([void Function(NavDataBuilder)? updates]) =>
      (new NavDataBuilder()..update(updates))._build();

  _$NavData._({required this.currentTab}) : super._() {
    BuiltValueNullFieldError.checkNotNull(currentTab, r'NavData', 'currentTab');
  }

  @override
  NavData rebuild(void Function(NavDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NavDataBuilder toBuilder() => new NavDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NavData && currentTab == other.currentTab;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currentTab.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NavData')
          ..add('currentTab', currentTab))
        .toString();
  }
}

class NavDataBuilder implements Builder<NavData, NavDataBuilder> {
  _$NavData? _$v;

  BottomNavItem? _currentTab;
  BottomNavItem? get currentTab => _$this._currentTab;
  set currentTab(BottomNavItem? currentTab) => _$this._currentTab = currentTab;

  NavDataBuilder();

  NavDataBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currentTab = $v.currentTab;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NavData other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$NavData;
  }

  @override
  void update(void Function(NavDataBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NavData build() => _build();

  _$NavData _build() {
    final _$result = _$v ??
        new _$NavData._(
            currentTab: BuiltValueNullFieldError.checkNotNull(
                currentTab, r'NavData', 'currentTab'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
