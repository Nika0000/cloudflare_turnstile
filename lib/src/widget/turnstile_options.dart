class TurnstileOptions {
  /// Create a Cloudflare Turnstile Options
  TurnstileOptions({
    this.mode = TurnstileMode.auto,
    this.size = TurnstileSize.normal,
    this.theme = TurnstileTheme.auto,
    this.language = 'auto',
    this.retryInterval = const Duration(milliseconds: 8000),
    this.retryAutomatically = true,
    this.refreshExpired = TurnstileRefreshExpired.auto,
    this.refreshTimeout = TurnstileRefreshTimeout.auto,
  })  : assert(
          retryInterval.inMilliseconds > 0 &&
              retryInterval.inMilliseconds <= 900000,
          'Duration must be greater than 0 and less than or equal to 900000 milliseconds.',
        ),
        assert(
          !(mode == TurnstileMode.invisible &&
              refreshExpired == TurnstileRefreshExpired.manual),
          '$refreshExpired is impossible in $mode, consider using TurnstileRefreshExpired.auto or TurnstileRefreshExpired.never',
        ),
        assert(
          !(mode == TurnstileMode.invisible &&
              refreshTimeout != TurnstileRefreshTimeout.auto),
          '$refreshTimeout has no effect on an $mode widget.',
        ),
        assert(
          !(mode == TurnstileMode.nonInteractive &&
              refreshTimeout != TurnstileRefreshTimeout.auto),
          '$refreshTimeout has no effect on an $mode widget.',
        );

  /// The Turnstile widget mode.
  ///
  ///  The 3 models for turnstile are:
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
  /// [TurnstileMode.auto] Automatically detects whether the Turnstile widget should
  ///  operate in interactive or invisible mode based on contextual cues.
  ///
  /// Note: This mode relies on contextual cues and does not guarantee detection accuracy since
  /// Cloudflare's Turnstile does not provide direct methods to determine widget mode.
  ///
  /// Default value is [TurnstileMode.auto]
  ///
  /// Refer to [Widget types](https://developers.cloudflare.com/turnstile/concepts/widget-types/)
  final TurnstileMode mode;

  /// The widget size. Can take the following values: [TurnstileSize.normal], [TurnstileSize.compact].
  /// Default value is [TurnstileSize.normal]
  final TurnstileSize size;

  /// Language to display, must be either: auto (default) to use the
  /// language that the visitor has chosen, or an ISO 639-1 two-letter
  /// language code (e.g. en) or language and country code (e.g. en-US).
  /// Refer to the list of supported languages for more information.
  /// Default value is `auto`
  ///
  /// Refer to [list of supported languages](https://developers.cloudflare.com/turnstile/reference/supported-languages/) for more infrmation.
  final String language;

  /// The widget theme
  ///
  /// Default value is [TurnstileTheme.auto], witch respects the device brigthnese.
  TurnstileTheme theme;

  /// Controls whether the widget should automatically retry to obtain
  /// a token if it did not succeed. The default value is true witch will
  /// retry Autmoatically. This can be set to false to disable retry upon
  /// failure.
  final bool retryAutomatically;

  /// When [retryAutomatically] is set to true, [retryInterval] controls the
  /// time between retry attempts in milliseconds. Value must be a positive
  /// integer less than 900000, defaults to 8000
  final Duration retryInterval;

  /// Automatically refreshes the token when it expires.
  /// Can take auto, manual or never, defaults to auto.
  final TurnstileRefreshExpired refreshExpired;

  /// Controls whether the widget should automatically refresh upon
  /// entering an interactive challange and observing a timeout.
  /// Can take [TurnstileRefreshTimeout.auto] (automaticly),
  /// [TurnstileRefreshTimeout.manual] (prompts the visitor to manualy refresh)
  /// or [TurnstileRefreshTimeout.never] (will show a timeout),
  /// defaults to [TurnstileRefreshTimeout.auto]
  ///
  /// Only applies to widgets of mode [TurnstileMode.managed]
  final TurnstileRefreshTimeout refreshTimeout;
}

/// Defines the modes for the Cloudflare Turnstile widget.
enum TurnstileMode {
  /// Managed Mode.
  ///
  /// The widget requires user interaction.
  managed,

  /// Non-Interaction mode.
  ///
  /// The widget does not require user interaction.
  nonInteractive,

  /// Invisible mode
  ///
  /// The widget is invisible to the user
  invisible,

  /// Auto mode.
  ///
  /// The widget automatically select the mode base on the context.
  auto,
}

/// Defines the sizes for the Cloudflare Turnstile widget.
enum TurnstileSize {
  /// Normal size.
  ///
  /// Dimensions: width 300, height 65.
  normal(300, 65),

  /// Compact size.
  ///
  /// Dimensions: width 130, height 120.
  compact(130, 120);

  /// Creates a TurnstileSize with the specified width and height
  const TurnstileSize(
    this.width,
    this.height,
  );

  /// The width of the widget.
  final double width;

  /// The height of the widget.
  final double height;
}

/// Defines the themes for the Cloudflare Turnstile widget.
enum TurnstileTheme {
  /// Automatic theme.
  ///
  /// The theme is automatically selected based on the context.
  auto,

  /// Dark theme.
  ///
  /// The widget uses a dark theme.
  dark,

  /// Light theme.
  ///
  /// The widget uses a light theme.
  light,
}

/// Defines the refresh behavior when the token expires.
enum TurnstileRefreshExpired {
  /// Automatic refresh.
  ///
  /// The widget automatically refreshes when the token expires.
  auto,

  /// Manual refresh.
  ///
  /// The widget requires manual refresh when the token expires.
  manual,

  /// Never refresh.
  ///
  /// The widget does not refresh when the token expires.
  never,
}

/// Defines the refresh behavior when the token times out.
enum TurnstileRefreshTimeout {
  /// Automatic refresh.
  ///
  /// The widget automatically refreshes when the token times out.
  auto,

  /// Manual refresh.
  ///
  /// The widget requires manual refresh when the token times out.
  manual,

  /// Never refresh.
  ///
  /// The widget does not refresh when the token times out.
  never,
}
