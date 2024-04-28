// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/src/controller/interface.dart' as i;

class TurnstileController extends ChangeNotifier implements i.TurnstileController<js.JsObject> {
  late String _token;

  late String _widgetId;

  @override
  String get token => _token;

  @override
  set newToken(String token) {
    _token = token;
    notifyListeners();
  }

  @override
  set widgetId(String id) => _widgetId = id;

  Future<void> refresh() async {}

  @override
  late js.JsObject connector;

  @override
  void setConnector(js.JsObject newConnector) {
    connector = newConnector;
  }

  @override
  Future<void> refreshToken() async {
    await connector.callMethod('refreshToken', [_widgetId]);
  }

  @override
  Future<bool> isExpired() async {
    final result = connector.callMethod('isExpired', [_widgetId]);
    return Future.value(result ?? true);
  }
}

/* 

  /// callback invoked when the token expires and does not reset the widget.
  final Function()? onTokenExpired;

  /// callback invoked when the challenge presents an interactive
  /// challenge but was not solved within a given time. A callback will
  /// reset the widget to allow a visitor to solve the challenge again.
  final Function()? onTimeout;

  
 */