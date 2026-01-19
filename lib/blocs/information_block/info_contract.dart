// ignore_for_file: constant_identifier_names
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import '../../core/screen_state.dart';

part 'info_contract.g.dart';

abstract class InfoData implements Built<InfoData, InfoDataBuilder> {
  factory InfoData([void Function(InfoDataBuilder) updates]) = _$InfoData;
  InfoData._();

  ScreenState get state;
  String? get errorMessage;
  String? get cityName;
  double? get temperature;
  String? get description;
  String? get phone;

  /// Use a BuiltList<dynamic> so it can contain the JSON maps returned by the API.
  BuiltList<dynamic>? get productsdata;
}

abstract class InfoEvent {}

class InitEvent extends InfoEvent {}

class GetWeatherEvent extends InfoEvent {
  final String city;
  GetWeatherEvent(this.city);
}

class ProductDataEvent extends InfoEvent {}

abstract class InfoTarget {
  static const String SPLASH = 'splash';
}
