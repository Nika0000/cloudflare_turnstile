import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:cloudflare_turnstile/src/controller/impl/turnstile_controller.dart';
import 'package:cloudflare_turnstile/src/html_data.dart';
import 'package:cloudflare_turnstile/src/turnstile_exception.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Cloudflare Turnstile mobile implementation
class CloudFlareTurnstile extends StatefulWidget
    implements i.CloudFlareTurnstile {
  /// Create a Cloudflare Turnstile Widget
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

    assert(
      this.options.retryInterval.inMilliseconds > 0 &&
          this.options.retryInterval.inMilliseconds <= 900000,
      'Duration must be greater than 0 and less than or equal to 900000 milliseconds.',
    );

    assert(
      !(mode == i.TurnstileMode.invisible &&
          this.options.refreshExpired == TurnstileRefreshExpired.manual),
      '${this.options.refreshExpired} is impossible in $mode, consider using TurnstileRefreshExpired.auto or TurnstileRefreshExpired.never',
    );

    assert(
      !(mode == i.TurnstileMode.invisible &&
          this.options.refreshTimeout != TurnstileRefreshTimeout.auto),
      '${this.options.refreshTimeout} has no effect on an $mode widget.',
    );

    assert(
      !(mode == i.TurnstileMode.nonInteractive &&
          this.options.refreshTimeout != TurnstileRefreshTimeout.auto),
      '${this.options.refreshTimeout} has no effect on an $mode widget.',
    );
  }

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
  final TurnstileController? controller;

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
  /// This widget will only be displayed if the TurnstileException's `retryable`
  /// property is set to `true`. For non-retriable errors, this callback may still
  /// be invoked, but the display or handling of these errors might be managed
  /// internally by the Turnstile widget or handled differently.
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
  State<CloudFlareTurnstile> createState() => _CloudFlareTurnstileState();
}

class _CloudFlareTurnstileState extends State<CloudFlareTurnstile> {
  late final WebViewController _controller;

  late String data;

  String? widgetId;

  bool _isWidgetReady = false;
  TurnstileException? _hasError;

  late bool _isWidgetInteractive;

  late double _widgetWidth = widget.options.size == TurnstileSize.flexible
      ? TurnstileSize.normal.width
      : widget.options.size.width;
  late double _widgetHeight = widget.options.size.height;

  final String _tokenRecivedJSHandler = 'TurnstileToken.postMessage(token);';
  final String _errorJSHandler = 'TurnstileError.postMessage(code);';
  final String _tokenExpiredJSHandler = 'TokenExpired.postMessage();';
  final String _widgetCreatedJSHandler =
      'TurnstileWidgetId.postMessage(widgetId);';

