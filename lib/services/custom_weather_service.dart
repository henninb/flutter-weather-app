import 'dart:convert';
import 'package:http/http.dart' as http;
import 'human_service.dart';

class CustomWeatherService {
  static const _url = 'https://vercel.bhenning.com/api/weather';

  static Future<Map<String, dynamic>> fetch({bool spoofUserAgent = false}) async {
    final uri = Uri.parse(_url);
    final humanHeaders = await HumanService.getHeaders();
    if (spoofUserAgent) {
      humanHeaders['User-Agent'] = 'PhantomJS/flutter/brian';
    }
    print('Custom API request headers: $humanHeaders');
    final response = await http.get(uri, headers: humanHeaders);
    print('Custom API response headers: ${response.headers}');
    print('Custom API status: ${response.statusCode}');

    if (response.statusCode == 403) {
      final result = await HumanService.handleResponse(
        responseBody: response.body,
        requestUrl: uri.toString(),
      );
      if (result == 'solved') {
        return fetch();
      }
      throw Exception('Request blocked (challenge $result)');
    }

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
