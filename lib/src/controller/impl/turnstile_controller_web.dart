// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/src/controller/interface.dart' as i;

class TurnstileController extends ChangeNotifier implements i.TurnstileController<js.JsObject> {
  /// The connector associated with the controller.
  @override
  late js.JsObject connector;

  late String _token;

  late String _widgetId;

  /// Sets a new connector.
  @override
  void setConnector(js.JsObject newConnector) {
    connector = newConnector;
  }

  /// Get current token
  @override
  String get token => _token;

  /// Sets a new token.
  @override
  set newToken(String token) {
    _token = token;
    notifyListeners();
  }

  /// Sets the Turnstile current widget id.
  @override
  set widgetId(String id) => _widgetId = id;

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
    await connector.callMethod('eval', ["""turnstile.reset(`$_widgetId`);"""]);
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
  Future<bool> isExpired() async {
    final result = connector.callMethod('eval', ["""turnstile.isExpired(`$_widgetId`);"""]);
    return Future.value(result ?? true);
  }

  /// dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}
