class ApiEndpoints {
  const ApiEndpoints._();

  static const health = '/health';

  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authEmailSendCode = '/auth/email/send-code';
  static const authEmailVerify = '/auth/email/verify';
  static const authVerifyCode = '/auth/verify-code';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';

  static const driverProfile = '/driver/profile';
  static const driverProfilePhoto = '/driver/profile/photo';
  static const driverOnline = '/driver/online';
  static const driverOffline = '/driver/offline';
  static const driverLocation = '/driver/location';
  static const driverLocationBatch = '/driver/location/batch';
  static const driverCurrentOrder = '/driver/orders/current';
  static const driverOrdersHistory = '/driver/orders/history';
  static const driverBalance = '/driver/balance';
  static const driverTransactions = '/driver/transactions';
  static String driverOrder(String orderId) => '/driver/orders/$orderId';
  static String driverOrderRoute(String orderId) =>
      '/driver/orders/$orderId/route';
  static String driverDispatcherChatMessages(String orderId) =>
      '/driver/orders/$orderId/chat/dispatcher/messages';

  static String driverAcceptOrder(String orderId) =>
      '/driver/orders/$orderId/accept';
  static String driverRejectOrder(String orderId) =>
      '/driver/orders/$orderId/reject';
  static String driverArrived(String orderId) =>
      '/driver/orders/$orderId/arrived';
  static String driverStartTrip(String orderId) =>
      '/driver/orders/$orderId/start';
  static String driverCompleteTrip(String orderId) =>
      '/driver/orders/$orderId/complete';
  static String driverRatePassenger(String orderId) =>
      '/driver/orders/$orderId/rate-passenger';
}
