// lib/presentation/screens/debug/network_diagnostic_screen.dart
//
// DROP this screen in your app temporarily to diagnose connectivity issues.
// Add route: GoRoute(path: '/debug/network', builder: (_, __) => const NetworkDiagnosticScreen())
// Then navigate to it from any screen while testing.
// REMOVE before production release.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class NetworkDiagnosticScreen extends StatefulWidget {
  const NetworkDiagnosticScreen({super.key});

  @override
  State<NetworkDiagnosticScreen> createState() =>
      _NetworkDiagnosticScreenState();
}

class _NetworkDiagnosticScreenState extends State<NetworkDiagnosticScreen> {
  final List<_DiagResult> _results = [];
  bool _running = false;

  // ── Edit these to match your setup ───────────────────────────────────────
  final List<String> _urlsToTest = [
    'http://10.0.2.2:8000/api/',          // Android Emulator → host machine
    'http://127.0.0.1:8000/api/',         // iOS Simulator → host machine
    'http://192.168.1.100:8000/api/',     // Replace with YOUR LAN IP
    'https://www.google.com',             // Internet check
  ];
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _runDiagnostics() async {
    setState(() {
      _results.clear();
      _running = true;
    });

    // 1. Device info
    _addInfo('Platform', Platform.operatingSystem);
    _addInfo('Is Physical Device?', _isPhysicalDevice() ? 'YES ⚠️' : 'NO (emulator/simulator)');

    // 2. Test each URL
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));

    for (final url in _urlsToTest) {
      await _testUrl(dio, url);
    }

    // 3. DNS check
    await _checkDns();

    setState(() => _running = false);
  }

  bool _isPhysicalDevice() {
    // Heuristic: emulators often have specific characteristics
    try {
      return !Platform.environment.containsKey('ANDROID_EMULATOR_SOCKET_NAME');
    } catch (_) {
      return true;
    }
  }

  Future<void> _testUrl(Dio dio, String url) async {
    final start = DateTime.now();
    try {
      final response = await dio.get(url);
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      _addSuccess(
        url,
        'HTTP ${response.statusCode} — ${elapsed}ms',
      );
    } on DioException catch (e) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      String detail;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          detail = 'CONNECTION TIMEOUT after ${elapsed}ms\n→ Server not reachable at this address';
          break;
        case DioExceptionType.receiveTimeout:
          detail = 'RECEIVE TIMEOUT after ${elapsed}ms\n→ Server reached but not responding';
          break;
        case DioExceptionType.connectionError:
          detail = 'CONNECTION ERROR\n→ ${e.message}';
          break;
        case DioExceptionType.badResponse:
          detail = 'HTTP ${e.response?.statusCode} (server IS reachable ✓)';
          // A 4xx/5xx still means we connected — the server is UP
          _addWarning(url, detail);
          return;
        default:
          detail = e.type.name;
      }
      _addError(url, detail);
    } catch (e) {
      _addError(url, e.toString());
    }
  }

  Future<void> _checkDns() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        _addSuccess('DNS lookup (google.com)', result.first.address);
      }
    } on SocketException catch (e) {
      _addError('DNS lookup', 'FAILED — No internet: ${e.message}');
    }
  }

  void _addInfo(String label, String value) {
    setState(() => _results.add(_DiagResult(
      label: label,
      detail: value,
      type: _ResultType.info,
    )));
  }

  void _addSuccess(String label, String detail) {
    setState(() => _results.add(_DiagResult(
      label: label,
      detail: detail,
      type: _ResultType.success,
    )));
  }

  void _addWarning(String label, String detail) {
    setState(() => _results.add(_DiagResult(
      label: label,
      detail: detail,
      type: _ResultType.warning,
    )));
  }

  void _addError(String label, String detail) {
    setState(() => _results.add(_DiagResult(
      label: label,
      detail: detail,
      type: _ResultType.error,
    )));
  }

  String get _summary {
    final buf = StringBuffer();
    for (final r in _results) {
      buf.writeln('[${r.type.name.toUpperCase()}] ${r.label}: ${r.detail}');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Diagnostics'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy results',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _summary));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Results copied to clipboard')),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            color: Colors.red.shade50,
            padding: const EdgeInsets.all(16),
            child: const Text(
              '⚠️ DEBUG TOOL — Remove before production release',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Fix guide
          ExpansionTile(
            leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
            title: const Text('Common Fixes',
                style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              _FixTile(
                title: 'Android physical device',
                fix: '→ Use your PC\'s LAN IP (e.g. 192.168.1.x:8000)\n'
                    '→ Run ipconfig (Win) or ifconfig (Mac)\n'
                    '→ Both phone & PC must be on same WiFi',
              ),
              _FixTile(
                title: 'Android Emulator',
                fix: '→ Use 10.0.2.2:8000 (maps to host localhost)',
              ),
              _FixTile(
                title: 'iOS Simulator',
                fix: '→ Use 127.0.0.1:8000 or localhost:8000',
              ),
              _FixTile(
                title: 'iOS Physical Device',
                fix: '→ Use your PC\'s LAN IP (same WiFi required)',
              ),
              _FixTile(
                title: 'Cleartext HTTP blocked (Android)',
                fix: '→ Add android:usesCleartextTraffic="true"\n'
                    '   in AndroidManifest.xml <application> tag',
              ),
              _FixTile(
                title: 'Server not running',
                fix: '→ Run: python manage.py runserver 0.0.0.0:8000\n'
                    '   (NOT just 127.0.0.1 — needs 0.0.0.0)',
              ),
              _FixTile(
                title: 'Firewall blocking',
                fix: '→ Temporarily disable Windows Firewall\n'
                    '→ Or add inbound rule for port 8000',
              ),
            ],
          ),

          const Divider(height: 1),

          // Results
          Expanded(
            child: _results.isEmpty && !_running
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.network_check,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Tap Run Diagnostics to start',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _results.length + (_running ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _results.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final r = _results[i];
                return _ResultCard(result: r);
              },
            ),
          ),

          // Run button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _running ? null : _runDiagnostics,
                  icon: _running
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.play_arrow),
                  label: Text(_running ? 'Running...' : 'Run Diagnostics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ResultType { info, success, warning, error }

class _DiagResult {
  final String label;
  final String detail;
  final _ResultType type;
  _DiagResult({required this.label, required this.detail, required this.type});
}

class _ResultCard extends StatelessWidget {
  final _DiagResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (result.type) {
      _ResultType.success => (Icons.check_circle, Colors.green, Colors.green.shade50),
      _ResultType.warning => (Icons.warning_amber, Colors.orange, Colors.orange.shade50),
      _ResultType.error   => (Icons.cancel, Colors.red, Colors.red.shade50),
      _ResultType.info    => (Icons.info_outline, Colors.blue, Colors.blue.shade50),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(result.detail,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FixTile extends StatelessWidget {
  final String title;
  final String fix;
  const _FixTile({required this.title, required this.fix});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(fix,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF374151), height: 1.5)),
        ],
      ),
    );
  }
}