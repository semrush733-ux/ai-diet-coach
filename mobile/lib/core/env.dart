/// Build-time environment configuration.
///
/// Pass values with --dart-define, e.g.
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
///   flutter run --dart-define=USE_FAKE_API=true   # run without a backend (DEV ONLY)
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// When true, repositories use clearly-labeled in-memory dev fakes instead
  /// of the real API. Never enable in release builds.
  static const useFakeApi =
      bool.fromEnvironment('USE_FAKE_API', defaultValue: false);
}
