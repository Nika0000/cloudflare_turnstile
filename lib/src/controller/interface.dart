import 'package:cloudflare_turnstile/src/widget/interface.dart';

abstract class TurnstileController<T> {
  /// The connector associated with the controller.
  late T connector;

  /// Get current token.
  String? get token;

  /// Sets a new connector.
  void setConnector(T newConnector);

  /// Sets a new token.
  set token(String? token);

  /// Get a current widget id
  String get widgetId;

  /// Get a current widget is ready
  bool get isWidgetReady;

  /// Sets a Widget is ready
  set isWidgetReady(bool isReady);

  /// Sets the Turnstile current widget id.
  set widgetId(String id);

  /// The function can be called when widget mey become expired and
  /// needs to be refreshed.
  ///
  /// This method can only be called when [widgetId] is not null.
  ///
  /// example:
  /// ```dart
  /// // Initialize controller
  /// TurnstileController controller = TurnstileController();
  ///
  /// await controller.refreshToken();
  /// ```
  Future<void> refreshToken();

  /// The function that check if a widget has expired by either
  /// subscription to the [OnTokenExpired] or using isExpired();
  /// function, which returns true if the widget is expired.
  ///
  /// This method can only be called when [widgetId] is not null.
  ///
  ///
  /// example:
  /// ```dart
  /// // Initialize controller
  /// TurnstileController controller = TurnstileController();
  ///
  /// bool isTokenExpired = await controller.isExpired();
  /// print(isTokenExpired);
  /// ```
  Future<bool> isExpired();
}
