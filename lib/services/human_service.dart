import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../config/human_security_app_id.dart';

export '../config/human_security_app_id.dart' show kHumanSecurityAppId;

/// Human Security Bot Defender bridge per
/// https://docs.humansecurity.com/applications/flutter-integration
///
/// Native code adds collector-derived headers; pass 403 bodies to
/// [handleBlockedResponse] so the SDK can present a challenge.
class HumanService {
  static const _channel = MethodChannel('com.humansecurity/sdk');
  static const _logName = 'Human';

  static bool _nativeConfigureSucceeded = false;

  /// Calls native `HumanSecurity.start` with [kHumanSecurityAppId]. Invoke once from `main()` before [runApp].
  ///
  /// **Collector logging:** the SDK does not expose raw HTTPS to the app. On **iOS**, Xcode shows
  /// `[HumanSecurity] collector SDK: BD.didUpdateHeaders…` when headers refresh after collector work;
  /// add scheme env **`HUMAN_CFNETWORK_LOG=1`** for verbose CFNetwork logs (see `AppDelegate.swift`).
  static Future<void> ensureNativeSdkConfigured() async {
    if (_nativeConfigureSucceeded) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(
        'humanConfigure',
        <String, dynamic>{'appId': kHumanSecurityAppId},
      );
      _nativeConfigureSucceeded = true;
      _logHumanAppId('native SDK configured');
    } catch (e, st) {
      logLine('collector: humanConfigure failed: $e');
      developer.log(
        'humanConfigure failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Visible in `flutter run` / Xcode (via [debugPrint]); also in DevTools via [developer.log].
  static void logLine(String message) {
    debugPrint('[$_logName] $message');
    developer.log(message, name: _logName);
  }

  static void _logHumanAppId(String context) {
    logLine('collector: HUMAN_APP_ID=$kHumanSecurityAppId — $context');
  }

  /// Value of `X-PX-AUTHORIZATION` from [headers], or null if missing (case-insensitive key).
  static String? pxAuthorizationValue(Map<String, String> headers) {
    for (final e in headers.entries) {
      if (e.key.toLowerCase() == 'x-px-authorization') {
        return e.value;
      }
    }
    return null;
  }

  /// Logs the PX auth header. In debug, logs the raw value; always logs [level] semantics.
  ///
  /// Mobile SDK format is `{level}:{payload}`. For level **2**, if the base64 payload decodes to
  /// JSON with **h, t, u, v**, we treat that as a **healthy** collector token (see
  /// [_logPxLevel2PayloadShape]).
  static void _logPxAuthorizationValue(Map<String, String> map) {
    final v = pxAuthorizationValue(map);
    if (v == null || v.isEmpty) {
      logLine(
        'collector: X-PX-AUTHORIZATION — absent (stub SDK, or collector not ready yet)',
      );
      return;
    }
    if (kDebugMode) {
      logLine('collector: X-PX-AUTHORIZATION = $v');
    } else {
      logLine(
        'collector: X-PX-AUTHORIZATION — present, length ${v.length} (run debug build to log full value)',
      );
    }
    _logPxAuthorizationSemantics(v);
  }

  /// Interprets `X-PX-AUTHORIZATION` level prefix (Mobile SDK). Payload after `:` is not validated here.
  static void _logPxAuthorizationSemantics(String value) {
    final i = value.indexOf(':');
    if (i <= 0) {
      logLine(
        'collector: X-PX-AUTHORIZATION — unexpected shape (expected `level:…`)',
      );
      return;
    }
    final level = int.tryParse(value.substring(0, i));
    if (level == null) {
      return;
    }
    switch (level) {
      case 1:
        logLine(
          'collector: X-PX-AUTHORIZATION level 1 = no token yet / async startup — not a scored risk token yet',
        );
        break;
      case 2:
        _logPxLevel2PayloadShape(value, i);
        break;
      case 3:
        logLine(
          'collector: X-PX-AUTHORIZATION level 3 = pinning / possible MITM — not a normal mobile auth token',
        );
        break;
      case 4:
        logLine(
          'collector: X-PX-AUTHORIZATION level 4 = bypass (legacy) — not a normal auth path',
        );
        break;
      default:
        logLine(
          'collector: X-PX-AUTHORIZATION — unknown level $level',
        );
    }
  }

  /// Decodes base64 JSON after `2:`; if keys **h, t, u, v** are all present, logs a healthy token.
  static void _logPxLevel2PayloadShape(String fullValue, int colonIndex) {
    final payload = fullValue.substring(colonIndex + 1);
    if (payload.isEmpty) {
      logLine(
        'collector: X-PX-AUTHORIZATION level 2 — empty payload after `2:`',
      );
      return;
    }
    try {
      final bytes = base64Decode(payload);
      final obj = json.decode(utf8.decode(bytes));
      if (obj is Map) {
        final keySet = obj.keys.map((k) => k.toString()).toSet();
        final sorted = keySet.toList()..sort();
        final healthy = const {'h', 't', 'u', 'v'}.every(keySet.contains);
        if (healthy) {
          logLine(
            'collector: X-PX-AUTHORIZATION level-2 payload decodes to JSON keys: '
            '${sorted.join(", ")} — indicates a healthy token',
          );
        } else {
          logLine(
            'collector: X-PX-AUTHORIZATION level-2 payload decodes to JSON keys: '
            '${sorted.join(", ")} — expected h, t, u, v for a healthy token; check Collector, ATS, VPN',
          );
        }
        return;
      }
    } catch (_) {
      // Payload shape varies by SDK version.
    }
    logLine(
      'collector: X-PX-AUTHORIZATION level 2 — payload not decodable as base64 JSON; '
      'debug network, ATS, SSL to Collector (*.perimeterx.net); v3+ may also use X-PX-HELLO',
    );
  }

  /// v3+ may send connection/pinning detail here (codes 2/3 etc.); pair with X-PX-AUTHORIZATION level 2 debugging.
  static void _logPxHelloIfPresent(Map<String, String> map) {
    String? hello;
    for (final e in map.entries) {
      if (e.key.toLowerCase() == 'x-px-hello') {
        hello = e.value;
        break;
      }
    }
    if (hello == null || hello.isEmpty) {
      return;
    }
    logLine(
      'collector: X-PX-HELLO present (length=${hello.length}) — v3+ uses this for connection/pinning signals alongside X-PX-AUTHORIZATION',
    );
    if (kDebugMode) {
      logLine('collector: X-PX-HELLO = $hello');
    }
  }

  /// Matches docs: `invokeMethod('humanGetHeaders')` → JSON string of header map.
  static Future<Map<String, String>> getHeaders() async {
    _logHumanAppId('humanGetHeaders');
    logLine('collector: invoking humanGetHeaders (native BD.headersForURLRequest)');
    try {
      final String? headersJson = await _channel
          .invokeMethod<String>('humanGetHeaders')
          .timeout(const Duration(seconds: 5));
      if (headersJson == null || headersJson.isEmpty) {
        logLine('collector: humanGetHeaders returned empty (SDK inactive or stub)');
        return {};
      }
      final map = Map<String, String>.from(
        json.decode(headersJson) as Map<dynamic, dynamic>,
      );
      final keys = map.keys.toList()..sort();
      logLine(
        'collector: humanGetHeaders ok — ${map.length} header(s), keys: ${keys.join(", ")}',
      );
      _logPxAuthorizationValue(map);
      _logPxHelloIfPresent(map);
      return map;
    } catch (e, st) {
      logLine('collector: humanGetHeaders failed: $e');
      developer.log(
        'collector: humanGetHeaders failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return {};
    }
  }

  /// Logs the full 403 body in numbered chunks so `flutter run` / Xcode output can be copied.
  static const _pasteChunkSize = 1600;

  static void _log403BodyForPaste(http.Response response) {
    final body = response.body;
    final n = body.length;
    final b = response.bodyBytes.length;
    logLine(
      'collector: --- 403 BODY FOR PASTE START (string length=$n, bytes=$b) ---',
    );
    if (n == 0) {
      logLine('collector: 403 body (empty)');
      logLine('collector: --- 403 BODY FOR PASTE END ---');
      return;
    }
    var start = 0;
    var part = 0;
    final total = (n + _pasteChunkSize - 1) ~/ _pasteChunkSize;
    while (start < n) {
      part++;
      final end = (start + _pasteChunkSize < n) ? start + _pasteChunkSize : n;
      logLine('collector: 403_body_chunk $part/$total: ${body.substring(start, end)}');
      start = end;
    }
    logLine('collector: --- 403 BODY FOR PASTE END ---');
  }

  /// **iOS:** Native docs require the real [HTTPURLResponse] (URL, status, **headers**) plus
  /// body [Data]. Passing only the body with a synthetic response often yields `handled == false`.
  /// **Android:** Body string is passed; map is accepted for parity.
  ///
  /// Returns `"solved"`, `"cancelled"`, or `"false"`.
  static Future<String> handleBlockedResponse(http.Response response) async {
    _logHumanAppId('humanHandleResponse');
    if (response.statusCode == 403) {
      _log403BodyForPaste(response);
    }
    final url = response.request?.url.toString() ?? '';
    logLine(
      'collector: invoking humanHandleResponse — status=${response.statusCode}, '
      'url=$url, headerKeys=${response.headers.keys.toList()..sort()}, '
      'bodyLength=${response.body.length}',
    );
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'humanHandleResponse',
        <String, dynamic>{
          'body': response.body,
          'bodyBase64': base64Encode(response.bodyBytes),
          'statusCode': response.statusCode,
          'requestUrl': url,
          'headers': response.headers,
        },
      );
      if (raw is Map) {
        final r = raw['result'] as String? ?? 'false';
        final can = raw['canHandle'];
        final handled = raw['handled'];
        final prefix = raw['bodyPrefix'] as String?;
        final hint = raw['hint'] as String?;
        logLine(
          'collector: humanHandleResponse → $r '
          '(native canHandle=$can handled=$handled)',
        );
        if (prefix != null && prefix.isNotEmpty) {
          logLine('collector: 403 body prefix (native): $prefix');
        }
        if (hint != null && hint.isNotEmpty) {
          logLine('collector: hint: $hint');
        }
        return r;
      }
      if (raw is String) {
        logLine('collector: humanHandleResponse → $raw');
        return raw;
      }
      logLine('collector: humanHandleResponse → false (unexpected native type)');
      return 'false';
    } on PlatformException catch (e, st) {
      logLine('collector: humanHandleResponse platform error: ${e.message}');
      developer.log(
        'collector: humanHandleResponse platform error',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return 'false';
    } catch (e, st) {
      logLine('collector: humanHandleResponse failed: $e');
      developer.log(
        'collector: humanHandleResponse failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return 'false';
    }
  }
}
