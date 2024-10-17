import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';

/// Turnstile view builder
String htmlData({
  required String siteKey,
  required TurnstileOptions options,
  required String onTokenReceived,
  required String onTurnstileError,
  required String onTokenExpired,
  required String onWidgetCreated,
  String? action,
  String? cData,
}) {
  final exp = RegExp(
    '<TURNSTILE_(SITE_KEY|ACTION|CDATA|THEME|SIZE|LANGUAGE|RETRY|RETRY_INTERVAL|REFRESH_EXPIRED|REFRESH_TIMEOUT|READY|TOKEN_RECEIVED|ERROR|TOKEN_EXPIRED|CREATED)>',
  );

  final replacedText = _source.replaceAllMapped(exp, (match) {
    switch (match.group(1)) {
      case 'SITE_KEY':
        return siteKey;
      case 'ACTION':
        return action ?? '';
      case 'CDATA':
        return cData ?? '';
      case 'THEME':
        return options.theme.name;
      case 'SIZE':
        return options.size.name;
      case 'LANGUAGE':
        return options.language;
      case 'RETRY':
        return options.retryAutomatically ? 'auto' : 'never';
      case 'RETRY_INTERVAL':
        return options.retryInterval.inMilliseconds.toString();
      case 'REFRESH_EXPIRED':
        return options.refreshExpired.name;
      case 'REFRESH_TIMEOUT':
        return options.refreshTimeout.name;
      case 'TOKEN_RECEIVED':
        return onTokenReceived;
      case 'ERROR':
        return onTurnstileError;
      case 'TOKEN_EXPIRED':
        return onTokenExpired;
      case 'CREATED':
        return onWidgetCreated;
      default:
        return match.group(0) ?? '';
    }
  });

  return replacedText;
}

String _source = """
<!DOCTYPE html>
<html lang="en">

<head>
   <meta charset="UTF-8">
   <link rel="icon" href="data:,">
   <meta name="viewport"
      content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
   <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"></script>

   
</head>

<body>
   <div id="cf-turnstile"></div>
   <script>
      turnstile.ready(function () {
           if (!document.getElementById('cf-turnstile').hasChildNodes()) {
               const widgetId = turnstile.render('#cf-turnstile', {
                  sitekey: '<TURNSTILE_SITE_KEY>',
                  action: '<TURNSTILE_ACTION>',
                  cData: '<TURNSTILE_CDATA>',
                  theme: '<TURNSTILE_THEME>',
                  size: '<TURNSTILE_SIZE>',
                  language: '<TURNSTILE_LANGUAGE>',
                  retry: '<TURNSTILE_RETRY>',
                  'retry-interval': parseInt('<TURNSTILE_RETRY_INTERVAL>'),
                  'refresh-expired': '<TURNSTILE_REFRESH_EXPIRED>',
                  'refresh-timeout': '<TURNSTILE_REFRESH_TIMEOUT>',
                  'feedback-enabled': false,
                  callback: function (token) {
                     <TURNSTILE_TOKEN_RECEIVED>
                  },
                  'error-callback': function (code) {
                     <TURNSTILE_ERROR>
                  },
                  'expired-callback': function () {
                     <TURNSTILE_TOKEN_EXPIRED>
                  }
               });

               <TURNSTILE_CREATED>
           }
        });

       function getWidgetDimensions() {
           const widgetElement = document.getElementById('cf-turnstile');
           const rect = widgetElement.getBoundingClientRect();

           const dimensions = {
               width: rect.width,
               height: rect.height
           };

           return JSON.stringify(dimensions);
       };

   </script>
   <style>
      * {
         overflow: hidden;
         margin: 0;
         padding: 0;
      }
   </style>
</body>

</html>

""";
