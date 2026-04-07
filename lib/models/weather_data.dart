class WeatherData {
  final CurrentWeather current;
  final HourlyForecast hourly;
  final DailyForecast daily;

  WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      current: CurrentWeather.fromJson(json['current']),
      hourly: HourlyForecast.fromJson(json['hourly']),
      daily: DailyForecast.fromJson(json['daily']),
    );
  }
}

class CurrentWeather {
  final double temperature;
  final int humidity;
  final double apparentTemperature;
  final int weatherCode;
  final double windSpeed;
  final int isDay;

  CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.isDay,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num).toInt(),
      apparentTemperature: (json['apparent_temperature'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      isDay: (json['is_day'] as num).toInt(),
    );
  }
}

class HourlyForecast {
  final List<String> time;
  final List<double> temperature;
  final List<int> weatherCode;
  final List<int> isDay;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.isDay,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: List<String>.from(json['time']),
      temperature:
          (json['temperature_2m'] as List).map((e) => (e as num).toDouble()).toList(),
      weatherCode:
          (json['weather_code'] as List).map((e) => (e as num).toInt()).toList(),
      isDay: (json['is_day'] as List).map((e) => (e as num).toInt()).toList(),
    );
  }
}

class DailyForecast {
  final List<String> time;
  final List<int> weatherCode;
  final List<double> maxTemp;
  final List<double> minTemp;
  final List<double> uvIndexMax;

  DailyForecast({
    required this.time,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    required this.uvIndexMax,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      time: List<String>.from(json['time']),
      weatherCode:
          (json['weather_code'] as List).map((e) => (e as num).toInt()).toList(),
      maxTemp:
          (json['temperature_2m_max'] as List).map((e) => (e as num).toDouble()).toList(),
      minTemp:
          (json['temperature_2m_min'] as List).map((e) => (e as num).toDouble()).toList(),
      uvIndexMax:
          (json['uv_index_max'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}
