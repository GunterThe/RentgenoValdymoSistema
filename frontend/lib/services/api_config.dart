class ApiConfig {
  // Keep in sync with Backend launch profile / hosting.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:5158',
  );
}
