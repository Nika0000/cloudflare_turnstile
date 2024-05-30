// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui;

import 'package:cloudflare_turnstile/src/html_data.dart';
import 'package:cloudflare_turnstile/src/controller/impl/turnstile_controller_web.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;

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
  late html.IFrameElement iframe;
  late String iframeViewType;
  late js.JsObject jsWindowObject;

  final String _jsToDartConnectorFN = 'connect_js_to_flutter';

  String? widgetId;

  bool _isWidgetReady = false;

  @override
  void initState() {
    super.initState();

    iframeViewType = _createViewType();
    iframe = _createIFrame();

    _connectJsToFlutter();

    _registerView(iframeViewType);

    Future.delayed(Duration.zero, () {
      _updateSource();
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
      ..style.height = '100%';

    return iframeElement;
  }

  void _connectJsToFlutter() {
    js.context['$_jsToDartConnectorFN$iframeViewType'] = (js.JsObject window) {
      jsWindowObject = window;

      jsWindowObject['TurnstileToken'] = (message) {
        widget.controller?.newToken = message;
        widget.onTokenRecived?.call(message);
      };

      jsWindowObject['TurnstileError'] = (message) {
        widget.onError?.call(message);
      };

      jsWindowObject['TurnstileWidgetId'] = (message) {
        widgetId = message;
        widget.controller?.widgetId = message;
      };

      jsWindowObject['TurnstileReady'] = (message) {
        setState(() {
          _isWidgetReady = message;
        });
      };

      jsWindowObject['TokenExpired'] = (message) {
        widget.onTokenExpired?.call();
      };

      widget.controller?.setConnector(jsWindowObject);
    };
  }

  void _registerView(String viewType) {
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) => iframe);
  }

  final String _readyJSHandler = 'TurnstileReady(true);';
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
        onTurnstileReady: _readyJSHandler,
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
      {'parent.$_jsToDartConnectorFN$windowDisambiguator && parent.$_jsToDartConnectorFN$windowDisambiguator(window)'},
    );
  }

  String _embedJsInHtmlSource(
    String source,
    Set<String> jsContents,
  ) {
    const newLine = '\n';
    const scriptOpenTag = '<script>';
    const scriptCloseTag = '</script>';
    final jsContent = jsContents.reduce((prev, elem) => prev + newLine * 2 + elem);

    final whatToEmbed = newLine + scriptOpenTag + newLine + jsContent + newLine + scriptCloseTag + newLine;

    final indexToSplit = source.indexOf('</head>');
    final splitSource1 = source.substring(0, indexToSplit);
    final splitSource2 = source.substring(indexToSplit);

    return '$splitSource1$whatToEmbed\n$splitSource2';
  }

  @override
  void dispose() {
    iframe.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width:
          widget.options.mode == TurnstileMode.invisible ? 0.01 : (_isWidgetReady ? widget.options.size.width : 0.01),
      height:
          widget.options.mode == TurnstileMode.invisible ? 0.01 : (_isWidgetReady ? widget.options.size.height : 0.01),
      child: AbsorbPointer(
        child: RepaintBoundary(
          child: HtmlElementView(
            key: widget.key,
            viewType: iframeViewType,
          ),
        ),
      ),
    );
  }
}
