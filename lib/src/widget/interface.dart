import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:cloudflare_turnstile/src/controller/interface.dart';

typedef OnTokenRecived = Function(String token);
typedef OnError = Function(String error);

abstract class CloudFlareTurnstile {
  /// This sitekey is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  final String siteKey;

  final TurnstileOptions options;

  final TurnstileController? controller;

  final OnTokenRecived? onTokenRecived;

  final OnError? onError;

  const CloudFlareTurnstile({
    required this.siteKey,
    this.options = const TurnstileOptions(),
    this.controller,
    this.onTokenRecived,
    this.onError,
  });
}
