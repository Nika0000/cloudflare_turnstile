# Flutter Cloudflare Turnstile [![Pub](https://img.shields.io/pub/v/horizontal_list_view.svg)](https://pub.dartlang.org/packages/horizontal_list_view)


Cloudflare turnstile is a free CAPTCHAs Alternative, Turnstile delivers frustration-free, CAPTCHA-free web experiences to website visitors - with just a simple snippet of free code. Moreover, Turnstile stops abuse and confirms visitors are real without the data privacy concerns or awful user experience of CAPTCHAs.

![Preview](https://cf-assets.www.cloudflare.com/slt3lc6tev37/2atsfrGgvgOc3DZ91qMlKN/0412afa63e5fac20964377c70c1a9a17/turnstile_gif.gif)



## ⚠️ NOTE

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
          siteKey: '0x0000000000000000000000', //Change with your site key
          baseUrl: 'http://localhost/',
          onTokenRecived: (token) {
            print(token);
          },
        ),
      ),
    );
  }
}
```
> For Android and iOS platforms you need to provide the `baseUrl` parameter with the actual URL of your Turnstile Site list. if you don't have a website, you can add the application package name to the Turnstile widget domains list in your Cloudflare Dashboard. Then the baseUrl should look like `baseUrl: 'http://com.example.app'` or `baseUrl: 'http://mywebsite.com/'`.

## Configure Turnstile Widget

```dart
final TurnstileOptions options = const TurnstileOptions(
  mode: TurnstileMode.managed,
  size: TurnstileSize.normal,
  theme: TurnstileTheme.light,
  language: 'ar',
  retryAutomatically: false,
  refreshTimeout: TurnstileRefreshTimeout.manual,
);

//...

CloudflareTurnstile(
  sitekey: '0x0000000000000000000000',
  options: options,
);
```

> `TurnstileOptions` is based on Cloudflare Turnstile configuration [documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)

## License

This project is licensed under the MIT License - see the [LICENSE.md](./LICENSE) file for details.