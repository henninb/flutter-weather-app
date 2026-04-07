import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/wmo_codes.dart';

class CurrentWeatherCard extends StatelessWidget {
  final CurrentWeather current;
  final DailyForecast daily;

  const CurrentWeatherCard({
    super.key,
    required this.current,
    required this.daily,
  });

  @override
  Widget build(BuildContext context) {
    final info = getWmoInfo(current.weatherCode);
    final isDay = current.isDay == 1;
    final icon = isDay ? info.dayIcon : info.nightIcon;
    final iconColor = isDay ? info.dayColor : info.nightColor;

    return Column(
      children: [
        Icon(icon, size: 72, color: iconColor),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${current.temperature.round()}',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w700,
                letterSpacing: -4,
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 2),
              child: Text(
                '°F',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          info.description,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 28),
        _detailsGrid(context),
      ],
    );
  }

  Widget _detailsGrid(BuildContext context) {
    final items = [
      _DetailItem(label: 'Feels Like', value: '${current.apparentTemperature.round()}°F'),
      _DetailItem(label: 'Humidity', value: '${current.humidity}%'),
      _DetailItem(label: 'Wind', value: '${current.windSpeed.round()} mph'),
      _DetailItem(label: 'UV Index', value: daily.uvIndexMax[0].toStringAsFixed(1)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A3A),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.value,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});
}
