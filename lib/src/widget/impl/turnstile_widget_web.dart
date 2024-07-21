// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui;

import 'package:cloudflare_turnstile/src/controller/impl/turnstile_controller_web.dart';
import 'package:cloudflare_turnstile/src/html_data.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';

/// Cloudflare Turnstile web implementation
class CloudFlareTurnstile extends StatefulWidget
    implements i.CloudFlareTurnstile {
  /// Create a Cloudflare Turnstile Widget
  CloudFlareTurnstile({
    required this.siteKey,
    super.key,
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

  @override
  State<CloudFlareTurnstile> createState() => _CloudFlareTurnstileState();
}

class _CloudFlareTurnstileState extends State<CloudFlareTurnstile> {
  late html.IFrameElement iframe;
  late String iframeViewType;
  late StreamSubscription<dynamic> iframeOnLoadSubscription;
  late js.JsObject jsWindowObject;

  late bool _isWidgetInteractive;

  final double _widgetWidth = TurnstileSize.normal.width;
  double _widgetHeight = TurnstileSize.normal.height;

  final String _jsToDartConnectorFN = 'connect_js_to_flutter';

  String? widgetId;

  bool _isWidgetReady = false;

  @override
  void initState() {
    super.initState();

    _isWidgetInteractive = widget.options.mode == TurnstileMode.managed;

    if (widget.options.theme == TurnstileTheme.auto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final brightness = MediaQuery.of(context).platformBrightness;
        final isDark = brightness == Brightness.dark;
        widget.options.theme =
            isDark ? TurnstileTheme.dark : TurnstileTheme.light;
      });
    }

    iframeViewType = _createViewType();
    iframe = _createIFrame();

    _connectJsToFlutter();
    _registerView(iframeViewType);

    Future.delayed(Duration.zero, () {
      _updateSource();
      _registerIframeOnLoadCallBack();
    });
  }

  String _createViewType() {
    final iframeId = '_${DateTime.now().microsecondsSinceEpoch.toString()}';
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
    iframeOnLoadSubscription = iframe.onLoad.listen((event) async {
      Future.delayed(Duration.zero, _detectWidgetMode);
    });
  }

  Future<void> _detectWidgetMode() async {
    if (widget.options.mode == TurnstileMode.auto) {
      final result = jsWindowObject.callMethod(
        'eval',
        ['''getWidgetDimensions();'''],
      );

      await Future.value(result).then((val) {
        final size = jsonDecode(val as String);

        // double width = size['width'];
        final height = size['height'] as double;

        setState(
          () {
            // check if widget have visible content
            if (height > 0) {
              // _widgetWidth = width;
              _widgetHeight = height;
              _isWidgetInteractive = true;
            } else {
              _isWidgetInteractive = false;
            }

            _isWidgetReady = true;
          },
        );
      });
    } else {
      setState(() => _isWidgetReady = true);
    }

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
        widget.onError?.call(message);
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
        onTokenRecived: _tokenRecivedJSHandler,
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

    final whatToEmbed = newLine +
        scriptOpenTag +
        newLine +
        jsContent +
        newLine +
        scriptCloseTag +
        newLine;

    final indexToSplit = source.indexOf('</head>');
    final splitSource1 = source.substring(0, indexToSplit);
    final splitSource2 = source.substring(indexToSplit);

    return '$splitSource1$whatToEmbed\n$splitSource2';
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
    return _isWidgetInteractive
        ? SizedBox(
            width: TurnstileSize.normal.width,
            height: TurnstileSize.normal.height,
            child: AbsorbPointer(
              child: RepaintBoundary(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxWidth: _widgetWidth,
                  maxHeight: _widgetHeight,
                  child: _view,
                ),
              ),
            ),
          )
        : SizedBox(
            width: 0.01,
            height: 0.01,
            child: _view,
          );
  }
}
