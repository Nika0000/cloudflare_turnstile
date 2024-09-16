import 'package:cloudflare_turnstile/src/widget/interface.dart';

/// Configuration options for the Cloudflare Turnstile widget.
class TurnstileOptions {
  /// Create a Cloudflare Turnstile Options configuration.
  ///
  /// The default values are:
  /// - [size] = [TurnstileSize.normal]
  /// - [theme] = [TurnstileTheme.auto]
  /// - [language] = 'auto'
  /// - [retryInterval] = 8000 milliseconds (8 seconds)
  /// - [retryAutomatically] = true (automatic retry)
  /// - [refreshExpired] = [TurnstileRefreshExpired.auto]
  /// - [refreshTimeout] = [TurnstileRefreshTimeout.auto]
  TurnstileOptions({
    this.size = TurnstileSize.normal,
    this.theme = TurnstileTheme.auto,
    this.language = 'auto',
    this.retryInterval = const Duration(milliseconds: 8000),
    this.retryAutomatically = true,
    this.refreshExpired = TurnstileRefreshExpired.auto,
    this.refreshTimeout = TurnstileRefreshTimeout.auto,
  });

  /// The widget size.
  ///
  /// Can be set to [TurnstileSize.normal] or [TurnstileSize.compact].
  /// The default value is [TurnstileSize.normal].
  final TurnstileSize size;

  /// The language to display in the widget.
  ///
  /// Defaults to 'auto', which uses the language chosen by the visitor.
  /// You can set an ISO 639-1 two-letter language code (e.g., 'en' for English),
  /// or a language and country code (e.g., 'en-US').
  ///
  /// Refer to the [list of supported languages](https://developers.cloudflare.com/turnstile/reference/supported-languages/).
  final String language;

  /// The theme of the widget.
  ///
  /// Defaults to [TurnstileTheme.auto], which automatically adjusts based on
  /// the device's brightness setting. Can also be set to [TurnstileTheme.dark]
  /// or [TurnstileTheme.light].
  TurnstileTheme theme;

  /// Whether the widget should automatically retry obtaining a token if
  /// the challenge fails.
  ///
  /// Defaults to `true`, which enables automatic retry. Set to `false` to
  /// disable automatic retry on failure.
  final bool retryAutomatically;

  /// The interval between retry attempts when [retryAutomatically] is enabled.
  ///
  /// The value is specified as a [Duration], with the default being 8 seconds (8000 milliseconds).
  /// This value must be a positive integer and less than 900000 milliseconds (15 minutes).
  final Duration retryInterval;

  /// Behavior for refreshing the token when it expires.
  ///
  /// Can be set to [TurnstileRefreshExpired.auto], [TurnstileRefreshExpired.manual],
  /// or [TurnstileRefreshExpired.never].
  ///
  /// The default is [TurnstileRefreshExpired.auto],
  /// which refreshes the token automatically when it expires.
  final TurnstileRefreshExpired refreshExpired;

  /// Controls how the widget behaves when a timeout occurs during an interactive challenge.
  ///
  /// Can be set to [TurnstileRefreshTimeout.auto] (automatic refresh), [TurnstileRefreshTimeout.manual]
  /// (manual refresh by the visitor), or [TurnstileRefreshTimeout.never] (show a timeout without refreshing).
  /// The default is [TurnstileRefreshTimeout.auto].
  ///
  /// This setting applies only to widgets in [TurnstileMode.managed].
  final TurnstileRefreshTimeout refreshTimeout;
}

/// Defines the sizes for the Cloudflare Turnstile widget.
enum TurnstileSize {
  /// Normal size for the widget.
  ///
  /// Dimensions: width 300px, height 65px.
  normal(300, 65),

  /// Compact size for the widget.
  ///
  /// Dimensions: width 150px, height 140px.
  compact(150, 140),

  /// Flexible size for the widget.
  ///
  /// Width is flexible (min 300px), and height is fixed at 65px.
  flexible(double.maxFinite, 65);

  /// Creates a [TurnstileSize] with the specified [width] and [height].
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
