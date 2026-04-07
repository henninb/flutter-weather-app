import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/hourly_forecast_section.dart';
import '../widgets/daily_forecast_section.dart';
import '../widgets/custom_api_section.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<WeatherData> _weatherFuture;
  bool _sendBlockHeader = false;
  bool _spoofUserAgent = false;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _fetch();
  }

  Future<WeatherData> _fetch() {
    return WeatherService.fetchWeather(
      sendBlockHeader: _sendBlockHeader,
      spoofUserAgent: _spoofUserAgent,
    );
  }

  void _retry() {
    setState(() {
      _weatherFuture = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: FutureBuilder<WeatherData>(
          future: _weatherFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            }
            if (snapshot.hasData) {
              return _buildContent(snapshot.data!);
            }
            return _buildLoading();
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF4FC3F7),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading weather...',
            style: TextStyle(
              color: Color(0xFF8899AA),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF5350),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8899AA),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: const Color(0xFF0F1923),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderToggles() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3A4A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          _toggleRow(
            label: 'x-px-block: 1',
            value: _sendBlockHeader,
            onChanged: (v) {
              setState(() => _sendBlockHeader = v ?? false);
              _retry();
            },
          ),
          Divider(height: 1, color: const Color(0xFF2A3A4A)),
          _toggleRow(
            label: 'UA: PhantomJS/flutter/brian',
            value: _spoofUserAgent,
            onChanged: (v) {
              setState(() => _spoofUserAgent = v ?? false);
              _retry();
            },
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 36,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF4FC3F7),
                checkColor: const Color(0xFF0F1923),
                side: const BorderSide(color: Color(0xFF8899AA)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: Color(0xFFCCDDEE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(WeatherData data) {
    final dateStr =
        DateFormat('EEEE, MMMM d').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        final weather = await _fetch();
        setState(() {
          _weatherFuture = Future.value(weather);
        });
      },
      color: const Color(0xFF4FC3F7),
      backgroundColor: const Color(0xFF1A2A3A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color: Color(0xFF4FC3F7),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Minneapolis, MN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  color: const Color(0xFF4FC3F7),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8899AA),
              ),
            ),

            const SizedBox(height: 16),

            _buildHeaderToggles(),

            const SizedBox(height: 16),

            // Current weather
            CurrentWeatherCard(
              current: data.current,
              daily: data.daily,
            ),

            const SizedBox(height: 28),

            // Hourly forecast
            HourlyForecastSection(hourly: data.hourly),

            const SizedBox(height: 28),

            // Daily forecast
            DailyForecastSection(daily: data.daily),

            const SizedBox(height: 28),

            CustomApiSection(spoofUserAgent: _spoofUserAgent),

            const SizedBox(height: 24),

            // Footer
            Text(
              'Powered by Open-Meteo',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF8899AA).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
