class TurnstileOptions {
  final TurnstileMode mode;

  /// The widget size. Can take the following values: [TurnstileSize.normal], [TurnstileSize.compact].
  /// Default value is [TurnstileSize.normal]
  final TurnstileSize size;

  /// Language to display, must be either: auto (default) to use the
  /// language that the visitor has chosen, or an ISO 639-1 two-letter
  /// language code (e.g. en) or language and country code (e.g. en-US).
  /// Refer to the list of supported languages for more information.
  /// Default value is [auto]
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
  final TurnstileRefreshExpired retry;

  final TurnstileRefreshTimeout refreshTimeout;

  const TurnstileOptions({
    this.mode = TurnstileMode.managed,
    this.size = TurnstileSize.normal,
    this.theme = TurnstileTheme.auto,
    this.language = 'auto',
    this.retryInterval = const Duration(milliseconds: 8000),
    this.retryAutomatically = true,
    this.retry = TurnstileRefreshExpired.auto,
    this.refreshTimeout = TurnstileRefreshTimeout.auto,
  });
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
