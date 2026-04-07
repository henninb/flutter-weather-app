import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/wmo_codes.dart';

class HourlyForecastSection extends StatelessWidget {
  final HourlyForecast hourly;

  const HourlyForecastSection({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int startIdx = 0;
    for (int i = 0; i < hourly.time.length; i++) {
      if (DateTime.parse(hourly.time[i]).isAfter(now) ||
          DateTime.parse(hourly.time[i]).isAtSameMomentAs(now)) {
        startIdx = i;
        break;
      }
    }

    final count = 24.clamp(0, hourly.time.length - startIdx);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEXT 24 HOURS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final i = startIdx + index;
              final time = DateTime.parse(hourly.time[i]);
              final temp = hourly.temperature[i].round();
              final code = hourly.weatherCode[i];
              final isDay = hourly.isDay[i] == 1;
              final info = getWmoInfo(code);
              final isNow = index == 0;

              return Container(
                width: 76,
                decoration: BoxDecoration(
                  color: isNow
                      ? const Color(0x264FC3F7)
                      : const Color(0xFF1A2A3A),
                  borderRadius: BorderRadius.circular(16),
                  border: isNow
                      ? Border.all(color: const Color(0xFF4FC3F7), width: 1)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isNow ? 'Now' : _formatHour(time),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      isDay ? info.dayIcon : info.nightIcon,
                      size: 24,
                      color: isDay ? info.dayColor : info.nightColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$temp°',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatHour(DateTime date) {
    final h = date.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12$ampm';
  }
}
