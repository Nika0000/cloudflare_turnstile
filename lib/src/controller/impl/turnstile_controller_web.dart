// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:cloudflare_turnstile/src/controller/interface.dart' as i;
import 'package:cloudflare_turnstile/src/widget/interface.dart';
import 'package:flutter/material.dart';

/// Turnstile controller web implementation.
class TurnstileController extends ChangeNotifier
    implements i.TurnstileController<js.JsObject> {
  /// The connector associated with the controller.
  @override
  late js.JsObject connector;

  String? _token;

  String _widgetId = '';

  bool _isReady = false;

  /// Sets a new connector.
  @override
  void setConnector(js.JsObject newConnector) {
    connector = newConnector;
  }

  /// Get current token
  @override
  String? get token => _token;

  /// Sets a new token.
  @override
  set token(String? token) {
    _token = token;
    notifyListeners();
  }

  /// Get a current widget id
  @override
  String get widgetId => _widgetId;

  /// Sets the Turnstile current widget id.
  @override
  set widgetId(String id) => _widgetId = id;

  /// Get a current widget is ready
  @override
  bool get isWidgetReady => _isReady;

  /// Sets a Widget is ready
  @override
  set isWidgetReady(bool isReady) => _isReady = isReady;

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
    _token = null;
    await connector.callMethod('eval', ['''turnstile.reset(`$_widgetId`);''']);
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
    if (!_isReady || _widgetId.isEmpty) {
      return true;
    }
    final result = connector
        .callMethod('eval', ['''turnstile.isExpired(`$_widgetId`);''']);
    return Future.value(result as bool);
  }

  /// dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}
