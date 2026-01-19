// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'info_contract.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$InfoData extends InfoData {
  @override
  final ScreenState state;
  @override
  final String? errorMessage;
  @override
  final String? cityName;
  @override
  final double? temperature;
  @override
  final String? description;
  @override
  final String? phone;
  @override
  final BuiltList<dynamic>? productsdata;

  factory _$InfoData([void Function(InfoDataBuilder)? updates]) =>
      (new InfoDataBuilder()..update(updates))._build();

  _$InfoData._(
      {required this.state,
      this.errorMessage,
      this.cityName,
      this.temperature,
      this.description,
      this.phone,
      this.productsdata})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(state, r'InfoData', 'state');
  }

  @override
  InfoData rebuild(void Function(InfoDataBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InfoDataBuilder toBuilder() => new InfoDataBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InfoData &&
        state == other.state &&
        errorMessage == other.errorMessage &&
        cityName == other.cityName &&
        temperature == other.temperature &&
        description == other.description &&
        phone == other.phone &&
        productsdata == other.productsdata;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, errorMessage.hashCode);
    _$hash = $jc(_$hash, cityName.hashCode);
    _$hash = $jc(_$hash, temperature.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, productsdata.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'InfoData')
          ..add('state', state)
          ..add('errorMessage', errorMessage)
          ..add('cityName', cityName)
          ..add('temperature', temperature)
          ..add('description', description)
          ..add('phone', phone)
          ..add('productsdata', productsdata))
        .toString();
  }
}

class InfoDataBuilder implements Builder<InfoData, InfoDataBuilder> {
  _$InfoData? _$v;

  ScreenState? _state;
  ScreenState? get state => _$this._state;
  set state(ScreenState? state) => _$this._state = state;

  String? _errorMessage;
  String? get errorMessage => _$this._errorMessage;
  set errorMessage(String? errorMessage) => _$this._errorMessage = errorMessage;

  String? _cityName;
  String? get cityName => _$this._cityName;
  set cityName(String? cityName) => _$this._cityName = cityName;

  double? _temperature;
  double? get temperature => _$this._temperature;
  set temperature(double? temperature) => _$this._temperature = temperature;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  ListBuilder<dynamic>? _productsdata;
  ListBuilder<dynamic> get productsdata =>
      _$this._productsdata ??= new ListBuilder<dynamic>();
  set productsdata(ListBuilder<dynamic>? productsdata) =>
      _$this._productsdata = productsdata;

  InfoDataBuilder();

  InfoDataBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _state = $v.state;
      _errorMessage = $v.errorMessage;
      _cityName = $v.cityName;
      _temperature = $v.temperature;
      _description = $v.description;
      _phone = $v.phone;
      _productsdata = $v.productsdata?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InfoData other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$InfoData;
  }

  @override
  void update(void Function(InfoDataBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InfoData build() => _build();

  _$InfoData _build() {
    _$InfoData _$result;
    try {
      _$result = _$v ??
          new _$InfoData._(
              state: BuiltValueNullFieldError.checkNotNull(
                  state, r'InfoData', 'state'),
              errorMessage: errorMessage,
              cityName: cityName,
              temperature: temperature,
              description: description,
              phone: phone,
              productsdata: _productsdata?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'productsdata';
        _productsdata?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'InfoData', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
