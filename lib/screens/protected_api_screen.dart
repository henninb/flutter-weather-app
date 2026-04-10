import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/protected_endpoints.dart';
import '../services/human_service.dart';
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
  String? _publicIp;
  Object? _publicIpError;
  String? _lastReportedIpFromJson;
  String? _pxHello;
  bool _pxHelloLoading = true;
  String? _customParam1Value;
  bool _customParam1Loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomParam1();
    _loadPxHello();
    ProtectedApiService.fetchPublicIp().then((ip) {
      if (mounted) {
        setState(() {
          _publicIp = ip;
          _publicIpError = null;
        });
      }
    }).catchError((Object e) {
      if (mounted) {
        setState(() {
          _publicIp = null;
          _publicIpError = e;
        });
      }
    });
  }

  Future<void> _loadCustomParam1() async {
    final v = await HumanService.getAppLabelForCustomParam1();
    if (!mounted) {
      return;
    }
    setState(() {
      _customParam1Loading = false;
      _customParam1Value = v.isEmpty ? null : v;
    });
  }

  Future<void> _loadPxHello() async {
    final headers = await HumanService.getHeaders();
    if (!mounted) {
      return;
    }
    setState(() {
      _pxHelloLoading = false;
      _pxHello = HumanService.pxHelloValue(headers);
    });
  }

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
      ).then((data) async {
        if (mounted) {
          setState(() {
            _lastReportedIpFromJson = ProtectedApiService.reportedClientIpFromJson(data);
          });
          await _loadPxHello();
          await _loadCustomParam1();
        }
        return data;
      });
    });
  }

  String _clientIpDisplayValue() {
    if (_lastReportedIpFromJson != null) {
      return _lastReportedIpFromJson!;
    }
    if (_publicIp != null) {
      return _publicIp!;
    }
    if (_publicIpError != null) {
      return '—';
    }
    return '…';
  }

  String? _clientIpCaption() {
    if (_lastReportedIpFromJson != null) {
      if (_publicIp != null && _publicIp != _lastReportedIpFromJson) {
        return 'From last API JSON; ipify egress (separate request) is $_publicIp';
      }
      return 'From last successful API JSON (clientIp / x-forwarded-for / similar)';
    }
    if (_publicIp != null) {
      return 'api.ipify.org only — not the address HUMAN collector traffic uses; '
          'those are different HTTPS paths and may differ on cellular/CGNAT.';
    }
    if (_publicIpError != null) {
      return 'ipify lookup failed';
    }
    return 'Loading ipify…';
  }

  /// Avoid implying ipify matches the HUMAN dashboard “collector” client IP.
  String _clientIpLabel() {
    if (_lastReportedIpFromJson != null) {
      return 'Client IP (API JSON)';
    }
    return 'Public IP (ipify)';
  }

  String _pxHelloDisplay() {
    if (_pxHelloLoading) {
      return '…';
    }
    final v = _pxHello;
    if (v == null || v.isEmpty) {
      return '—';
    }
    return v;
  }

  Widget _buildContextRow({
    required String label,
    required String value,
    String? caption,
  }) {
    return Column(
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
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE8EDF2),
          ),
        ),
        if (caption != null && caption.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8899AA),
              height: 1.3,
            ),
          ),
        ],
      ],
    );
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3A4A)),
              ),
              child: _buildContextRow(
                label: 'custom_param1',
                value: _customParam1Loading
                    ? '…'
                    : (_customParam1Value ?? '—'),
                caption: _customParam1Loading
                    ? 'Loading…'
                    : 'Hard-coded in lib/config/human_custom_param1.dart; passed to BD.setCustomParameters.',
              ),
            ),
            const SizedBox(height: 16),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3A4A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContextRow(
                    label: 'App ID (HUMAN)',
                    value: kHumanSecurityAppId,
                  ),
                  const SizedBox(height: 10),
                  _buildContextRow(
                    label: _clientIpLabel(),
                    value: _clientIpDisplayValue(),
                    caption: _clientIpCaption(),
                  ),
                  const SizedBox(height: 10),
                  _buildContextRow(
                    label: 'X-PX-HELLO',
                    value: _pxHelloDisplay(),
                    caption: _pxHelloLoading
                        ? 'Loading from humanGetHeaders…'
                        : (_pxHello == null || _pxHello!.isEmpty)
                            ? 'Not present in SDK headers (v3+ may send connection/pinning detail here).'
                            : 'From HumanService.getHeaders(); refreshed after GET.',
                  ),
                ],
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
