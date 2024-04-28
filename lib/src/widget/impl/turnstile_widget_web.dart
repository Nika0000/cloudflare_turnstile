import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui;

import 'package:cloudflare_turnstile/src/html_data.dart';
import 'package:cloudflare_turnstile/src/controller/impl/turnstile_controller_web.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../interface.dart' as base;

class CloudFlareTurnstile extends StatefulWidget implements base.CloudFlareTurnstile {
  @override
  final String siteKey;

  @override
  final TurnstileOptions options;

  @override
  final TurnstileController? controller;

  @override
  final base.OnTokenRecived? onTokenRecived;

  @override
  final base.OnError? onError;

  const CloudFlareTurnstile({
    super.key,
    required this.siteKey,
    this.options = const TurnstileOptions(),
    this.controller,
    this.onTokenRecived,
    this.onError,
  });

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

      widget.controller?.setConnector(jsWindowObject);
    };
  }

  void _registerView(String viewType) {
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) => iframe);
  }

  void _updateSource() {
    iframe.srcdoc = _embedWebIframeJsConnector(
        htmlData(
          siteKey: widget.siteKey,
          options: widget.options,
        ),
        iframeViewType);
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
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _isWidgetReady ? widget.options.size.width : 0.1,
      height: _isWidgetReady ? widget.options.size.height : 0.1,
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
