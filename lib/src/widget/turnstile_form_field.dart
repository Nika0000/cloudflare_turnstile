import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;

class TurnstileFormField extends FormField<String> implements i.Turnstile {
  /// This [siteKey] is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  ///
  /// It`s likely generated or obtained from the CloudFlare dashboard.
  @override
  final String siteKey;

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

  /// A base url of turnstile Site
  @override
  final String baseUrl;

  /// A Turnstile widget options
  @override
  final TurnstileOptions? options;

  /// A controller for an Turnstile widget
  @override
  final TurnstileController? controller;

  /// A Callback invoked upon success of the challange.
  /// The callback is passed a [token] that can be validated.
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
  @override
  final i.OnTokenRecived? onTokenRecived;

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
  @override
  final i.OnTokenExpired? onTokenExpired;

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
  @override
  final i.OnError? onError;

  ///  Decoration is used when the widget is not valid or the token is null
  final BoxDecoration? decoration;

  /// The style to use for the error text.
  final TextStyle? errorStyle;

  TurnstileFormField({
    super.key,
    required this.siteKey,
    this.action,
    this.cData,
    this.baseUrl = 'http://localhost/',
    this.options,
    this.controller,
    this.onTokenRecived,
    this.onTokenExpired,
    this.onError,
    this.decoration,
    this.errorStyle,
    super.validator,
  }) : super(
          initialValue: null,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (FormFieldState<String> state) {
            bool isVisible = options?.mode != TurnstileMode.invisible && state.hasError;

            final BoxDecoration adaptiveDecoration = isVisible
                ? decoration ??
                    BoxDecoration(
                      border: Border.all(
                        color: Colors.red,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    )
                : const BoxDecoration();

            ///   WidgetsBinding.instance.addPostFrameCallback((_) {
            ///     state.didChange(hasToken);
            ///   });

            /// TODO: Incorrect use of setValue

            // ignore: invalid_use_of_protected_member
            state.setValue(controller?.token);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: adaptiveDecoration,
                  child: Turnstile(
                    siteKey: siteKey,
                    action: action,
                    cData: cData,
                    baseUrl: baseUrl,
                    options: options,
                    controller: controller,
                    onTokenRecived: (token) {
                      state.didChange(token);
                      onTokenRecived?.call(token);
                    },
                    onTokenExpired: () {
                      state.didChange(null);
                      onTokenExpired?.call();
                    },
                    onError: (error) {
                      state.didChange(null);
                      onError?.call(error);
                    },
                  ),
                ),
                if (isVisible)
                  Text(
                    state.errorText!,
                    style: errorStyle ?? const TextStyle(fontSize: 14.0, color: Colors.red, height: 2.0),
                  )
              ],
            );
          },
        );
}
