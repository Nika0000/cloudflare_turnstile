// ignore: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/src/controller/interface.dart' as i;
import 'package:webview_flutter/webview_flutter.dart';

class TurnstileController extends ChangeNotifier implements i.TurnstileController<WebViewController> {
  /// The connector associated with the controller.
  @override
  late WebViewController connector;

  String? _token;

  late String _widgetId;

  /// Sets a new connector.
  @override
  void setConnector(newConnector) {
    connector = newConnector;
  }

  /// Get current token
  @override
  String? get token => _token;

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
    _token = null;
    await connector.runJavaScript("""turnstile.reset(`$_widgetId`);""");
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
    final result = await connector.runJavaScriptReturningResult("""turnstile.isExpired(`$_widgetId`);""") as bool;
    return result;
  }

  /// dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}
