abstract class TurnstileController<T> {
  late T connector;

  String get token;

  void setConnector(T newConnector);

  set newToken(String token);

  set widgetId(String id);

  Future<void> refreshToken();

  Future<bool> isExpired();
}
