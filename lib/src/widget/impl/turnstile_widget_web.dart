// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui;

import 'package:cloudflare_turnstile/src/controller/impl/turnstile_controller_web.dart';
import 'package:cloudflare_turnstile/src/html_data.dart';
import 'package:cloudflare_turnstile/src/turnstile_exception.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';

const String _tokenReceivedJSHandler = 'TurnstileToken(token);';
const String _errorJSHandler = 'TurnstileError(code);';
const String _tokenExpiredJSHandler = 'TokenExpired();';
const String _widgetCreatedJSHandler = 'TurnstileWidgetId(widgetId);';

const String _jsToDartConnectorFN = 'connect_js_to_flutter';

String _createViewType() {
  final iframeId = '_${DateTime.now().microsecondsSinceEpoch}';
  return '_iframe$iframeId';
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

/// Cloudflare Turnstile web implementation
class CloudflareTurnstile extends StatefulWidget
    implements i.CloudflareTurnstile {
  /// Create a Cloudflare Turnstile Widget
  CloudflareTurnstile({
    required this.siteKey,
    super.key,
    this.action,
    this.cData,
    this.baseUrl = 'http://localhost/',
    TurnstileOptions? options,
    this.controller,
    this.onTokenReceived,
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

    assert(
      this.options.retryInterval.inMilliseconds > 0 &&
          this.options.retryInterval.inMilliseconds <= 900000,
      'Duration must be greater than 0 and less than or equal to 900000 milliseconds.',
    );

    /*   assert(
      !(mode == i.TurnstileMode.invisible && this.options.refreshExpired == TurnstileRefreshExpired.manual),
      '${this.options.refreshExpired} is impossible in $mode, consider using TurnstileRefreshExpired.auto or TurnstileRefreshExpired.never',
    );

    assert(
      !(mode == i.TurnstileMode.invisible && this.options.refreshTimeout != TurnstileRefreshTimeout.auto),
      '${this.options.refreshTimeout} has no effect on an $mode widget.',
    );

    assert(
      !(mode == i.TurnstileMode.nonInteractive && this.options.refreshTimeout != TurnstileRefreshTimeout.auto),
      '${this.options.refreshTimeout} has no effect on an $mode widget.',
    ); */
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
  /// CloudflareTurnstile(
  ///   siteKey: '3x00000000000000000000FF',
  ///   onTokenReceived: (String token) {
  ///     print('Token: $token');
  ///   },
  /// ),
  /// ```
  @override
  final i.OnTokenReceived? onTokenReceived;

  /// A Callback invoke when the token expires and does not
  /// reset the widget.
  ///
  /// example:
  /// ```dart
  /// CloudflareTurnstile(
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
  /// CloudflareTurnstile(
  ///   siteKey: '3x00000000000000000000FF',
  ///   errorBuilder: (error) {
  ///     print(error.message);
  ///   },
  /// ),
  /// ```
  ///
  /// Refer to [Client-side errors](https://developers.cloudflare.com/turnstile/troubleshooting/client-side-errors/).
  @override
  final i.OnError? onError;

  @override
  State<CloudflareTurnstile> createState() => _CloudflareTurnstileState();

  /// Create a Cloudflare Turnstile invisible widget.
  ///
  /// [siteKey] - A Cloudflare Turnstile sitekey.
  /// It`s likely generated or obtained from the Cloudflare dashboard.
  ///
  /// [action] - A customer value that can be used to differentiate widgets under
  /// the some sitekey in analytics and witch is returned upon validation.
  ///
  /// [cData] - A customer payload that can be used to attach customer data to the
  /// challenge throughout its issuance and which is returned upon validation.
  ///
  /// [baseUrl] - A website url corresponding current turnstile widget.
  ///
  /// [options] - Configuration options for the Turnstile widget.
  factory CloudflareTurnstile.invisible({
    required String siteKey,
    String? action,
    String? cData,
    TurnstileOptions? options,
  }) {
    return _TurnstileInvisible.init(
      siteKey: siteKey,
      action: action,
      cData: cData,
      options: options ?? TurnstileOptions(),
    );
  }

  /// Retrives the current token from the widget.
  ///
  /// Returns `null` if no token is available.
  @override
  String? get token => throw UnimplementedError(
        'This function cannot be called in interactive widget mode.',
      );

  /// Retrives the current widget id.
  ///
  /// This `id` is used to uniquely identify the Turnstile widget instance.
  @override
  String? get id => throw UnimplementedError(
        'This function cannot be called in interactive widget mode.',
      );

  /// The function can be called when widget mey become expired and
  /// needs to be refreshed otherwise, it will start a new challenge.
  ///
  /// This method can only be called when [id] is not null.
  ///
  ///
  /// example:
  /// ```dart
  /// // Initialize turnstile instance
  /// final turnstile = CloudflareTurnstile.invisible(
  ///   siteKey: '1x00000000000000000000BB', // Replace with your actual site key
  /// );
  ///
  /// await turnstile.isExpired();
  ///
  /// // finally clean up widget.
  /// await turnstile.dispose();
  /// ```
  @override
  Future<void> refresh({bool forceRefresh = true}) {
    throw UnimplementedError(
      'This function cannot be called in interactive widget mode.',
    );
  }

  /// This function starts a Cloudflare Turnstile challenge and returns token
  /// or `null` if challenge failed or error occured.
  ///
  /// example:
  /// ```dart
  /// // Initialize turnstile instance
  /// final turnstile = CloudflareTurnstile.invisible(
  ///   siteKey: '1x00000000000000000000BB', // Replace with your actual site key
  /// );
  ///
  /// final token = await turnstile.getToken();
  ///
  /// print(token);
  ///
  /// // finally clean up widget.
  /// await turnstile.dispose();
  /// ```
  @override
  Future<String?> getToken() {
    throw UnimplementedError(
      'This function cannot be called in interactive widget mode.',
    );
  }

  /// The function that check if a widget has expired.
  ///
  /// This method can only be called when [id] is not null.
  ///
  ///
  /// example:
  /// ```dart
  /// // Initialize turnstile instance
  /// final turnstile = CloudflareTurnstile.invisible(
  ///   siteKey: '1x00000000000000000000BB', // Replace with your actual site key
  /// );
  ///
  /// // ...
  ///
  /// bool isTokenExpired = await turnstile.isExpired();
  /// print(isTokenExpired);
  ///
  /// // finally clean up widget.
  /// await turnstile.dispose();
  /// ```
  @override
  Future<bool> isExpired() {
    throw UnimplementedError(
      'This function cannot be called in interactive widget mode.',
    );
  }

  /// Dispose invisible Turnstile widget.
  ///
  ///
  /// This should be called when the widget is no longer needed to free
  /// up resources and clean up.
  @override
  Future<void> dispose() {
    throw UnimplementedError(
      'This function cannot be called in interactive widget mode.',
    );
  }
}

class _CloudflareTurnstileState extends State<CloudflareTurnstile> {
  late html.IFrameElement iframe;
  late String iframeViewType;
  late StreamSubscription<dynamic> iframeOnLoadSubscription;
  late js.JsObject jsWindowObject;

  final String _jsToDartConnectorFN = 'connect_js_to_flutter';
  String? widgetId;

  bool _isWidgetReady = false;
  TurnstileException? _hasError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setTurnstileTheme();
    });

    iframeViewType = _createViewType();
    iframe = _createIFrame();

    _connectJsToFlutter();
    _registerView(iframeViewType);

    _updateSource();
    _registerIframeOnLoadCallBack();
  }

  void _setTurnstileTheme() {
    if (widget.options.theme == TurnstileTheme.auto) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;
      widget.options.theme =
          isDark ? TurnstileTheme.dark : TurnstileTheme.light;
    }
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
    _resetWidget();

    iframeOnLoadSubscription = iframe.onLoad.listen((event) {
      setState(() => _isWidgetReady = true);
      widget.controller?.isWidgetReady = _isWidgetReady;
    });
  }

  void _connectJsToFlutter() {
    js.context['$_jsToDartConnectorFN$iframeViewType'] = (js.JsObject window) {
      jsWindowObject = window;

      jsWindowObject['TurnstileToken'] = (String message) {
        widget.controller?.token = message;
        widget.onTokenReceived?.call(message);
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

  void _updateSource() {
    iframe.srcdoc = _embedWebIframeJsConnector(
      htmlData(
        siteKey: widget.siteKey,
        action: widget.action,
        cData: widget.cData,
        options: widget.options,
        onTokenReceived: _tokenReceivedJSHandler,
        onTurnstileError: _errorJSHandler,
        onTokenExpired: _tokenExpiredJSHandler,
        onWidgetCreated: _widgetCreatedJSHandler,
      ),
      iframeViewType,
    );
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
      widget.onError?.call(error);
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
    _setTurnstileTheme();

    final primaryColor = widget.options.theme == TurnstileTheme.light
        ? const Color(0xFFFAFAFA)
        : const Color(0xFF232323);
    final secondaryColor = widget.options.theme == TurnstileTheme.light
        ? const Color(0xFFDEDEDE)
        : const Color(0xFF9A9A9A);
    final adaptiveBorderColor =
        _isWidgetReady ? secondaryColor : Colors.transparent;

    final isErrorResolvable = _hasError != null && _hasError!.retryable == true;

    final turnstileWidget = Visibility(
      visible: _hasError == null || isErrorResolvable,
      child: AnimatedContainer(
        duration: widget.options.animationDuration!,
        width: _isWidgetReady ? widget.options.size.width : 0.1,
        height: _isWidgetReady ? widget.options.size.height : 0.1,
        curve: widget.options.curves!,
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: adaptiveBorderColor),
          borderRadius: widget.options.borderRadius,
        ),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: widget.options.borderRadius!.add(
            // add extra 1 px because border
            const BorderRadius.all(
              Radius.circular(1),
            ),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: _view,
      ),
    );

    return turnstileWidget;
  }
}

// ignore: must_be_immutable
class _TurnstileInvisible extends CloudflareTurnstile {
  _TurnstileInvisible.init({
    required String siteKey,
    String? action,
    String? cData,
    TurnstileOptions? options,
  }) : super(siteKey: siteKey, controller: TurnstileController()) {
    _iframe = html.IFrameElement();
    _iframeViewType = _createViewType();

    final data = htmlData(
      siteKey: siteKey,
      action: action,
      cData: cData,
      options: options!,
      onTokenReceived: _tokenReceivedJSHandler,
      onTurnstileError: _errorJSHandler,
      onTokenExpired: _tokenExpiredJSHandler,
      onWidgetCreated: _widgetCreatedJSHandler,
    );

    _iframe.srcdoc = _embedWebIframeJsConnector(data, _iframeViewType);
    _iframe.style.display = 'none';

    _connectJsToFlutter();

    _iframeOnLoadSubscription = _iframe.onLoad.listen(
      (_) => controller?.isWidgetReady = true,
    );
  }

  late html.IFrameElement _iframe;
  late js.JsObject _jsWindowObject;
  late String _iframeViewType;
  late StreamSubscription<dynamic> _iframeOnLoadSubscription;
  Completer<dynamic>? _completer;

  void _connectJsToFlutter() {
    js.context['$_jsToDartConnectorFN$_iframeViewType'] = (js.JsObject window) {
      _jsWindowObject = window;

      _jsWindowObject['TurnstileToken'] = (String message) {
        controller?.token = message;
        if (!_completer!.isCompleted) {
          _completer?.complete(token);
        }
      };

      _jsWindowObject['TurnstileError'] = (String message) {
        final errorCode = int.tryParse(message);
        final error = TurnstileException.fromCode(errorCode ?? -1);

        controller?.error = error;
        if (!_completer!.isCompleted) {
          _completer?.completeError(error);
        }
      };

      _jsWindowObject['TurnstileWidgetId'] = (String message) {
        controller!.widgetId = message;
      };

      _jsWindowObject['TokenExpired'] = (message) {
        if (!_completer!.isCompleted) {
          _completer?.complete(null);
        }
      };

      controller?.setConnector(_jsWindowObject);
    };
  }

  void _run() => html.document.body?.append(_iframe);

  bool _isRunning() {
    if (html.document.body != null && html.document.body!.contains(_iframe)) {
      return true;
    }
    return false;
  }

  @override
  Future<String?> getToken() async {
    _completer = Completer<String?>();

    if (!_isRunning()) {
      _run();
    }

    if (controller!.token != null) {
      if (!await controller!.isExpired()) {
        _completer?.complete(token);
      }
    }

    return _completer!.future as Future<String?>;
  }

  @override
  String? get id => controller?.widgetId;

  @override
  Future<bool> isExpired() {
    return controller!.isExpired();
  }

  @override
  Future<void> refresh({bool forceRefresh = true}) async {
    if (!_isRunning() || !controller!.isWidgetReady || forceRefresh) {
      await getToken();
    } else if (controller!.isWidgetReady) {
      _completer = Completer<String?>();

      if (token != null) {
        if (!await controller!.isExpired()) {
          if (!_completer!.isCompleted) {
            _completer?.complete(token);
            return _completer!.future;
          }
        }
      }

      await controller?.refreshToken();
      return _completer!.future;
    }
  }

  @override
  String? get token => controller?.token;

  @override
  Future<void> dispose() async {
    await _iframeOnLoadSubscription.cancel();
    _iframe.remove();
  }
}
