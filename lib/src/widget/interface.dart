import 'package:cloudflare_turnstile/src/controller/interface.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';

/// Callback invoked upon successful token reception.
///
/// The callback receives a [token] that can be validated.
typedef OnTokenRecived = Function(String token);

/// Callback invoked when the token expires.
///
/// The callback does not reset the widget.
typedef OnTokenExpired = Function();

/// Callback invoked when an error occurs.
///
/// The callback receives an [error] message, which could be due to network
/// issues or challenge failure.
typedef OnError = Function(String error);

/// Abstract class for CloudFlare Turnstile widget.
abstract class CloudFlareTurnstile {
  /// Create a Cloudflare Turnstile Widget
  CloudFlareTurnstile({
    required this.siteKey,
    this.action,
    this.cData,
    this.baseUrl = 'http://localhost/',
    TurnstileOptions? options,
    this.controller,
    this.onTokenRecived,
    this.onTokenExpired,
    this.onError,
  }) : options = options ?? TurnstileOptions();

  /// This [siteKey] is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  ///
  /// It`s likely generated or obtained from the CloudFlare dashboard.
  final String siteKey;

  /// A customer value that can be used to differentiate widgets under the
  /// same sitekey in analytics and which is returned upon validation.
  ///
  /// This can only contain up to 32 alphanumeric characters including _ and -.
  final String? action;

  /// A customer payload that can be used to attach customer data to the
  /// challenge throughout its issuance and which is returned upon validation.
  ///
  /// This can only contain up to 255 alphanumeric characters including _ and -.
  final String? cData;

  /// A base url of turnstile Site
  final String baseUrl;

  /// A Turnstile widget options
  final TurnstileOptions? options;

  /// A controller for an Turnstile widget
  final TurnstileController<dynamic>? controller;

  /// A Callback invoked upon success of the challange.
  /// The callback is passed a `token` that can be validated.
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '0x000000000000000000000',
  ///   onTokenRecived: (String token) {
  ///     print('Token: $token');
  ///   },
  /// ),
  /// ```
  final OnTokenRecived? onTokenRecived;

  /// A Callback invoke when the token expires and does not
  /// reset the widget.
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '0x000000000000000000000',
  ///   onTokenExpired: () {
  ///     print('Token Expired');
  ///   },
  /// ),
  /// ```
  final OnTokenExpired? onTokenExpired;

  /// A Callback invoke when there is an error
  /// (e.g network error or challange failed).
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '0x000000000000000000000',
  ///   onError: (String error) {
  ///     print('Error: $error');
  ///   },
  /// ),
  /// ```
  ///
  /// Refer to [Client-side errors](https://developers.cloudflare.com/turnstile/troubleshooting/client-side-errors/).
  final OnError? onError;
}
