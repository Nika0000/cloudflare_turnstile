import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TurnstileController _controller = TurnstileController();
  final TurnstileOptions _options = TurnstileOptions(
    mode: TurnstileMode.managed,
    size: TurnstileSize.normal,
    theme: TurnstileTheme.light,
    refreshExpired: TurnstileRefreshExpired.manual,
    language: 'ru',
    retryAutomatically: false,
  );

  String? _token;

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: _token != null ? Text(_token!) : const CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 48.0),
                  CloudFlareTurnstile(
                    siteKey: '2x00000000000000000000BB',
                    options: _options,
                    controller: _controller,
                    onTokenRecived: (token) {
                      setState(() {
                        _token = token;
                      });
                    },
                    onTokenExpired: () {},
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    },
                  ),
                  const SizedBox(height: 48.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _token = null;
                          });

                          await _controller.refreshToken();
                        },
                        child: const Text('Refresh Token'),
                      ),
                      const SizedBox(width: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          _controller.isExpired().then((isExpired) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Token is ${isExpired ? "Expired" : "Valid"}'),
                              ),
                            );
                          });
                        },
                        child: const Text('Validate Token'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
