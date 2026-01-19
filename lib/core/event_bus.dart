// ignore_for_file: depend_on_referenced_packages

import 'package:rxdart/subjects.dart';


abstract class BusEvent {}

abstract class EventBus {
  void sendEvent(BusEvent event);

  Stream<BusEvent> get events;
}

class EventBusImpl extends EventBus {
  // ignore: close_sinks
  final PublishSubject<BusEvent> _channel = PublishSubject();

  @override
  Stream<BusEvent> get events => _channel.stream;

  @override
  void sendEvent(BusEvent event) {
    _channel.sink.add(event);
  }
}

class UpdateProfileBusEvent extends BusEvent {
  @override
  // ignore: hash_and_equals, avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    return other is UpdateProfileBusEvent;
  }
}

class GetCategoriesBusEvent extends BusEvent {
  @override
  // ignore: hash_and_equals, avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    return other is UpdateProfileBusEvent;
  }
}

class RefreshAccountScreenBusEvent extends BusEvent {
  @override
  // ignore: hash_and_equals, avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    return other is UpdateProfileBusEvent;
  }
}

class ChnageBusinessCategoryBusEvent extends BusEvent {
  ChnageBusinessCategoryBusEvent({
    required this.categoryId,
    required this.subCategoryIds,
    required this.mainCategoryName,
  });
  final int categoryId;
  final List<int> subCategoryIds;
  final String mainCategoryName;
}

class DownloadRefreshBusEvent extends BusEvent {}

class SubscriptionPaymentSuccessResponseBusEvent extends BusEvent {
  SubscriptionPaymentSuccessResponseBusEvent({
    required this.paymentId,
  });
  final String paymentId;
}

class SubscriptionPaymentFailResponseBusEvent extends BusEvent {
  SubscriptionPaymentFailResponseBusEvent({
    required this.error,
  });
  final String error;
}

class SubscriptionPaymentCancelBusEvent extends BusEvent {}

class SubscriptionPaymentExternalWalletResponseBusEvent extends BusEvent {
  SubscriptionPaymentExternalWalletResponseBusEvent({
    required this.walletName,
  });
  final String walletName;
}

class PurchaseDetailsListUpdatedBusEvent extends BusEvent {}
