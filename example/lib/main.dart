import 'package:flutter/material.dart';
import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turnstile Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloudflare Turnstile Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VisibleTurnstilePage(),
                  ),
                );
              },
              icon: const Icon(Icons.security),
              label: const Text('Visible Turnstile'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InvisibleTurnstilePage(),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_off),
              label: const Text('Invisible Turnstile'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: Visible Turnstile Widget
class VisibleTurnstilePage extends StatefulWidget {
  const VisibleTurnstilePage({super.key});

  @override
  State<VisibleTurnstilePage> createState() => _VisibleTurnstilePageState();
}

class _VisibleTurnstilePageState extends State<VisibleTurnstilePage> {
  final TurnstileController _controller = TurnstileController();
  String? _token;
  String? _widgetId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visible Turnstile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CloudflareTurnstile(
                    siteKey: '3x00000000000000000000FF', // Test site key
                    controller: _controller,
                    options: TurnstileOptions(
                      size: TurnstileSize.flexible,
                      theme: TurnstileTheme.light,
                    ),
                    onTokenReceived: (token) {
                      setState(() {
                        _token = token;
                        _widgetId = _controller.widgetId;
                      });
                    },
                    onTokenExpired: () {
                      setState(() => _token = null);
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${error.message}')),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoCard(
                  title: 'Widget ID',
                  value: _widgetId ?? 'Not assigned',
                  color: _widgetId != null ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  title: 'Token',
                  value: _token ?? 'Waiting for token...',
                  color: _token != null ? Colors.green : Colors.grey,
                  isMonospace: true,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setState(() => _token = null);
                          await _controller.refreshToken();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _token != null
                            ? () async {
                                final isExpired = await _controller.isExpired();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isExpired
                                            ? 'Token expired'
                                            : 'Token valid',
                                      ),
                                      backgroundColor: isExpired
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Validate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required Color color,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Example: Invisible Turnstile Widget
class InvisibleTurnstilePage extends StatefulWidget {
  const InvisibleTurnstilePage({super.key});

  @override
  State<InvisibleTurnstilePage> createState() => _InvisibleTurnstilePageState();
}

class _InvisibleTurnstilePageState extends State<InvisibleTurnstilePage> {
  late CloudflareTurnstile _turnstile;
  String? _token;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _turnstile = CloudflareTurnstile.invisible(
      siteKey: '1x00000000000000000000BB', // Test site key
      onTokenReceived: (token) {
        if (mounted) {
          setState(() {
            _token = token;
            _isLoading = false;
          });
        }
      },
      onTokenExpired: () {
        if (mounted) setState(() => _token = null);
      },
    );
  }

  @override
  void dispose() {
    _turnstile.dispose();
    super.dispose();
  }

  Future<void> _getToken() async {
    setState(() => _isLoading = true);
    try {
      final token = await _turnstile.getToken();
      if (mounted) {
        setState(() {
          _token = token;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invisible Turnstile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Icon(
                    Icons.visibility_off,
                    size: 64,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Invisible Turnstile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Runs in the background without UI',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoCard(
                  title: 'Widget ID',
                  value: _turnstile.id ?? 'Not assigned',
                  color: _turnstile.id != null ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  title: 'Token',
                  value: _token ?? 'No token yet',
                  color: _token != null ? Colors.green : Colors.grey,
                  isMonospace: true,
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _getToken,
                              icon: const Icon(Icons.key),
                              label: const Text('Get Token'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                await _turnstile.refresh();
                                setState(() => _isLoading = false);
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _token != null
                            ? () async {
                                final isExpired = await _turnstile.isExpired();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isExpired
                                            ? 'Token expired'
                                            : 'Token valid',
                                      ),
                                      backgroundColor: isExpired
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Validate Token'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required Color color,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}
