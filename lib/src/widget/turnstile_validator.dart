import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:flutter/material.dart';

/// Helper class to validate parameters passed to Cloudflare Turnstile.
@immutable
class TurnstileValidator {
  // Private constructor to prevent instantiation.
  const TurnstileValidator._();

  // Precompiled regex patterns (const for compile‑time constants).
  static const _actionPattern = r'^[a-zA-Z0-9_-]*$';
  static const _cDataPattern = r'^[a-zA-Z0-9_-]*$';

  static final _actionRegExp = RegExp(_actionPattern);
  static final _cDataRegExp = RegExp(_cDataPattern);

  /// Validates parameters for the Cloudflare Turnstile widget.
  /// Throws [ArgumentError] if any parameter is invalid.
  static void validate({
    required String siteKey,
    required TurnstileOptions options,
    String? action,
    String? cData,
  }) {
    // Validate siteKey (must not be empty).
    if (siteKey.isEmpty) {
      throw ArgumentError.value(
          siteKey, 'siteKey', 'Site key cannot be empty.');
    }

    // Validate action.
    if (action != null) {
      if (action.length > 32 || !_actionRegExp.hasMatch(action)) {
        throw ArgumentError.value(
          action,
          'action',
          'Must contain up to 32 alphanumeric characters, including _ and -.',
        );
      }
    }

    // Validate cData.
    if (cData != null) {
      if (cData.length > 255 || !_cDataRegExp.hasMatch(cData)) {
        throw ArgumentError.value(
          cData,
          'cData',
          'Must contain up to 255 alphanumeric characters, including _ and -.',
        );
      }
    }

    // Validate retryInterval.
    final retryMs = options.retryInterval.inMilliseconds;
    if (retryMs <= 0 || retryMs > 900000) {
      throw ArgumentError.value(
        retryMs,
        'options.retryInterval',
        'Must be > 0 and ≤ 900,000 ms (15 minutes).',
      );
    }
  }
}
