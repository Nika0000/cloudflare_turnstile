// ignore: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/src/controller/interface.dart' as i;

class TurnstileController extends ChangeNotifier implements i.TurnstileController<dynamic> {
  /// The connector associated with the controller.
  @override
  late dynamic connector;

  /// Get current token
  @override
  String get token => throw UnimplementedError('Cannot call this function on the facade.');

  /// Sets a new connector.
  @override
  void setConnector(newConnector) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Sets a new token.
  @override
  set newToken(String token) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

  /// Sets the Turnstile current widget id.
  @override
  set widgetId(String id) {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

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
  @override
  Future<void> refreshToken() async {
    throw UnimplementedError('Cannot call this function on the facade.');
  }

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
  @override
  Future<bool> isExpired() {
    throw UnimplementedError('Cannot call this function on the facade.');
  }
}
