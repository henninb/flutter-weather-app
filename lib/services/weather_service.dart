import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static const double _lat = 44.9778;
  static const double _lon = -93.265;

  static Future<WeatherData> fetchWeather({
    bool sendBlockHeader = false,
    bool spoofUserAgent = false,
  }) async {
    final params = {
      'latitude': _lat.toString(),
      'longitude': _lon.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day',
      'hourly': 'temperature_2m,weather_code,is_day',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,uv_index_max',
      'temperature_unit': 'fahrenheit',
      'wind_speed_unit': 'mph',
      'timezone': 'America/Chicago',
      'forecast_days': '7',
    };

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', params);

    final headers = <String, String>{};
    if (sendBlockHeader) {
      headers['x-px-block'] = '1';
    }
    if (spoofUserAgent) {
      headers['User-Agent'] = 'PhantomJS/flutter/brian';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherData.fromJson(json);
  }
}
