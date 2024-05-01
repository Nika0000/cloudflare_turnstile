import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';

String htmlData({
  required String siteKey,
  required TurnstileOptions options,
  required String onTurnstileReady,
  required String onTokenRecived,
  required String onTurnstileError,
  required String onTokenExpired,
  required String onWidgetCreated,
}) {
  RegExp exp = RegExp(
      r'<TURNSTILE_(SITE_KEY|THEME|SIZE|LANGUAGE|RETRY|RETRY_INTERVAL|REFRESH_EXPIRED|REFRESH_TIMEOUT|READY|TOKEN_RECIVED|ERROR|TOKEN_EXPIRED|CREATED)>');
  String replacedText = _source.replaceAllMapped(exp, (match) {
    switch (match.group(1)) {
      case 'SITE_KEY':
        return siteKey;
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
      case 'READY':
        return onTurnstileReady;
      case 'TOKEN_RECIVED':
        return onTokenRecived;
      case 'ERROR':
        return onTurnstileError;
      case 'TOKEN_EXPIRED':
        return onTokenExpired;
      case 'CREATED':
        return onWidgetCreated;
      default:
        return match.group(0) ?? "";
    }
  });

  return replacedText;
}

String _source = """
<!DOCTYPE html>
<html lang="en">

<head>
   <meta charset="UTF-8">
   <meta name="viewport"
      content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
   <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"></script>


</head>

<body>
   <div id="cf-turnstile"></div>
   <script>
      turnstile.ready(function () {
         <TURNSTILE_READY>

         const widgetId = turnstile.render('#cf-turnstile', {
            sitekey: '<TURNSTILE_SITE_KEY>',
            theme: '<TURNSTILE_THEME>',
            size: '<TURNSTILE_SIZE>',
            language: '<TURNSTILE_LANGUAGE>',
            retry: '<TURNSTILE_RETRY>',
            'retry-interval': parseInt('<TURNSTILE_RETRY_INTERVAL>'),
            'refresh-expired': '<TURNSTILE_REFRESH_EXPIRED>',
            'refresh-timeout': '<TURNSTILE_REFRESH_TIMEOUT>',
            callback: function (token) {
               <TURNSTILE_TOKEN_RECIVED>
            },
            'error-callback': function (code) {
               <TURNSTILE_ERROR>
            },
            'expired-callback': function () {
               <TURNSTILE_TOKEN_EXPIRED>
            }
         });
         
         <TURNSTILE_CREATED>
      });
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
