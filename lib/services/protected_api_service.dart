import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/user_agent.dart';
import 'human_service.dart';

/// GET with HUMAN Bot Defender headers, 403 → [HumanService.handleBlockedResponse], JSON body.
///
/// **Collector vs your API:** beacon traffic goes to PerimeterX; your server sees app HTTP
/// requests with `X-PX-AUTHORIZATION` etc.
class ProtectedApiService {
  static const _postSolveRetryDelay = Duration(milliseconds: 200);

  /// Returns a JSON object: decoded map, or `{'_list': [...]}`, or `{'_value': ...}` for scalars.
  static Future<Map<String, dynamic>> fetchJson({
    required Uri url,
    bool spoofUserAgent = false,
    bool isPostSolveRetry = false,
  }) async {
    HumanService.logLine(
      isPostSolveRetry
          ? 'collector: POST-SOLVE retry — GET $url'
          : 'collector: ProtectedApiService.fetchJson — GET $url',
    );
    final humanHeaders = await HumanService.getHeaders();
    if (kOptionalUserAgentOverride.isNotEmpty) {
      humanHeaders['User-Agent'] = kOptionalUserAgentOverride;
    } else if (spoofUserAgent) {
      humanHeaders['User-Agent'] = 'PhantomJS/flutter/brian';
    }
    HumanService.logLine(
      'collector: outbound request header keys: ${humanHeaders.keys.toList()..sort()}',
    );
    late final http.Response response;
    try {
      response = await http
          .get(url, headers: humanHeaders)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
              'Request timed out after 30s — check network or URL: $url',
            ),
          );
    } on SocketException catch (e) {
      throw Exception(
        'Network error (${url.host}): ${e.message}. '
        'DNS failures are common for some free APIs (e.g. api.quotable.io); try the JSONPlaceholder preset.',
      );
    } on HttpException catch (e) {
      throw Exception('HTTP transport error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('HTTP client error: ${e.message}');
    }
    HumanService.logLine(
      'collector: response status=${response.statusCode}',
    );

    if (response.statusCode == 403) {
      HumanService.logLine(
        'collector: 403 — invoking humanHandleResponse with full HTTP response (URL, headers, body)',
      );
      final result = await HumanService.handleBlockedResponse(response);
      if (result == 'solved') {
        HumanService.logLine(
          'collector: challenge solved — waiting ${_postSolveRetryDelay.inMilliseconds}ms '
          'then retrying GET',
        );
        await Future<void>.delayed(_postSolveRetryDelay);
        return fetchJson(
          url: url,
          spoofUserAgent: spoofUserAgent,
          isPostSolveRetry: true,
        );
      }
      throw Exception('Request blocked (challenge $result)');
    }

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return _decodeJsonBody(response.body);
  }

  /// Best-effort public egress IPv4/IPv6 via HTTPS (api.ipify.org). Used when the API body does not echo client IP.
  static Future<String> fetchPublicIp() async {
    final uri = Uri.parse('https://api.ipify.org?format=json');
    late final http.Response response;
    try {
      response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('IP lookup timed out'),
      );
    } on SocketException catch (e) {
      throw Exception('Network error (ipify): ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('IP lookup failed: ${e.message}');
    }
    if (response.statusCode != 200) {
      throw Exception('IP lookup HTTP ${response.statusCode}');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (e) {
      throw Exception('IP lookup response is not JSON: ${e.message}');
    }
    if (decoded is! Map) {
      throw Exception('IP lookup response has unexpected shape');
    }
    final map = Map<String, dynamic>.from(decoded);
    final ip = map['ip'] as String?;
    if (ip == null || ip.isEmpty) {
      throw Exception('IP lookup returned empty ip');
    }
    return ip;
  }

  /// Extracts a client IP string if the backend includes it in JSON (common key names / shallow nesting).
  static String? reportedClientIpFromJson(Map<String, dynamic> data, [int depth = 0]) {
    if (depth > 4) {
      return null;
    }
    const directKeys = [
      'clientIp',
      'client_ip',
      'clientIP',
      'reportedIp',
      'reported_ip',
      'remoteIp',
      'remote_addr',
      'ip',
    ];
    for (final k in directKeys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) {
        return v.trim();
      }
    }
    const forwardedKeys = ['xForwardedFor', 'x-forwarded-for', 'X-Forwarded-For'];
    for (final k in forwardedKeys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) {
        return v.split(',').first.trim();
      }
    }
    for (final value in data.values) {
      if (value is Map<String, dynamic>) {
        final found = reportedClientIpFromJson(value, depth + 1);
        if (found != null) {
          return found;
        }
      } else if (value is Map) {
        final found = reportedClientIpFromJson(
          Map<String, dynamic>.from(value),
          depth + 1,
        );
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> _decodeJsonBody(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw Exception('Response body is not valid JSON: ${e.message}');
    }
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    if (decoded is List) {
      return {'_list': decoded};
    }
    return {'_value': decoded};
  }
}
