/// Named backends you can call with HUMAN Bot Defender headers.
///
/// **Enforcer:** Only URLs on origins where you deploy PerimeterX / HUMAN Enforcer will return
/// real 403 challenges. The **sample JSON** preset hits a stable public API (200 + JSON) so you
/// can verify the client flow; replace its URL with your own Enforcer-backed route to test blocking.
class ProtectedEndpoint {
  const ProtectedEndpoint({
    required this.id,
    required this.label,
    required this.url,
    this.description = '',
  });

  final String id;
  final String label;

  /// Full HTTPS URL for `GET` (must match [hybrid web root](https://docs.humansecurity.com/applications/hybrid-app-integration) config on iOS/Android).
  final String url;
  final String description;

  Uri get uri => Uri.parse(url);
}

/// Default home screen (weather JSON shape).
const String kWeatherEndpointId = 'weather';

const List<ProtectedEndpoint> kProtectedEndpoints = [
  ProtectedEndpoint(
    id: kWeatherEndpointId,
    label: 'Weather (HUMAN demo)',
    url: 'https://vercel.bhenning.com/api/weather',
    description: 'Your Enforcer-backed station observation JSON.',
  ),
  ProtectedEndpoint(
    id: 'sampleJson',
    label: 'Sample post (JSONPlaceholder)',
    url: 'https://jsonplaceholder.typicode.com/posts/1',
    description:
        'Stable fake REST API (no key). Not blocked by PX unless you proxy through your Enforcer.',
  ),
];

ProtectedEndpoint protectedEndpointById(String id) =>
    kProtectedEndpoints.firstWhere((e) => e.id == id);
