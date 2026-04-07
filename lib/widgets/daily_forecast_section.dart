import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/wmo_codes.dart';

class DailyForecastSection extends StatelessWidget {
  final DailyForecast daily;

  const DailyForecastSection({super.key, required this.daily});

  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-DAY FORECAST',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(daily.time.length, (i) {
          final date = DateTime.parse('${daily.time[i]}T12:00:00');
          final code = daily.weatherCode[i];
          final info = getWmoInfo(code);
          final hi = daily.maxTemp[i].round();
          final lo = daily.minTemp[i].round();
          final dayLabel = i == 0 ? 'Today' : _dayNames[date.weekday % 7];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A3A),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    info.dayIcon,
                    size: 28,
                    color: info.dayColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      info.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$hi°',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$lo°',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
