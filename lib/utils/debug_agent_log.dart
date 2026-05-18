import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Debug-mode NDJSON logs → ingest server (session 0af2c8).
void agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, Object?> data = const {},
  String runId = 'pre-fix',
}) {
  final payload = <String, Object?>{
    'sessionId': '0af2c8',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final line = '${jsonEncode(payload)}\n';
  debugPrint('[agent] $message ${data.isEmpty ? '' : data}');

  // #region agent log
  Future(() async {
    final hosts = <String>[
      '127.0.0.1',
      if (Platform.isAndroid) '10.0.2.2',
    ];
    for (final host in hosts) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(milliseconds: 800);
        final req = await client.postUrl(
          Uri.parse(
            'http://$host:7704/ingest/5555d578-0d91-41bd-b628-e61cfa09d4fb',
          ),
        );
        req.headers.set('Content-Type', 'application/json');
        req.headers.set('X-Debug-Session-Id', '0af2c8');
        req.write(line);
        await req.close();
        client.close(force: true);
        return;
      } catch (_) {
        continue;
      }
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/debug-0af2c8.log');
      await f.writeAsString(line, mode: FileMode.append);
    } catch (_) {}
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final f = File('debug-0af2c8.log');
        await f.writeAsString(line, mode: FileMode.append);
      } catch (_) {}
    }
  });
  // #endregion
}
