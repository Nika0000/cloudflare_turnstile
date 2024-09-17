import 'package:cloudflare_turnstile/src/controller/interface.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';

/// Facade class for Cloudflare Turnstile.
class CloudFlareTurnstile extends StatelessWidget
    implements i.CloudFlareTurnstile {
  /// Create a Cloudflare Turnstile Widget
  ///
  /// /// The [siteKey] is required and associates this widget with a Cloudflare Turnstile instance.
  /// [mode] defines the Turnstile widget behavior (e.g., managed, non-interactive, or invisible).
  /// Additional parameters like [action], [cData], [controller], and various options
  /// customize the widget's behavior.
  CloudFlareTurnstile({
    required this.siteKey,
    required this.mode,
    super.key,
    this.action,
    this.cData,
    this.baseUrl = 'http://localhost/',
    TurnstileOptions? options,
    this.controller,
    this.onTokenRecived,
    this.onTokenExpired,
    this.errorBuilder,
  }) : options = options ?? TurnstileOptions();

  /// This [siteKey] is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  ///
  /// It`s likely generated or obtained from the CloudFlare dashboard.
  @override
  final String siteKey;

  /// The Turnstile widget mode.
  ///
  /// The three available modes are:
  /// [TurnstileMode.managed] - Cloudflare will use information from the visitor
  /// to decide if an interactive challange should be used. if we show an interaction,
  /// the user will be prmpted to check a box
  ///
  /// [TurnstileMode.nonInteractive] - Users will see a widget with a loading bar
  /// while the browser challanges run. Users will never be required or prompted
  /// to interact with the widget
  ///
  /// [TurnstileMode.invisible] - Users will not see a widget or any indication that
  /// an invisible browser challange is in progress. invisible challanges should take
  /// a few seconds to complete.
  ///
  /// Refer to [Widget types](https://developers.cloudflare.com/turnstile/concepts/widget-types/)
  @override
  final i.TurnstileMode mode;

  /// A customer value that can be used to differentiate widgets under the
  /// same sitekey in analytics and which is returned upon validation.
  ///
  /// This can only contain up to 32 alphanumeric characters including _ and -.
  @override
  final String? action;

  /// A customer payload that can be used to attach customer data to the
  /// challenge throughout its issuance and which is returned upon validation.
  ///
  /// This can only contain up to 255 alphanumeric characters including _ and -.
  @override
  final String? cData;

  /// The base URL of the Turnstile site.
  ///
  /// Defaults to 'http://localhost/'.
  @override
  final String baseUrl;

  /// Configuration options for the Turnstile widget.
  ///
  /// If no options are provided, the default [TurnstileOptions] are used.
  @override
  final TurnstileOptions options;

  /// A controller for managing interactions with the Turnstile widget.
  @override
  final TurnstileController<dynamic>? controller;

  /// A Callback invoked upon success of the challange.
  /// The callback is passed a `token` that can be validated.
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '3x00000000000000000000FF',
  ///   onTokenRecived: (String token) {
  ///     print('Token: $token');
  ///   },
  /// ),
  /// ```
  @override
  final i.OnTokenRecived? onTokenRecived;

  /// A Callback invoke when the token expires and does not
  /// reset the widget.
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '3x00000000000000000000FF',
  ///   onTokenExpired: () {
  ///     print('Token Expired');
  ///   },
  /// ),
  /// ```
  @override
  final i.OnTokenExpired? onTokenExpired;

  /// A Callback invoke when there is an error
  /// (e.g network error or challange failed).
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '3x00000000000000000000FF',
  ///   errorBuilder: (context, error) {
  ///     return Text(error.message);
  ///   },
  /// ),
  /// ```
  ///
  /// Refer to [Client-side errors](https://developers.cloudflare.com/turnstile/troubleshooting/client-side-errors/).
  @override
  final i.ErrorBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError(
        'Cannot call build on the facade implementation of CloudFlareTurnstile.');
  }
}
