import 'dart:convert';

import 'package:http/http.dart' as http;
import 'human_service.dart';

/// Protected backend (HUMAN Bot Defender).
///
/// **Collector vs your API:** PerimeterX “collector” / beacon traffic is sent from the
/// mobile SDK to **PerimeterX infrastructure** (e.g. `collector-*.perimeterx.net`), not
/// to your own API hostname. Your backend should see **application HTTP requests** (e.g.
/// `GET /api/weather`) that include Bot Defender headers such as `X-PX-AUTHORIZATION`.
/// You will not see separate “collector” URL hits on your server.
class CustomWeatherService {
  static const _url = 'https://vercel.bhenning.com/api/weather';

  /// Brief pause so native BD state can settle before the next [HumanService.getHeaders].
  static const _postSolveRetryDelay = Duration(milliseconds: 200);

  static Future<Map<String, dynamic>> fetch({bool spoofUserAgent = false}) =>
      _fetchImpl(spoofUserAgent: spoofUserAgent, isPostSolveRetry: false);

  static Future<Map<String, dynamic>> _fetchImpl({
    required bool spoofUserAgent,
    bool isPostSolveRetry = false,
  }) async {
    final uri = Uri.parse(_url);
    HumanService.logLine(
      isPostSolveRetry
          ? 'collector: POST-SOLVE retry — GET $uri (fresh BD headers)'
          : 'collector: CustomWeatherService.fetch — GET $uri',
    );
    final humanHeaders = await HumanService.getHeaders();
    if (spoofUserAgent) {
      humanHeaders['User-Agent'] = 'PhantomJS/flutter/brian';
    }
    HumanService.logLine(
      'collector: outbound request header keys: ${humanHeaders.keys.toList()..sort()}',
    );
    final response = await http.get(uri, headers: humanHeaders);
    HumanService.logLine(
      'collector: response status=${response.statusCode} (Custom API)',
    );

    if (response.statusCode == 403) {
      HumanService.logLine(
        'collector: 403 — invoking humanHandleResponse with full HTTP response (URL, headers, body)',
      );
      final result = await HumanService.handleBlockedResponse(response);
      if (result == 'solved') {
        HumanService.logLine(
          'collector: challenge solved — waiting ${_postSolveRetryDelay.inMilliseconds}ms '
          'for native BD to refresh, then retrying API GET',
        );
        await Future<void>.delayed(_postSolveRetryDelay);
        return _fetchImpl(
          spoofUserAgent: spoofUserAgent,
          isPostSolveRetry: true,
        );
      }
      throw Exception('Request blocked (challenge $result)');
    }

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
