import 'package:cloudflare_turnstile/src/controller/impl/turnstile_controller_web.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';
import '../interface.dart' as base;

class CloudFlareTurnstile extends StatefulWidget implements base.CloudFlareTurnstile {
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
  State<CloudFlareTurnstile> createState() => _CloudFlareTurnstileState();
}

class _CloudFlareTurnstileState extends State<CloudFlareTurnstile> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('For Mobile'),
    );
  }
}
