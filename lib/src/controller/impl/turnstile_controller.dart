// ignore: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/src/controller/interface.dart' as i;

class TurnstileController extends ChangeNotifier implements i.TurnstileController<dynamic> {
  @override
  String get token => throw UnimplementedError();

  @override
  set newToken(String token) {
    throw UnimplementedError();
  }

  Future<void> refresh() async {
    throw UnimplementedError();
  }

  @override
  late dynamic connector;

  @override
  void setConnector(newConnector) {
    throw UnimplementedError();
  }

  @override
  Future<void> refreshToken() async {
    throw UnimplementedError();
  }

  @override
  set widgetId(String id) {}

  @override
  Future<bool> isExpired() {
    throw UnimplementedError();
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