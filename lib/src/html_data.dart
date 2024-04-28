import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:cloudflare_turnstile/src/widget/turnstile_options.dart';

String htmlData({
  required String siteKey,
  required TurnstileOptions options,
}) {
  RegExp exp = RegExp(r'<TURNSTILE_(SITE_KEY|THEME|LANGUAGE|RETRY|REFRESH_EXPIRED|REFRESH_TIMEOUT)>');
  String replacedText = _source.replaceAllMapped(exp, (match) {
    switch (match.group(1)) {
      case 'SITE_KEY':
        return siteKey;
      case 'THEME':
        return options.theme.name;
      case 'LANGUAGE':
        return options.language;
      case 'RETRY':
        return options.retryAutomatically ? 'auto' : 'never';
      case 'REFRESH_EXPIRED':
        return options.retry.name;
      case 'REFRESH_TIMEOUT':
        return options.refreshTimeout.name;
      default:
        return match.group(0) ?? ""; // Return the original match if no replacement found
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
         TurnstileReady(true);

         const widgetId = turnstile.render('#cf-turnstile', {
            sitekey: '<TURNSTILE_SITE_KEY>',
            theme: '<TURNSTILE_THEME>',
            language: '<TURNSTILE_LANGUAGE>',
            retry: '<TURNSTILE_RETRY>',
            'refresh-expired': '<TURNSTILE_REFRESH_EXPIRED>',
            'refresh-timeout': '<TURNSTILE_REFRESH_TIMEOUT>',
            callback: function (token) {
               TurnstileToken(token);
            },
            'error-callback': function (code) {
               TurnstileError(code);
            },
            'expired-callback': function (code) {
               console.log('expired token')
            }
         });
         TurnstileWidgetId(widgetId);
      });
   </script>
   <script>
      function refreshToken(widgetId) { turnstile.reset(widgetId); }
   </script>
   <script>
      function isExpired(widgetId) { return turnstile.isExpired(widgetId); }
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
