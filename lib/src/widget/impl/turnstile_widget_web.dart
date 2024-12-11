// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui;

import 'package:cloudflare_turnstile/src/controller/impl/turnstile_controller_web.dart';
import 'package:cloudflare_turnstile/src/turnstile_exception.dart';
import 'package:cloudflare_turnstile/src/widget/interface.dart' as i;
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Renders the Turnstile widget into the specified HTML element.
@JS('turnstile.render')
external String? turnstileRender(web.HTMLElement turnstileView);

/// Executes the Turnstile widget's verification process.
@JS('turnstile.execute')
external String? turnstileExecute(web.HTMLElement turnstileView);

/// Resets the Turnstile widget by ID, clearing any previous verification state.
@JS('turnstile.reset')
external void turnstileReset(String? widgetId);

/// Removes the Turnstile widget from the page by ID.
@JS('turnstile.remove')
external void turnstileRemove(String widgetId);

/// Retrieves the response token from the Turnstile widget.
@JS('turnstile.getResponse')
external String? turnstileGetResponse();

/// Checks whether the Turnstile widget's token has expired.
@JS('turnstile.isExpired')
external bool turnstileIsExpired(String widgetId);

/// Callback triggered when the Turnstile library is successfully loaded.
@JS('onloadTurnstileCallback')
external void onLoadTurnstileCallback();

/// Retrieves the last widget ID created by the Turnstile library.
@JS('getTurnstileWidgetId')
external String? getLastWidgetId();

/// Resets the internally tracked widget ID within the Turnstile library.
@JS('resetTurnstileWidgetId')
external void resetTurnstileWidgetId();

class _TurnstileHandler {
  _TurnstileHandler({
    this.onTokenCallback,
    this.onWidgetIdCallback,
    this.onErrorCallback,
    this.onTokenExpiredCallBack,
  });

  void Function(String)? onTokenCallback;
  void Function(String)? onWidgetIdCallback;
  void Function(int)? onErrorCallback;
  void Function()? onTokenExpiredCallBack;

  @JSExport('token')
  void token(JSString token) {
    onTokenCallback?.call(token.toDart);
  }

  @JSExport('widgetId')
  void widgetId(JSString widgetId) {
    onWidgetIdCallback?.call(widgetId.toDart);
  }

  @JSExport('error')
  void error(JSString code) {
    final errorCode = int.tryParse(code.toDart) ?? -1;
    onErrorCallback?.call(errorCode);
  }

