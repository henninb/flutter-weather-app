import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/protected_endpoints.dart';
import '../services/protected_api_service.dart';

/// Try any configured URL or a custom HTTPS URL with the same HUMAN header + 403 flow.
class ProtectedApiScreen extends StatefulWidget {
  const ProtectedApiScreen({super.key});

  @override
  State<ProtectedApiScreen> createState() => _ProtectedApiScreenState();
}

class _ProtectedApiScreenState extends State<ProtectedApiScreen> {
  ProtectedEndpoint _selected = kProtectedEndpoints.last;
  final _customController = TextEditingController();
  bool _spoofUa = false;
  Future<Map<String, dynamic>>? _future;
  String? _error;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _runFetch() {
    final custom = _customController.text.trim();
    Uri uri;
    if (custom.isNotEmpty) {
      final u = Uri.tryParse(custom);
      if (u == null || !u.hasScheme || u.host.isEmpty) {
        setState(() {
          _error = 'Enter a valid https:// URL';
          _future = null;
        });
        return;
      }
      uri = u;
    } else {
      uri = _selected.uri;
    }
    setState(() {
      _error = null;
      _future = ProtectedApiService.fetchJson(
        url: uri,
        spoofUserAgent: _spoofUa,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        foregroundColor: const Color(0xFFE8EDF2),
        title: const Text('Protected API'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Same HUMAN headers as the home screen. Use a URL on an origin protected by '
              'your Enforcer to see 403 + challenge. Free public APIs return 200 unless you proxy them.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8899AA),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Preset',
                labelStyle: TextStyle(color: Color(0xFF8899AA)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2A3A4A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4FC3F7)),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ProtectedEndpoint>(
                  value: _selected,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A2A3A),
                  items: kProtectedEndpoints
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e.label,
                            style: const TextStyle(color: Color(0xFFE8EDF2)),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selected = v);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selected.description,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8899AA)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customController,
              style: const TextStyle(
                color: Color(0xFFE8EDF2),
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                labelText: 'Custom URL (optional, overrides preset)',
                hintText: 'https://your-origin.com/api/…',
                hintStyle: TextStyle(color: Color(0xFF556677)),
                labelStyle: TextStyle(color: Color(0xFF8899AA)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2A3A4A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4FC3F7)),
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _spoofUa = !_spoofUa),
              child: Row(
                children: [
                  Checkbox(
                    value: _spoofUa,
                    onChanged: (v) => setState(() => _spoofUa = v ?? false),
                    activeColor: const Color(0xFF4FC3F7),
                    checkColor: const Color(0xFF0F1923),
                  ),
                  const Expanded(
                    child: Text(
                      'UA: PhantomJS/flutter/brian (test)',
                      style: TextStyle(fontSize: 13, color: Color(0xFFCCDDEE)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _runFetch,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('GET with HUMAN headers'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: const Color(0xFF0F1923),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF5350))),
            ],
            const SizedBox(height: 20),
            if (_future != null)
              FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SelectableText(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Color(0xFFEF5350), fontSize: 13),
                    );
                  }
                  final data = snapshot.data;
                  if (data == null) {
                    return const SizedBox.shrink();
                  }
                  final pretty = const JsonEncoder.withIndent('  ').convert(data);
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2A3A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A3A4A)),
                    ),
                    child: SelectableText(
                      pretty,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFFCCDDEE),
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
