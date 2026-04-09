import 'package:flutter/material.dart';

import '../config/protected_endpoints.dart';
import '../models/wmo_codes.dart';
import '../services/protected_api_service.dart';

class CustomApiSection extends StatefulWidget {
  final bool spoofUserAgent;
  final ProtectedEndpoint endpoint;

  const CustomApiSection({
    super.key,
    required this.endpoint,
    this.spoofUserAgent = false,
  });

  @override
  State<CustomApiSection> createState() => _CustomApiSectionState();
}

class _CustomApiSectionState extends State<CustomApiSection> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProtectedApiService.fetchJson(
      url: widget.endpoint.uri,
      spoofUserAgent: widget.spoofUserAgent,
    );
  }

  @override
  void didUpdateWidget(covariant CustomApiSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spoofUserAgent != widget.spoofUserAgent ||
        oldWidget.endpoint.id != widget.endpoint.id) {
      _future = ProtectedApiService.fetchJson(
        url: widget.endpoint.uri,
        spoofUserAgent: widget.spoofUserAgent,
      );
    }
  }

  void refresh() {
    setState(() {
      _future = ProtectedApiService.fetchJson(
      url: widget.endpoint.uri,
      spoofUserAgent: widget.spoofUserAgent,
    );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cloud_queue_rounded, size: 18, color: Color(0xFF4FC3F7)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Station Observation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE8EDF2),
                ),
              ),
            ),
            GestureDetector(
              onTap: refresh,
              child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF4FC3F7)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildContainer(
                child: const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF4FC3F7),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return _buildContainer(
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Color(0xFFEF5350), fontSize: 13),
                ),
              );
            }
            if (snapshot.hasData) {
              return _buildObservation(snapshot.data!);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildObservation(Map<String, dynamic> data) {
    final observations = data['observations'] as List<dynamic>?;
    if (observations == null || observations.isEmpty) {
      return _buildContainer(
        child: const Text(
          'No observations available',
          style: TextStyle(color: Color(0xFF8899AA), fontSize: 13),
        ),
      );
    }

    final obs = observations[0] as Map<String, dynamic>;
    final imperial = obs['imperial'] as Map<String, dynamic>? ?? {};
    final temp = imperial['temp'];
    final windChill = imperial['windChill'];
    final pressure = imperial['pressure'];
    final humidity = obs['humidity'];
    final windSpeed = obs['windSpeed'];
    final precipitation = obs['precipitation'];
    final weatherCode = obs['weatherCode'] as int? ?? 0;
    final timeStr = obs['obsTimeLocal'] as String? ?? '';
    final wmoInfo = getWmoInfo(weatherCode);

    final time = timeStr.isNotEmpty ? timeStr.split('T').last : '';

    return _buildContainer(
      child: Column(
        children: [
          Row(
            children: [
              Icon(wmoInfo.dayIcon, size: 32, color: wmoInfo.dayColor),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${temp ?? '--'}°F',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8EDF2),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    wmoInfo.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8899AA),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (time.isNotEmpty)
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8899AA),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDetail('Feels Like', '${windChill ?? '--'}°F'),
              _buildDetail('Humidity', '${humidity ?? '--'}%'),
              _buildDetail('Wind', '${windSpeed ?? '--'} mph'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDetail('Pressure', '${pressure ?? '--'} in'),
              _buildDetail('Precip', '${precipitation ?? '--'} in'),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8899AA),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE8EDF2),
            ),
          ),
        ],
      ),
    );
  }
}
