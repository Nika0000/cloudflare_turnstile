class TurnstileOptions {
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
  final TurnstileMode mode;

  /// The widget size. Can take the following values: [TurnstileSize.normal], [TurnstileSize.compact].
  /// Default value is [TurnstileSize.normal]
  final TurnstileSize size;

  /// Language to display, must be either: auto (default) to use the
  /// language that the visitor has chosen, or an ISO 639-1 two-letter
  /// language code (e.g. en) or language and country code (e.g. en-US).
  /// Refer to the list of supported languages for more information.
  /// Default value is [auto]
  ///
  /// Refer to [list of supported languages](https://developers.cloudflare.com/turnstile/reference/supported-languages/) for more infrmation.
  final String language;

  final TurnstileTheme theme;

  /// Controls whether the widget should automatically retry to obtain
  /// a token if it did not succeed. The default value is true witch will
  /// retry Autmoatically. This can be set to false to disable retry upon
  /// failure.
  final bool retryAutomatically;

  /// When retry is set to [auto], [retryInterval] controls the time
  /// between retry attempts in milliseconds. Value must be a positive
  /// integer less than 900000, defaults to 8000
  final Duration retryInterval;

  /// Automatically refreshes the token when it expires.
  /// Can take auto, manual or never, defaults to auto.
  final TurnstileRefreshExpired refreshExpired;

  /// Controls whether the widget should automatically refresh upon
  /// entering an interactive challange and observing a timeout.
  /// Can take [auto] (automaticly), [manual] (prompts the visitor to
  /// manualy refresh) or [never] (will show a timeout), defaults to [auto]
  /// Only applies to widgets of mode [managed]
  final TurnstileRefreshTimeout refreshTimeout;

  TurnstileOptions({
    this.mode = TurnstileMode.managed,
    this.size = TurnstileSize.normal,
    this.theme = TurnstileTheme.auto,
    this.language = 'auto',
    this.retryInterval = const Duration(milliseconds: 8000),
    this.retryAutomatically = true,
    this.refreshExpired = TurnstileRefreshExpired.auto,
    this.refreshTimeout = TurnstileRefreshTimeout.auto,
  })  : assert(
          retryInterval.inMilliseconds > 0 && retryInterval.inMilliseconds <= 900000,
          "Duration must be greater than 0 and less than or equal to 900000 milliseconds.",
        ),
        assert(
          mode == TurnstileMode.managed && refreshTimeout == TurnstileRefreshTimeout.auto,
          "TurnstileRefreshTimeout has no effect on an invisible/non-interactive widget. ${mode.name} ${refreshTimeout.name}",
        );
}

enum TurnstileMode { managed, nonInteractive, invisible }

enum TurnstileSize {
  normal(300, 65),
  compact(130, 120);

  final double width;
  final double height;
  const TurnstileSize(this.width, this.height);
}

enum TurnstileTheme { auto, dark, light }

enum TurnstileRefreshExpired { auto, manual, never }

enum TurnstileRefreshTimeout { auto, manual, never }
