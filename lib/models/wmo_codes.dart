import 'package:flutter/material.dart';

class WmoInfo {
  final String description;
  final IconData dayIcon;
  final IconData nightIcon;
  final Color dayColor;
  final Color nightColor;

  const WmoInfo({
    required this.description,
    required this.dayIcon,
    required this.nightIcon,
    required this.dayColor,
    required this.nightColor,
  });
}

const wmoCodes = <int, WmoInfo>{
  0: WmoInfo(
    description: 'Clear Sky',
    dayIcon: Icons.wb_sunny_rounded,
    nightIcon: Icons.nightlight_round,
    dayColor: Color(0xFFFFC107),
    nightColor: Color(0xFF90CAF9),
  ),
  1: WmoInfo(
    description: 'Mainly Clear',
    dayIcon: Icons.wb_sunny_rounded,
    nightIcon: Icons.nightlight_round,
    dayColor: Color(0xFFFFC107),
    nightColor: Color(0xFF90CAF9),
  ),
  2: WmoInfo(
    description: 'Partly Cloudy',
    dayIcon: Icons.wb_cloudy_rounded,
    nightIcon: Icons.cloud_rounded,
    dayColor: Color(0xFFFFD54F),
    nightColor: Color(0xFFB0BEC5),
  ),
  3: WmoInfo(
    description: 'Overcast',
    dayIcon: Icons.cloud_rounded,
    nightIcon: Icons.cloud_rounded,
    dayColor: Color(0xFFB0BEC5),
    nightColor: Color(0xFFB0BEC5),
  ),
  45: WmoInfo(
    description: 'Foggy',
    dayIcon: Icons.foggy,
    nightIcon: Icons.foggy,
    dayColor: Color(0xFFB0BEC5),
    nightColor: Color(0xFFB0BEC5),
  ),
  48: WmoInfo(
    description: 'Depositing Rime Fog',
    dayIcon: Icons.foggy,
    nightIcon: Icons.foggy,
    dayColor: Color(0xFFB0BEC5),
    nightColor: Color(0xFFB0BEC5),
  ),
  51: WmoInfo(
    description: 'Light Drizzle',
    dayIcon: Icons.grain_rounded,
    nightIcon: Icons.grain_rounded,
    dayColor: Color(0xFF81D4FA),
    nightColor: Color(0xFF81D4FA),
  ),
  53: WmoInfo(
    description: 'Moderate Drizzle',
    dayIcon: Icons.grain_rounded,
    nightIcon: Icons.grain_rounded,
    dayColor: Color(0xFF4FC3F7),
    nightColor: Color(0xFF4FC3F7),
  ),
  55: WmoInfo(
    description: 'Dense Drizzle',
    dayIcon: Icons.water_drop_rounded,
    nightIcon: Icons.water_drop_rounded,
    dayColor: Color(0xFF29B6F6),
    nightColor: Color(0xFF29B6F6),
  ),
  56: WmoInfo(
    description: 'Freezing Drizzle',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFF80DEEA),
    nightColor: Color(0xFF80DEEA),
  ),
  57: WmoInfo(
    description: 'Heavy Freezing Drizzle',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFF4DD0E1),
    nightColor: Color(0xFF4DD0E1),
  ),
  61: WmoInfo(
    description: 'Slight Rain',
    dayIcon: Icons.water_drop_rounded,
    nightIcon: Icons.water_drop_rounded,
    dayColor: Color(0xFF4FC3F7),
    nightColor: Color(0xFF4FC3F7),
  ),
  63: WmoInfo(
    description: 'Moderate Rain',
    dayIcon: Icons.water_drop_rounded,
    nightIcon: Icons.water_drop_rounded,
    dayColor: Color(0xFF29B6F6),
    nightColor: Color(0xFF29B6F6),
  ),
  65: WmoInfo(
    description: 'Heavy Rain',
    dayIcon: Icons.water_drop_rounded,
    nightIcon: Icons.water_drop_rounded,
    dayColor: Color(0xFF039BE5),
    nightColor: Color(0xFF039BE5),
  ),
  66: WmoInfo(
    description: 'Freezing Rain',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFF80DEEA),
    nightColor: Color(0xFF80DEEA),
  ),
  67: WmoInfo(
    description: 'Heavy Freezing Rain',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFF4DD0E1),
    nightColor: Color(0xFF4DD0E1),
  ),
  71: WmoInfo(
    description: 'Slight Snow',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFFE0E0E0),
    nightColor: Color(0xFFE0E0E0),
  ),
  73: WmoInfo(
    description: 'Moderate Snow',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFFE0E0E0),
    nightColor: Color(0xFFE0E0E0),
  ),
  75: WmoInfo(
    description: 'Heavy Snow',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFFBDBDBD),
    nightColor: Color(0xFFBDBDBD),
  ),
  77: WmoInfo(
    description: 'Snow Grains',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFFE0E0E0),
    nightColor: Color(0xFFE0E0E0),
  ),
  80: WmoInfo(
    description: 'Slight Showers',
    dayIcon: Icons.water_drop_rounded,
    nightIcon: Icons.water_drop_rounded,
    dayColor: Color(0xFF4FC3F7),
    nightColor: Color(0xFF4FC3F7),
  ),
  81: WmoInfo(
    description: 'Moderate Showers',
    dayIcon: Icons.water_drop_rounded,
    nightIcon: Icons.water_drop_rounded,
    dayColor: Color(0xFF29B6F6),
    nightColor: Color(0xFF29B6F6),
  ),
  82: WmoInfo(
    description: 'Violent Showers',
    dayIcon: Icons.thunderstorm_rounded,
    nightIcon: Icons.thunderstorm_rounded,
    dayColor: Color(0xFF7E57C2),
    nightColor: Color(0xFF7E57C2),
  ),
  85: WmoInfo(
    description: 'Slight Snow Showers',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFFE0E0E0),
    nightColor: Color(0xFFE0E0E0),
  ),
  86: WmoInfo(
    description: 'Heavy Snow Showers',
    dayIcon: Icons.ac_unit_rounded,
    nightIcon: Icons.ac_unit_rounded,
    dayColor: Color(0xFFBDBDBD),
    nightColor: Color(0xFFBDBDBD),
  ),
  95: WmoInfo(
    description: 'Thunderstorm',
    dayIcon: Icons.thunderstorm_rounded,
    nightIcon: Icons.thunderstorm_rounded,
    dayColor: Color(0xFF7E57C2),
    nightColor: Color(0xFF7E57C2),
  ),
  96: WmoInfo(
    description: 'Thunderstorm w/ Hail',
    dayIcon: Icons.thunderstorm_rounded,
    nightIcon: Icons.thunderstorm_rounded,
    dayColor: Color(0xFF7E57C2),
    nightColor: Color(0xFF7E57C2),
  ),
  99: WmoInfo(
    description: 'Thunderstorm w/ Heavy Hail',
    dayIcon: Icons.thunderstorm_rounded,
    nightIcon: Icons.thunderstorm_rounded,
    dayColor: Color(0xFF7E57C2),
    nightColor: Color(0xFF7E57C2),
  ),
};

WmoInfo getWmoInfo(int code) {
  return wmoCodes[code] ?? wmoCodes[0]!;
}
