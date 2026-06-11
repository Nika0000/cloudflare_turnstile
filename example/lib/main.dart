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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TurnstileController _controller = TurnstileController();
  String? _token;
  String? _widgetId;
  int _mountCount = 0;
  bool _showWidget = true;

  @override
  void initState() {
    super.initState();
    _mountCount++;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turnstile Refresh Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTestInstructions(),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Mount Count',
                  value: '$_mountCount (increases on hot reload, not F5)',
                  color: Colors.purple,
                ),
                const SizedBox(height: 12),
                if (_showWidget)
                  Center(
                    child: CloudflareTurnstile(
                      siteKey: '3x00000000000000000000FF',
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
                          SnackBar(
                            content: Text('Error: ${error.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                if (!_showWidget)
                  Container(
                    height: 65,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Widget removed',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 16),
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
                const Text(
                  'Test Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showWidget = !_showWidget;
                            if (!_showWidget) {
                              _token = null;
                              _widgetId = null;
                            }
                          });
                        },
                        icon: Icon(
                          _showWidget ? Icons.visibility_off : Icons.visibility,
                        ),
                        label: Text(
                          _showWidget ? 'Remove Widget' : 'Add Widget',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setState(() => _token = null);
                          await _controller.refreshToken();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Token'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OtherPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.navigate_next),
                        label: const Text('Navigate Away'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Replace Page'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecondTurnstilePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Open Second Turnstile Page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Scenarios:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text('1. Press F5 - widget should re-render without errors'),
          Text('2. "Remove Widget" then "Add Widget" - should re-render'),
          Text('3. "Navigate Away" then back - should re-render'),
          Text('4. "Replace Page" - old widget cleaned up, new one renders'),
          Text('5. Open console - no "widget already exists" errors'),
        ],
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class OtherPage extends StatelessWidget {
  const OtherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Other Page'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Navigated away from Turnstile',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'The widget should have been disposed.\n'
              'Press back and verify it re-renders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondTurnstilePage extends StatefulWidget {
  const SecondTurnstilePage({super.key});

  @override
  State<SecondTurnstilePage> createState() => _SecondTurnstilePageState();
}

class _SecondTurnstilePageState extends State<SecondTurnstilePage> {
  final TurnstileController _controller = TurnstileController();
  String? _token;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Turnstile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'This page has its own Turnstile widget.\n'
                  'Tests multiple widgets across navigation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                CloudflareTurnstile(
                  siteKey: '3x00000000000000000000FF',
                  controller: _controller,
                  options: TurnstileOptions(
                    size: TurnstileSize.flexible,
                    theme: TurnstileTheme.light,
                  ),
                  onTokenReceived: (token) {
                    setState(() => _token = token);
                  },
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${error.message}')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_token != null ? Colors.green : Colors.grey)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _token != null ? 'Token received' : 'Waiting...',
                    style: TextStyle(
                      color: _token != null ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
