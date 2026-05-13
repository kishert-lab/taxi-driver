class ApiEndpoints {
  const ApiEndpoints._();

  static const health = '/api/v1/health';

  static const authRegister = '/api/v1/auth/register';
  static const authLogin = '/api/v1/auth/login';
  static const authEmailSendCode = '/api/v1/auth/email/send-code';
  static const authEmailVerify = '/api/v1/auth/email/verify';
  static const authVerifyCode = '/api/v1/auth/verify-code';
  static const authRefresh = '/api/v1/auth/refresh';
  static const authLogout = '/api/v1/auth/logout';

  static const driverProfile = '/api/v1/driver/profile';
  static const driverProfilePhoto = '/api/v1/driver/profile/photo';
  static const driverOnline = '/api/v1/driver/online';
  static const driverOffline = '/api/v1/driver/offline';
  static const driverLocation = '/api/v1/driver/location';
  static const driverLocationBatch = '/api/v1/driver/location/batch';
  static const driverCurrentOrder = '/api/v1/driver/orders/current';
  static const driverOrdersHistory = '/api/v1/driver/orders/history';
  static const driverBalance = '/api/v1/driver/balance';
  static const driverTransactions = '/api/v1/driver/transactions';

  static String driverAcceptOrder(String orderId) =>
      '/api/v1/driver/orders/$orderId/accept';
  static String driverRejectOrder(String orderId) =>
      '/api/v1/driver/orders/$orderId/reject';
  static String driverArrived(String orderId) =>
      '/api/v1/driver/orders/$orderId/arrived';
  static String driverStartTrip(String orderId) =>
      '/api/v1/driver/orders/$orderId/start';
  static String driverCompleteTrip(String orderId) =>
      '/api/v1/driver/orders/$orderId/complete';
  static String driverRatePassenger(String orderId) =>
      '/api/v1/driver/orders/$orderId/rate-passenger';
}
