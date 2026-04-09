/// Optional `User-Agent` for [ProtectedApiService] (your API GETs only).
///
/// - **Empty** (`''`): no override — `package:http` uses its default UA, unless the UI
///   **“PhantomJS/flutter/brian”** test toggle is on (that still sets a bot-like UA for tests).
/// - **Non-empty**: always sent as `User-Agent` (toggle is ignored when this is set).
///
/// Does **not** change the HUMAN SDK’s internal collector or WKWebView traffic.
const String kOptionalUserAgentOverride = '';
