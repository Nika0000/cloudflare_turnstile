# Flutter Cloudflare Turnstile [![Pub](https://img.shields.io/pub/v/cloudflare_turnstile.svg)](https://pub.dartlang.org/packages/cloudflare_turnstile)

![head](https://github.com/user-attachments/assets/5ffd938a-93b5-490e-b0dc-a3f2a99958be)

Cloudflare turnstile is a free CAPTCHAs Alternative, Turnstile delivers frustration-free, CAPTCHA-free web experiences to website visitors - with just a simple snippet of free code. Moreover, Turnstile stops abuse and confirms visitors are real without the data privacy concerns or awful user experience of CAPTCHAs.

## ⚠️ **NOTE** 

This package is unofficial and not endorsed by Cloudflare. Use it at your own discretion.

## Installation

```sh
flutter pub add cloudflare_turnstile
```

# Example

Here`s a quick example that show how to add Cloudflare Turnstile widget to your flutter app

```dart
import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CloudFlareTurnstile(
          siteKey: '3x00000000000000000000FF', //Change with your site key
          baseUrl: 'http://localhost/',
          mode: TurnstileMode.managed,
          onTokenReceived: (token) {
            print(token);
          },
        ),
      ),
    );
  }
}
```
> For Android and iOS platforms you need to provide the `baseUrl` parameter with the actual URL of your Turnstile Widget Domains list. `baseUrl` is must be a same as list of domains when creating a Widget.

## Configure Turnstile Widget

```dart
final TurnstileOptions options = const TurnstileOptions(
  size: TurnstileSize.normal,
  theme: TurnstileTheme.light,
  language: 'ar',
  retryAutomatically: false,
  refreshTimeout: TurnstileRefreshTimeout.manual,
);

//...

CloudFlareTurnstile(
  sitekey: '3x00000000000000000000FF',
  options: options,
  mode: TurnstileMode.managed,
);
```

## Contribution
Your contributions are welcome and greatly valued! If you have ideas, suggestions, or improvements, feel free to open an issue or submit a pull request. Every bit of help is appreciated, and your input can make a big difference. Just ensure your contributions fit with the project's goals and guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE.md](./LICENSE) file for details.
