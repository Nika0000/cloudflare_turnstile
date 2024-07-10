// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:cloudflare_turnstile/src/html_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;

import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CloudFlareTurnstile extends StatefulWidget implements i.CloudFlareTurnstile {
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

  CloudFlareTurnstile({
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
  State<CloudFlareTurnstile> createState() => _CloudFlareTurnstileState();
}

class _CloudFlareTurnstileState extends State<CloudFlareTurnstile> {
  late final WebViewController _controller;

  late String data;

  String? widgetId;

  bool _isWidgetReady = false;

  bool _isWidgetInteractive = false;

  final double _widgetWidth = TurnstileSize.normal.width;
  double _widgetHeight = TurnstileSize.normal.height;

  final String _tokenRecivedJSHandler = 'TurnstileToken.postMessage(token);';
  final String _errorJSHandler = 'TurnstileError.postMessage(code);';
  final String _tokenExpiredJSHandler = 'TokenExpired.postMessage();';
  final String _widgetCreatedJSHandler = 'TurnstileWidgetId.postMessage(widgetId);';

  @override
  void initState() {
    super.initState();

    _isWidgetInteractive = widget.options.mode != TurnstileMode.invisible;

    data = htmlData(
      siteKey: widget.siteKey,
      action: widget.action,
      cData: widget.cData,
      options: widget.options,
      onTokenRecived: _tokenRecivedJSHandler,
      onTurnstileError: _errorJSHandler,
      onTokenExpired: _tokenExpiredJSHandler,
      onWidgetCreated: _widgetCreatedJSHandler,
    );

    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = AndroidWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    // Enable HybridComposition
    if (Platform.isAndroid) {
      AndroidWebViewWidgetCreationParams(
        displayWithHybridComposition: true,
        controller: controller.platform,
      );
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setOnConsoleMessage((mes) {
        if (mes.level == JavaScriptLogLevel.warning) {
          if (mes.message.contains(RegExp('Turnstile'))) {
            if (kDebugMode) {
              debugPrint(mes.message);
            }
          }
        }
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (c) async {
            if (widget.options.mode == TurnstileMode.auto) {
              RegExp jsonFormatRegex = RegExp(r'^"|"$|\\');

              var result = await _controller.runJavaScriptReturningResult("""getWidgetDimensions()""");

              String jsonData = result.toString();

              String jsonWithoutOuterQuotes = jsonData.replaceAll(jsonFormatRegex, '');
              Map<String, dynamic> size = jsonDecode(jsonWithoutOuterQuotes);

              //double width = size['width'].toDouble();
              double height = size['height'].toDouble();

              setState(() {
                if (height > 0) {
                  //_widgetWidth = width;
                  _widgetHeight = height;
                  _isWidgetInteractive = true;
                } else {
                  _isWidgetInteractive = false;
                }

                _isWidgetReady = true;
              });
            } else {
              setState(() {
                if (widget.options.mode != TurnstileMode.invisible) {
                  _widgetHeight = _widgetHeight + 5.0;
                }
                _isWidgetReady = true;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.errorType == WebResourceErrorType.hostLookup) {
              widget.onError?.call('Network connection error');
            }
          },
          onNavigationRequest: (_) => NavigationDecision.prevent,
          onHttpAuthRequest: (_) => NavigationDecision.prevent,
          onHttpError: (error) {
            if (error.response != null && error.response!.statusCode >= 500) {
              widget.onError?.call('Cloudflare Service returns server error');
            }
          },
        ),
      )
      ..enableZoom(false);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController).setOnPlatformPermissionRequest(
        (request) => request.deny(),
      );
    }

    _controller = controller;

    widget.controller?.setConnector(controller);

    _createChannels();

    _controller.loadHtmlString(
      data,
      baseUrl: widget.baseUrl,
    );
  }

  _createChannels() {
    _controller.addJavaScriptChannel(
      'TurnstileToken',
      onMessageReceived: (message) {
        widget.controller?.newToken = message.message;
        widget.onTokenRecived?.call(message.message);
      },
    );

    _controller.addJavaScriptChannel(
      'TurnstileError',
      onMessageReceived: (message) {
        widget.onError?.call(message.message);
      },
    );

    _controller.addJavaScriptChannel(
      'TurnstileWidgetId',
      onMessageReceived: (message) {
        widgetId = message.message;
        widget.controller?.widgetId = message.message;
      },
    );

    _controller.addJavaScriptChannel(
      'TurnstileReady',
      onMessageReceived: (message) {
        setState(() {
          _isWidgetReady = true;
        });
      },
    );
    _controller.addJavaScriptChannel(
      'TokenExpired',
      onMessageReceived: (message) {
        widget.onTokenExpired?.call();
      },
    );
  }

  late final Widget _view = WebViewWidget(
    controller: _controller,
  ).build(context);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isWidgetInteractive
        ? SizedBox(
            width: _isWidgetReady ? TurnstileSize.normal.width : 0,
            height: _isWidgetReady ? TurnstileSize.normal.height : 0,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: _widgetHeight,
              maxWidth: _widgetWidth,
              child: _view,
            ),
          )
        : SizedBox.shrink(
            child: _view,
          );
  }
}
