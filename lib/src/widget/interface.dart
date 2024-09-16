import 'package:cloudflare_turnstile/src/controller/interface.dart';
import 'package:cloudflare_turnstile/src/turnstile_exception.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';

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
/// The callback receives a [TurnstileException] object, [error], which provides
/// details about the error, such as network issues or a challenge failure.
///
/// The [ErrorBuilder] callback is used to build a custom error widget.
/// This widget will only be displayed if the TurnstileException's `retryable`
/// property is set to `true`. For non-retriable errors, this callback may still
/// be invoked, but the display or handling of these errors might be managed
/// internally by the Turnstile widget or handled differently.
typedef ErrorBuilder = Widget Function(
  BuildContext context,
  TurnstileException error,
);

/// Abstract class representing a Cloudflare Turnstile widget.
abstract class CloudFlareTurnstile {
  /// Create a Cloudflare Turnstile Widget
  ///
  /// /// The [siteKey] is required and associates this widget with a Cloudflare Turnstile instance.
  /// [mode] defines the Turnstile widget behavior (e.g., managed, non-interactive, or invisible).
  /// Additional parameters like [action], [cData], [controller], and various options
  /// customize the widget's behavior.
  CloudFlareTurnstile({
    required this.siteKey,
    required this.mode,
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
  final TurnstileMode mode;

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

  /// The base URL of the Turnstile site.
  ///
  /// Defaults to 'http://localhost/'.
  final String baseUrl;

  /// Configuration options for the Turnstile widget.
  ///
  /// If no options are provided, the default [TurnstileOptions] are used.
  final TurnstileOptions? options;

  /// A controller for managing interactions with the Turnstile widget.
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
  /// This widget will only be displayed if the TurnstileException's `retryable`
  /// property is set to `true`. For non-retriable errors, this callback may still
  /// be invoked, but the display or handling of these errors might be managed
  /// internally by the Turnstile widget or handled differently.
  ///
  /// example:
  /// ```dart
  /// CloudFlareTurnstile(
  ///   siteKey: '0x000000000000000000000',
  ///   errorBuilder: (context, error) {
  ///     return Text(error.message);
  ///   },
  /// ),
  /// ```
  ///
  /// Refer to [Client-side errors](https://developers.cloudflare.com/turnstile/troubleshooting/client-side-errors/).
  final ErrorBuilder? errorBuilder;
}

/// Defines the modes for the Cloudflare Turnstile widget.
enum TurnstileMode {
  /// Managed Mode.
  ///
  /// The widget requires user interaction.
  managed,

  /// Non-Interaction mode.
  ///
  /// The widget does not require user interaction.
  nonInteractive,

  /// Invisible mode
  ///
  /// The widget is invisible to the user
  invisible,
}