  @override
  void initState() {
    super.initState();

    _isWidgetInteractive = widget.mode != i.TurnstileMode.invisible;

    if (widget.options.theme == TurnstileTheme.auto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final brightness = MediaQuery.of(context).platformBrightness;
        final isDark = brightness == Brightness.dark;
        widget.options.theme =
            isDark ? TurnstileTheme.dark : TurnstileTheme.light;
      });
    }

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

    final controller = WebViewController.fromPlatformCreationParams(params);

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
            final description = mes.message.split('] ')[1];
            dev.log(description, level: 800, name: 'cloudflare_turnstile');
          }
        }
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (c) async {
            var attemps = 0;

            Timer.periodic(const Duration(microseconds: 2500), (timer) async {
              attemps++;

              if (_isWidgetReady || !mounted) return timer.cancel();

              await _getWidgetDimension();

              if (attemps >= 3) {
                timer.cancel();

                if (!_isWidgetReady) {
                  dev.log(
                    'Widget mode mismatch: The current widget mode is ${widget.mode.name}, which may not match the mode set in the Cloudflare Turnstile dashboard. Please verify the widget mode in the Cloudflare dashboard settings.',
                    name: 'cloudflare_turnstile',
                    level: 800,
                  );
                }

                setState(() => _isWidgetReady = true);
                widget.controller?.isWidgetReady = _isWidgetReady;
              }
            });

            // TODO: The current method for handling flexible sizes by injecting
            // custom styles is not ideal and needs improvement.
            if (widget.options.size == TurnstileSize.flexible) {
              await _controller.runJavaScript("""
                const style = document.createElement('style');
                style.innerHTML = `
                  #cf-turnstile {
                      width: calc(100% - 3px);
                      margin: auto;
                  }
                `;
                document.head.appendChild(style);
              """);
            }
          },
          onPageStarted: (_) => _resetWidget(),
          onWebResourceError: (error) {
            if (error.errorType == WebResourceErrorType.hostLookup && mounted) {
              setState(() {
                _hasError = const TurnstileException(
                  'Server or proxy hostname lookup failed.',
                );

                widget.controller?.error = _hasError;

                _isWidgetReady = false;
                widget.controller?.isWidgetReady = _isWidgetReady;
              });
            }
          },
          onNavigationRequest: (request) {
            if (Platform.isIOS) {
              final uri = Uri.tryParse(request.url);
              final baseUri = Uri.tryParse(widget.baseUrl);

              if (uri?.host == 'challenges.cloudflare.com' ||
                  uri?.host == baseUri?.host ||
                  request.url == 'about:srcdoc' ||
                  request.url == 'about:blank') {
                return NavigationDecision.navigate;
              } else {
                return NavigationDecision.prevent;
              }
            } else {
              return NavigationDecision.prevent;
            }
          },
          onHttpAuthRequest: (_) => NavigationDecision.prevent,
          onHttpError: (error) {
            if (error.response != null && error.response!.statusCode >= 500) {
              setState(() {
                _hasError = TurnstileException(
                  'Server returned HTTP status ${error.response!.statusCode}',
                );
                _isWidgetReady = false;
                widget.controller?.error = _hasError;
                widget.controller?.isWidgetReady = _isWidgetReady;
              });
            }
          },
        ),
      )
      ..enableZoom(false);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setOnPlatformPermissionRequest(
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

  FutureOr<void> _getWidgetDimension() async {
    if (_isWidgetReady) {
      return;
    }

    final jsonFormatRegex = RegExp(r'^"|"$|\\');

    final result = await _controller.runJavaScriptReturningResult(
      '''getWidgetDimensions()''',
    );

    final jsonData = result.toString();

    final jsonWithoutOuterQuotes = jsonData.replaceAll(
      jsonFormatRegex,
      '',
    );

    final size = jsonDecode(jsonWithoutOuterQuotes) as Map<String, dynamic>?;
    if (size == null) return;

    final height = double.parse(size['height'].toString());
    final width = double.parse(size['width'].toString());

    if (widget.mode != i.TurnstileMode.invisible) {
      if (height <= 0) return;
      _widgetHeight = height;
      _widgetWidth = width;
    } else {
      if (height > 0) return;
    }

    setState(() => _isWidgetReady = true);
    widget.controller?.isWidgetReady = _isWidgetReady;
  }

  void _createChannels() {
    _controller
      ..addJavaScriptChannel(
        'TurnstileToken',
        onMessageReceived: (message) {
          if (!mounted) return;
          widget.controller?.token = message.message;
          widget.onTokenRecived?.call(message.message);
        },
      )
      ..addJavaScriptChannel(
        'TurnstileError',
        onMessageReceived: (message) {
          if (_hasError != null) return;
          final errorCode = int.tryParse(message.message) ?? -1;
          _addError(TurnstileException.fromCode(errorCode));
        },
      )
      ..addJavaScriptChannel(
        'TurnstileWidgetId',
        onMessageReceived: (message) {
          if (!mounted) return;
          widgetId = message.message;
          widget.controller?.widgetId = message.message;
        },
      )
      ..addJavaScriptChannel(
        'TokenExpired',
        onMessageReceived: (message) {
          if (!mounted) return;
          widget.onTokenExpired?.call();
        },
      );
  }

  void _resetWidget() {
    if (!mounted) return;
    setState(() {
      _hasError = null;
      _isWidgetReady = false;
      widget.controller?.error = null;
      widget.controller?.isWidgetReady = false;
    });
  }

  void _addError(TurnstileException error) {
    if (!mounted) return;
    setState(() {
      _hasError = error;
      _isWidgetReady = error.retryable;
      widget.controller?.error = error;
      widget.controller?.isWidgetReady = error.retryable;
    });
  }

  Offset _getCorrectSize(double width, double height) {
    var dx = _widgetWidth - width;
    var dy = _widgetHeight - height;

    if (widget.options.size == TurnstileSize.flexible) {
      if (_widgetWidth <= TurnstileSize.normal.width && dx > 0) {
        dx = (TurnstileSize.normal.width - _widgetWidth).ceilToDouble();
      }
    }

    if (dx < 0) dx = 0;
    if (dy < 0) dy = 0;

    return Offset(dx, dy);
  }

  late final Widget _view = WebViewWidget(
    controller: _controller,
  );

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return the custom error widget if the error is retriable or if the
    // Turnstile widget does not have a built-in method for displaying errors.
    // Otherwise, return an empty widget.
    if (_hasError != null) {
      if (_hasError!.retryable && widget.mode != i.TurnstileMode.invisible) {
        widget.errorBuilder?.call(context, _hasError!);
      } else {
        return widget.errorBuilder?.call(context, _hasError!) ??
            const SizedBox.shrink();
      }
    }

    if (!_isWidgetInteractive) {
      return SizedBox.shrink(
        child: _view,
      );
    }

    return SizedBox(
      width: widget.options.size.width,
      height: widget.options.size.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final offset = _getCorrectSize(
            constraints.maxWidth,
            widget.options.size.height,
          );

          return OverflowBox(
            alignment: Alignment.topCenter,
            maxWidth: constraints.maxWidth + offset.dx,
            maxHeight: widget.options.size.height + offset.dy,
            child: Opacity(
              opacity: _isWidgetReady ? 1.0 : 0.0,
              child: _view,
            ),
          );
        },
      ),
    );
  }
}
