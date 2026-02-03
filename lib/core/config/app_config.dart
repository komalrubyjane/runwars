/// Application configuration for development and testing modes.
class AppConfig {
  /// Enable mock/test data mode. Set to true to bypass real API calls.
  /// This is useful for development when the backend is not available.
  static const bool useMockData = true;

  /// Base API URL
  static const String apiUrl = 'https://runbackendrun-6d3g5hh5.b4a.run/api/';
}
