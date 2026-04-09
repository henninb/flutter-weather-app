import 'package:flutter/material.dart';

import '../widgets/custom_api_section.dart';

/// HUMAN-protected API only (no Open-Meteo).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _spoofUserAgent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 22,
                    color: Color(0xFF4FC3F7),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Protected weather API',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Requests use HUMAN Bot Defender headers per Flutter integration docs.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8899AA),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _buildUaToggle(),
              const SizedBox(height: 20),
              CustomApiSection(spoofUserAgent: _spoofUserAgent),
              const SizedBox(height: 24),
              Text(
                'HUMAN Bot Defender',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF8899AA).withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUaToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3A4A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _spoofUserAgent = !_spoofUserAgent),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 36,
                child: Checkbox(
                  value: _spoofUserAgent,
                  onChanged: (v) => setState(() => _spoofUserAgent = v ?? false),
                  activeColor: const Color(0xFF4FC3F7),
                  checkColor: const Color(0xFF0F1923),
                  side: const BorderSide(color: Color(0xFF8899AA)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'UA: PhantomJS/flutter/brian (test)',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: Color(0xFFCCDDEE),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
