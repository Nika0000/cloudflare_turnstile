import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:cloudflare_turnstile/src/html_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;

class Turnstile extends StatefulWidget implements i.Turnstile {
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
  final TurnstileOptions options;

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

  Turnstile({
    super.key,
    required this.siteKey,
    this.action,
    this.cData,
    this.baseUrl = 'http://localhost/',
    TurnstileOptions? options,
    this.controller,
    this.onTokenRecived,
    this.onTokenExpired,
    this.onError,
  }) : options = options ?? TurnstileOptions() {
    if (action != null) {
      assert(
        action!.length <= 32 && RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(action!),
        'action must be contain up to 32 characters including _ and -.',
      );
    }

    if (cData != null) {
      assert(
        cData!.length <= 32 && RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(cData!),
        'action must be contain up to 32 characters including _ and -.',
      );
    }
  }

  @override
  State<Turnstile> createState() => _TurnstileState();
}

class _TurnstileState extends State<Turnstile> {
  late String data;

  String? widgetId;

  bool _isWidgetReady = false;

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    disableHorizontalScroll: true,
    verticalScrollBarEnabled: false,
    transparentBackground: true,
    disallowOverScroll: true,
    disableVerticalScroll: true,
    supportZoom: false,
    useWideViewPort: false,
    hardwareAcceleration: false,
  );

  final String _readyJSHandler = 'window.flutter_inappwebview.callHandler(`TurnstileReady`, true);';
  final String _tokenRecivedJSHandler = 'window.flutter_inappwebview.callHandler(`TurnstileToken`, token);';
  final String _errorJSHandler = 'window.flutter_inappwebview.callHandler(`TurnstileError`, code);';
  final String _tokenExpiredJSHandler = 'window.flutter_inappwebview.callHandler(`TokenExpired`);';
  final String _widgetCreatedJSHandler = 'window.flutter_inappwebview.callHandler(`TurnstileWidgetId`, widgetId);';

  @override
  void initState() {
    super.initState();
    data = htmlData(
      siteKey: widget.siteKey,
      action: widget.action,
      cData: widget.cData,
      options: widget.options,
      onTurnstileReady: _readyJSHandler,
      onTokenRecived: _tokenRecivedJSHandler,
      onTurnstileError: _errorJSHandler,
      onTokenExpired: _tokenExpiredJSHandler,
      onWidgetCreated: _widgetCreatedJSHandler,
    );

    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
  }

  _onWebViewCreated(PlatformInAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'TurnstileToken',
      callback: (args) {
        widget.controller?.newToken = args[0];
        widget.onTokenRecived?.call(args[0]);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'TurnstileError',
      callback: (args) {
        widget.onError?.call(args[0]);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'TurnstileWidgetId',
      callback: (args) {
        widgetId = args[0];
        widget.controller?.widgetId = args[0];
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'TurnstileReady',
      callback: (args) {
        setState(() {
          _isWidgetReady = args[0];
        });
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'TokenExpired',
      callback: (args) {
        widget.onTokenExpired?.call();
      },
    );

    widget.controller?.setConnector(controller);
  }

  final double _borderWidth = 0.25;

  Widget get _view => PlatformInAppWebViewWidget(
        PlatformInAppWebViewWidgetCreationParams(
          initialData: InAppWebViewInitialData(
            data: data,
            baseUrl: WebUri(widget.baseUrl),
          ),
          initialSettings: _settings,
          onWebViewCreated: (controller) => _onWebViewCreated(controller as PlatformInAppWebViewController),
          onConsoleMessage: (_, message) {
            if (message.message.contains(RegExp('Turnstile'))) {
              debugPrint(message.message);
              if (message.messageLevel == ConsoleMessageLevel.ERROR) {
                widget.onError?.call(message.message);
              }
            }
          },
          onReceivedError: (_, __, webError) {
            if (webError.type == WebResourceErrorType.CANNOT_CONNECT_TO_HOST) {
              return;
            }

            widget.onError?.call(webError.description);
          },
        ),
      ).build(context);

  @override
  Widget build(BuildContext context) {
    return switch (widget.options.mode) {
      TurnstileMode.invisible => SizedBox.shrink(child: _view),
      _ => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _isWidgetReady ? widget.options.size.width + _borderWidth : 0,
          height: _isWidgetReady ? widget.options.size.height + _borderWidth : 0,
          child: _view,
        ),
    };
  }
}