  @JSExport('expired')
  void tokenExpired() {
    onTokenExpiredCallBack?.call();
  }
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
  ///
  /// [onTokenReceived] - A Callback invoked upon success of the challange.
  /// The callback is passed a `token` that can be validated.
  ///
  /// [onTokenExpired] - A Callback invoke when the token expires and does not
  /// reset the widget.
  factory CloudflareTurnstile.invisible({
    required String siteKey,
    String? action,
    String? cData,
    i.OnTokenReceived? onTokenReceived,
    i.OnTokenExpired? onTokenExpired,
    TurnstileOptions? options,
  }) {
    return _TurnstileInvisible.init(
      siteKey: siteKey,
      action: action,
      cData: cData,
      onTokenReceived: onTokenReceived,
      onTokenExpired: onTokenExpired,
      options: options ?? TurnstileOptions(),
    );
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
  late web.HTMLDivElement _turnstileElement;
  late String _turnstileViewType;
  //late js.JSObject jsWindowObject;
  final _turnstileScriptElement = web.HTMLScriptElement();
  final _turnstileCallbackElement = web.HTMLScriptElement();
  final _turnstileWidgetElement = web.HTMLDivElement();

  String? widgetId;

  List<String> widgetsList = [];

  bool _isWidgetReady = false;
  TurnstileException? _hasError;

  @override
  void initState() {
    super.initState();
    _connectJsToFlutter();

    _turnstileViewType = _createViewType();
    _turnstileElement = _createTurnstileElement();

    _createTurnstileCallbacksScript(_turnstileCallbackElement);

    _configureTurnstileRoot(
      _turnstileWidgetElement,
      siteKey: widget.siteKey,
      options: widget.options,
      cData: widget.cData,
      action: widget.action,
    );

    _createTurnstileScriptElement(_turnstileScriptElement);

    _registerView(_turnstileViewType);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setTurnstileTheme();
      _addTurnstileHtml();
    });
  }

  void _setTurnstileTheme() {
    if (widget.options.theme == TurnstileTheme.auto) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;
      widget.options.theme =
          isDark ? TurnstileTheme.dark : TurnstileTheme.light;
    }
  }

  void _addTurnstileHtml() {
    _resetWidget();

    try {
      if (widgetId != null) {
        turnstileRemove(widgetId!);
      }

      _turnstileElement
        ..append(_turnstileCallbackElement)
        ..append(_turnstileWidgetElement);

      if (web.document.head?.querySelector('#turnstile-script') == null) {
        web.document.head?.append(_turnstileScriptElement);

        widget.controller?.isWidgetReady = true;
        _isWidgetReady = true;

        if (mounted) {
          setState(() {});
        }
      } else {
        if (getLastWidgetId() != null) {
          // Previous turnstile challane is during execute
          turnstileRemove(getLastWidgetId()!);
          resetTurnstileWidgetId();
        }

        widgetId = turnstileRender(_turnstileWidgetElement);

        if (widgetId == null || widgetId!.isEmpty) throw Exception();

        _isWidgetReady = true;
        widget.controller?.widgetId = widgetId!;
        widget.controller?.isWidgetReady = true;

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      _addError(
        const TurnstileException('Failed to render Turnstile Widget.'),
      );
    }
  }

  web.HTMLDivElement _createTurnstileElement() {
    final newElement = web.HTMLDivElement()
      ..id = 'cf_turnstile_${DateTime.now().microsecondsSinceEpoch}'
      ..style.border = 'none'
      ..style.width = '100%'
      ..title = 'CloudFlare_Turnstile'
      ..style.height = '100%';

    return newElement;
  }

  String _createViewType() {
    final iframeId = '_${DateTime.now().microsecondsSinceEpoch}';
    return '_iframe$iframeId';
  }

  void _connectJsToFlutter() {
    final handler = _TurnstileHandler(
      onTokenCallback: (token) {
        widget.controller?.token = token;
        widget.onTokenReceived?.call(token);
      },
      onWidgetIdCallback: (cWidgetId) {
        widgetId = cWidgetId;
        widget.controller?.widgetId = cWidgetId;
      },
      onTokenExpiredCallBack: () {
        widget.onTokenExpired?.call();
      },
      onErrorCallback: (code) {
        _addError(TurnstileException.fromCode(code));
      },
    );

    web.window.setProperty(
      'turnstileHandler'.toJS,
      createJSInteropWrapper(handler),
    );
  }

  void _registerView(String viewType) {
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => _turnstileElement,
    );
  }

  void _resetWidget() {
    _hasError = null;
    _isWidgetReady = false;
    widget.controller?.error = null;
    widget.controller?.isWidgetReady = false;
    if (!mounted) return;
    setState(() {});
  }

  void _addError(TurnstileException error) {
    _hasError = error;
    _isWidgetReady = error.retryable;
    widget.controller?.error = error;
    widget.controller?.isWidgetReady = error.retryable;
    widget.onError?.call(error);
    if (!mounted) return;
    setState(() {});
  }

  late final Widget _view = HtmlElementView(
    key: widget.key,
    viewType: _turnstileViewType,
  );

  @override
  void dispose() {
    if (widgetId != null && widgetId!.isNotEmpty) {
      final lastWidgetId = getLastWidgetId();
      if (lastWidgetId == widgetId) {
        turnstileRemove(widgetId!);
      }
    }
    _turnstileElement.remove();
    _turnstileScriptElement.remove();
    _turnstileCallbackElement.remove();
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
    super.onTokenReceived,
    super.onTokenExpired,
    TurnstileOptions? options,
  }) : super(
          siteKey: siteKey,
          controller: TurnstileController(),
        ) {
    _iframe = web.HTMLDivElement();

    _createTurnstileCallbacksScript(_turnstileCallbacks);

    _configureTurnstileRoot(
      _iframe,
      siteKey: siteKey,
      options: options!,
      cData: cData,
      action: action,
    );

    _createTurnstileScriptElement(_turnstileScript);

    _iframe.style.display = 'none';
    _iframe.appendChild(_turnstileCallbacks);

    _connectJsToFlutter();
  }

  late web.HTMLDivElement _iframe;

  final web.HTMLScriptElement _turnstileScript = web.HTMLScriptElement();
  final web.HTMLScriptElement _turnstileCallbacks = web.HTMLScriptElement();

  Completer<dynamic>? _completer;

  String _widgetId = '';
  bool _isWidgetReady = false;
  String? _token;

  void _connectJsToFlutter() {
    final handler = _TurnstileHandler(
      onTokenCallback: (token) {
        _token = token;

        onTokenReceived?.call(token);
        if (!_completer!.isCompleted) {
          _completer?.complete(token);
        }
      },
      onWidgetIdCallback: (widgetId) {
        _isWidgetReady = true;
        _widgetId = widgetId;
        controller?.isWidgetReady = true;
      },
      onTokenExpiredCallBack: () {
        onTokenExpired?.call();
        if (!_completer!.isCompleted) {
          _completer?.complete(null);
        }
      },
      onErrorCallback: (code) {
        if (!_completer!.isCompleted) {
          _completer?.completeError(TurnstileException.fromCode(code));
        }
      },
    );

    web.window.setProperty(
      'turnstileHandler'.toJS,
      createJSInteropWrapper(handler),
    );
  }

  void _run() {
    try {
      _isWidgetReady = false;

      web.document.body?.append(_iframe);

      if (_widgetId.isNotEmpty) {
        turnstileRemove(_widgetId);
      }

      if (web.document.head?.querySelector('#turnstile-script') == null) {
        web.document.head?.append(_turnstileScript);

        _isWidgetReady = true;
      } else {
        if (getLastWidgetId() != null) {
          turnstileRemove(getLastWidgetId()!);
          resetTurnstileWidgetId();
        }

        _widgetId = turnstileRender(_iframe) ?? '';

        if (_widgetId.isEmpty) throw Exception();

        _isWidgetReady = true;
      }
    } catch (e) {
      _completer?.completeError(
        const TurnstileException('Failed to render Turnstile Widget.'),
      );
    }
  }

  bool _isRunning() {
    if (web.document.body != null && web.document.body!.contains(_iframe)) {
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

    if (_token != null) {
      turnstileReset(_widgetId);
    }

    return _completer!.future as Future<String?>;
  }

  @override
  String? get id => _widgetId;

  @override
  Future<bool> isExpired() async {
    return turnstileIsExpired(_widgetId);
  }

  @override
  Future<void> refresh({bool forceRefresh = true}) async {
    if (!_isRunning() || !_isWidgetReady || forceRefresh) {
      await getToken();
    } else if (_isWidgetReady) {
      _completer = Completer<String?>();

      if (_token != null) {
        if (!await controller!.isExpired()) {
          if (!_completer!.isCompleted) {
            _completer?.complete(token);
            return _completer!.future;
          }
        }
      }
      turnstileReset(_widgetId);
      return _completer!.future;
    }
  }

  @override
  String? get token => _token;

  @override
  Future<void> dispose() async {
    if (_widgetId.isNotEmpty && getLastWidgetId() != null) {
      turnstileRemove(getLastWidgetId()!);
    }
    _iframe.remove();
  }
}

