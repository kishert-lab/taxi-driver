enum RealtimeEventType {
  syncRequired,
  orderOffer,
  orderOfferExpired,
  orderOfferCancelled,
  orderAccepted,
  orderCancelled,
  passengerCancelled,
  driverLocationUpdated,
  unknown,
}

extension RealtimeEventTypeX on RealtimeEventType {
  static RealtimeEventType fromWire(String event) {
    return switch (event) {
      'sync.required' => RealtimeEventType.syncRequired,
      'order.offer' => RealtimeEventType.orderOffer,
      'order.offer_expired' => RealtimeEventType.orderOfferExpired,
      'order.offer_cancelled' => RealtimeEventType.orderOfferCancelled,
      'order.accepted' => RealtimeEventType.orderAccepted,
      'order.cancelled' => RealtimeEventType.orderCancelled,
      'passenger.cancelled' => RealtimeEventType.passengerCancelled,
      'driver.location_updated' => RealtimeEventType.driverLocationUpdated,
      _ => RealtimeEventType.unknown,
    };
  }
}
