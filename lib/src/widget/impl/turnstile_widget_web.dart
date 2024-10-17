// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui;

import 'package:cloudflare_turnstile/src/controller/impl/turnstile_controller_web.dart';
import 'package:cloudflare_turnstile/src/html_data.dart';
import 'package:cloudflare_turnstile/src/turnstile_exception.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';

/// Cloudflare Turnstile web implementation
class CloudFlareTurnstile extends StatefulWidget implements i.CloudFlareTurnstile {
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
  late html.IFrameElement iframe;
  late String iframeViewType;
  late StreamSubscription<dynamic> iframeOnLoadSubscription;
  late js.JsObject jsWindowObject;

  late bool _isWidgetInteractive;
  late double _widgetHeight = widget.options.size.height;

  final String _jsToDartConnectorFN = 'connect_js_to_flutter';

  String? widgetId;

  bool _isWidgetReady = false;
  TurnstileException? _hasError;

  @override
  void initState() {
    super.initState();

    _isWidgetInteractive = widget.mode != i.TurnstileMode.invisible;

    if (widget.options.theme == TurnstileTheme.auto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final brightness = MediaQuery.of(context).platformBrightness;
        final isDark = brightness == Brightness.dark;
        widget.options.theme = isDark ? TurnstileTheme.dark : TurnstileTheme.light;
      });
    }

    iframeViewType = _createViewType();
    iframe = _createIFrame();

    _connectJsToFlutter();
    _registerView(iframeViewType);

    _updateSource();
    _registerIframeOnLoadCallBack();
  }

  String _createViewType() {
    final iframeId = '_${DateTime.now().microsecondsSinceEpoch}';
    return '_iframe$iframeId';
  }

  html.IFrameElement _createIFrame() {
    final iframeElement = html.IFrameElement()
      ..id = 'id_$iframeViewType'
      ..name = 'name_$iframeViewType'
      ..style.border = 'none'
      ..width = widget.options.size.width.toString()
      ..height = widget.options.size.height.toString()
      ..style.width = '100%'
      ..title = 'CloudFlare_Turnstile'
      ..style.height = '100%';

    return iframeElement;
  }

  void _registerIframeOnLoadCallBack() {
    var attemps = 0;

    _resetWidget();

    iframeOnLoadSubscription = iframe.onLoad.listen((event) {
      Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) async {
          attemps++;

          if (_isWidgetReady) return timer.cancel();

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
        },
      );
    });
  }

  FutureOr<void> _getWidgetDimension() async {
    if (_isWidgetReady) {
      return;
    }

    final result = jsWindowObject.callMethod(
      'eval',
      ['''getWidgetDimensions();'''],
    );

    final val = await Future.value(result) as String;
    final size = jsonDecode(val) as Map<String, dynamic>;

    final height = double.parse(size['height'].toString());

    if (widget.mode != i.TurnstileMode.invisible) {
      if (height <= 0) return;
      _widgetHeight = height.ceilToDouble();
    } else {
      if (height > 0) return;
    }

    setState(() => _isWidgetReady = true);
    widget.controller?.isWidgetReady = _isWidgetReady;
  }

  void _connectJsToFlutter() {
    js.context['$_jsToDartConnectorFN$iframeViewType'] = (js.JsObject window) {
      jsWindowObject = window;

      jsWindowObject['TurnstileToken'] = (String message) {
        widget.controller?.token = message;
        widget.onTokenRecived?.call(message);
      };

      jsWindowObject['TurnstileError'] = (String message) {
        final errorCode = int.tryParse(message) ?? -1;
        _addError(TurnstileException.fromCode(errorCode));
      };

      jsWindowObject['TurnstileWidgetId'] = (String message) {
        widgetId = message;
        widget.controller?.widgetId = message;
      };

      jsWindowObject['TokenExpired'] = (message) {
        widget.onTokenExpired?.call();
      };

      widget.controller?.setConnector(jsWindowObject);
    };
  }

  void _registerView(String viewType) {
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => iframe,
    );
  }

  final String _tokenRecivedJSHandler = 'TurnstileToken(token);';
  final String _errorJSHandler = 'TurnstileError(code);';
  final String _tokenExpiredJSHandler = 'TokenExpired();';
  final String _widgetCreatedJSHandler = 'TurnstileWidgetId(widgetId);';

  void _updateSource() {
    iframe.srcdoc = _embedWebIframeJsConnector(
      htmlData(
        siteKey: widget.siteKey,
        action: widget.action,
        cData: widget.cData,
        options: widget.options,
        onTokenReceived: _tokenRecivedJSHandler,
        onTurnstileError: _errorJSHandler,
        onTokenExpired: _tokenExpiredJSHandler,
        onWidgetCreated: _widgetCreatedJSHandler,
      ),
      iframeViewType,
    );
  }

  String _embedWebIframeJsConnector(String source, String windowDisambiguator) {
    return _embedJsInHtmlSource(
      source,
      {
        'parent.$_jsToDartConnectorFN$windowDisambiguator && parent.$_jsToDartConnectorFN$windowDisambiguator(window)'
      },
    );
  }

  String _embedJsInHtmlSource(
    String source,
    Set<String> jsContents,
  ) {
    const newLine = '\n';
    const scriptOpenTag = '<script>';
    const scriptCloseTag = '</script>';
    final jsContent = jsContents.reduce(
      (prev, elem) => prev + newLine * 2 + elem,
    );

    final whatToEmbed =
        newLine + scriptOpenTag + newLine + jsContent + newLine + scriptCloseTag + newLine;

    final indexToSplit = source.indexOf('</head>');
    final splitSource1 = source.substring(0, indexToSplit);
    final splitSource2 = source.substring(indexToSplit);

    return '$splitSource1$whatToEmbed\n$splitSource2';
  }

  void _resetWidget() {
    setState(() {
      _hasError = null;
      _isWidgetReady = false;
      widget.controller?.error = null;
      widget.controller?.isWidgetReady = false;
    });
  }

  void _addError(TurnstileException error) {
    setState(() {
      _hasError = error;
      _isWidgetReady = error.retryable;
      widget.controller?.error = error;
      widget.controller?.isWidgetReady = error.retryable;
    });
  }

  late final Widget _view = HtmlElementView(
    key: widget.key,
    viewType: iframeViewType,
  );

  @override
  void dispose() {
    iframeOnLoadSubscription.cancel();
    iframe.remove();
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
        // call only when turnstile dont have buildin method to display error
        return widget.errorBuilder?.call(context, _hasError!) ?? const SizedBox();
      }
    }

    if (!_isWidgetInteractive) {
      return SizedBox(
        width: 0.01,
        height: 0.01,
        child: _view,
      );
    }

    return SizedBox(
      width: widget.options.size.width,
      height: widget.options.size.height,
      child: AbsorbPointer(
        child: RepaintBoundary(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: _widgetHeight,
            child: _view,
          ),
        ),
      ),
    );
  }
}
