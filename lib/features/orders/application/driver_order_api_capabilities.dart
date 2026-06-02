class DriverOrderApiCapabilities {
  const DriverOrderApiCapabilities();

  bool supportsAction(String action) {
    return switch (action) {
      'accept' => true,
      'reject' => true,
      'arriving' => true,
      'arrived' => true,
      'start' => true,
      'complete' => true,
      'call_passenger' => true,
      _ => false,
    };
  }

  bool get supportsCancel => false;
}
