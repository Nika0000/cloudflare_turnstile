import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:cloudflare_turnstile/src/html_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;

class CloudFlareTurnstile extends StatefulWidget implements i.CloudFlareTurnstile {
  /// This [siteKey] is associated with the corresponding widget configuration
  /// and is created upon the widget creation.
  ///
  /// It`s likely generated or obtained from the CloudFlare dashboard.
  @override
  final String siteKey;

  /// A Turnstile widget options
  @override
  final TurnstileOptions options;

  /// A base url of turnstile Site
  @override
  final String baseUrl;

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

  const CloudFlareTurnstile({
    super.key,
    required this.siteKey,
    this.baseUrl = 'http://localhost/',
    this.options = const TurnstileOptions(),
    this.controller,
    this.onTokenRecived,
    this.onTokenExpired,
    this.onError,
  });

  @override
  State<CloudFlareTurnstile> createState() => _CloudFlareTurnstileState();
}

class _CloudFlareTurnstileState extends State<CloudFlareTurnstile> {
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

  final double _borderWidth = 2.0;

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
