import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurnstileValidator tests', () {
    final defaultOptions = TurnstileOptions();

    test('valid parameters should not throw errors', () {
      expect(
        () => TurnstileValidator.validate(
          siteKey: '3x00000000000000000000FF',
          options: defaultOptions,
        ),
        returnsNormally,
      );

      expect(
        () => TurnstileValidator.validate(
          siteKey: '3x00000000000000000000FF',
          action: 'login-form_action',
          cData: 'custom_session-id-1234',
          options: defaultOptions,
        ),
        returnsNormally,
      );
    });

    test('invalid action length should throw ArgumentError', () {
      expect(
        () => TurnstileValidator.validate(
          siteKey: '3x00000000000000000000FF',
          action: 'a' * 33, // limit is 32
          options: defaultOptions,
        ),
        throwsArgumentError,
      );
    });

    test('invalid action characters should throw ArgumentError', () {
      expect(
        () => TurnstileValidator.validate(
          siteKey: '3x00000000000000000000FF',
          action: 'action@123', // only alphanumeric, _, - allowed
          options: defaultOptions,
        ),
        throwsArgumentError,
      );
    });

    test('cData length up to 255 should be valid', () {
      expect(
        () => TurnstileValidator.validate(
          siteKey: '3x00000000000000000000FF',
          cData: 'c' * 255, // valid up to 255
          options: defaultOptions,
        ),
        returnsNormally,
      );
    });

    test('cData length > 255 should throw ArgumentError', () {
      expect(
        () => TurnstileValidator.validate(
          siteKey: '3x00000000000000000000FF',
          cData: 'c' * 256, // limit is 255
          options: defaultOptions,
        ),
        throwsArgumentError,
      );
    });

    test('invalid retry interval should throw ArgumentError', () {
      expect(
        () => TurnstileValidator.validate(
          siteKey: '3x00000000000000000000FF',
          options: TurnstileOptions(retryInterval: Duration.zero),
        ),
        throwsArgumentError,
      );
    });
  });
}
