import 'package:cloudflare_turnstile/src/controller/interface.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as base;

class CloudFlareTurnstile extends StatelessWidget implements base.CloudFlareTurnstile {
  @override
  final String siteKey;

  @override
  final TurnstileOptions options;

  @override
  final TurnstileController? controller;

  @override
  final base.OnTokenRecived? onTokenRecived;

  @override
  final base.OnError? onError;

  const CloudFlareTurnstile({
    super.key,
    required this.siteKey,
    this.options = const TurnstileOptions(),
    this.controller,
    this.onTokenRecived,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Cannot call build on the facade implementation of WebViewX.');
  }
}
