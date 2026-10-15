/// Typed API error carried from the data layer to the UI.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Machine-readable code from the backend envelope (e.g. `validation_error`),
  /// or a client-side code (`network`, `timeout`, `unknown`).
  final String code;
  final String message;
  final int? statusCode;

  /// field → list of messages, from 422 validation responses.
  final Map<String, List<String>> fieldErrors;

  bool get isNetwork => code == 'network' || code == 'timeout';
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
