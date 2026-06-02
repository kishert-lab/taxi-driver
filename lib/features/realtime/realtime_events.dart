enum RealtimeEventType {
  syncRequired,
  orderOffer,
  orderOfferExpired,
  orderOfferCancelled,
  orderAccepted,
  orderCancelled,
  passengerCancelled,
  chatMessage,
  driverLocationUpdated,
  unknown,
}

extension RealtimeEventTypeX on RealtimeEventType {
  static RealtimeEventType fromWire(String event) {
    return switch (event) {
      'sync.required' => RealtimeEventType.syncRequired,
      'sync_required' => RealtimeEventType.syncRequired,
      'order.offer' => RealtimeEventType.orderOffer,
      'order_offer' => RealtimeEventType.orderOffer,
      'order.offered' => RealtimeEventType.orderOffer,
      'driver.order.offer' => RealtimeEventType.orderOffer,
      'order.offer_expired' => RealtimeEventType.orderOfferExpired,
      'order_offer_expired' => RealtimeEventType.orderOfferExpired,
      'order.offer_cancelled' => RealtimeEventType.orderOfferCancelled,
      'order_offer_cancelled' => RealtimeEventType.orderOfferCancelled,
      'order.accepted' => RealtimeEventType.orderAccepted,
      'order_accepted' => RealtimeEventType.orderAccepted,
      'order.cancelled' => RealtimeEventType.orderCancelled,
      'order_cancelled' => RealtimeEventType.orderCancelled,
      'passenger.cancelled' => RealtimeEventType.passengerCancelled,
      'passenger_cancelled' => RealtimeEventType.passengerCancelled,
      'chat.message' => RealtimeEventType.chatMessage,
      'chat_message' => RealtimeEventType.chatMessage,
      'chat.new_message' => RealtimeEventType.chatMessage,
      'chat_new_message' => RealtimeEventType.chatMessage,
      'driver.chat.message' => RealtimeEventType.chatMessage,
      'dispatcher.chat.message' => RealtimeEventType.chatMessage,
      'order.chat.message' => RealtimeEventType.chatMessage,
      'driver.location_updated' => RealtimeEventType.driverLocationUpdated,
      'driver_location_updated' => RealtimeEventType.driverLocationUpdated,
      _ => RealtimeEventType.unknown,
    };
  }
}