void _configureTurnstileRoot(
  web.HTMLDivElement rootElement, {
  required String siteKey,
  required TurnstileOptions options,
  String? action,
  String? cData,
}) {
  rootElement
    ..id = 'cf-turnstile'
    ..setAttribute('data-sitekey', siteKey)
    ..setAttribute('data-action', action ?? '')
    ..setAttribute('data-cdata', cData ?? '')
    ..setAttribute('data-theme', options.theme.name)
    ..setAttribute('data-size', options.size.name)
    ..setAttribute('data-language', options.language)
    ..setAttribute('data-retry', options.retryAutomatically ? 'auto' : 'never')
    ..setAttribute(
      'data-retry-interval',
      options.retryInterval.inMilliseconds.toString(),
    )
    ..setAttribute('data-refresh-expired', options.refreshExpired.name)
    ..setAttribute('data-refresh-timeout', options.refreshTimeout.name)
    ..setAttribute('data-callback', 'onTokenReceived')
    ..setAttribute('data-error-callback', 'onTurnstileError')
    ..setAttribute('data-expired-callback', 'onTokenExpired');
}

void _createTurnstileCallbacksScript(web.HTMLScriptElement scriptElement) {
  scriptElement
    ..id = 'cf_turnstile_cb_scripts'
    ..innerHTML = '''
  window.onloadTurnstileCallback = function () {
   const turnstileID = turnstile.render("#cf-turnstile");
   turnstileWidgetId = turnstileID;
   turnstileHandler.widgetId(turnstileID);
  };

  function onTokenReceived(token) {
    return  turnstileHandler.token(token);
  }

  function onTurnstileError(code) {
    return turnstileHandler.error(code);
  }

  function onTokenExpired() {
    return turnstileHandler.expired();
  }

  function getTurnstileWidgetId() {
    return window.turnstileWidgetId;
  }

  function resetTurnstileWidgetId() {
    window.turnstileWidgetId = undefined;
  }
'''
        .toJS;
}

void _createTurnstileScriptElement(web.HTMLScriptElement scriptElement) {
  scriptElement
    ..id = 'turnstile-script'
    ..type = 'text/javascript'
    ..defer = true
    ..src =
        'https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onloadTurnstileCallback';
}
