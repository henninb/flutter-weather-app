import Foundation
import Flutter
import HUMAN
import os.log

/// Per https://docs.humansecurity.com/applications/flutter-integration
/// — start in AppDelegate, method channel `com.humansecurity/sdk`,
/// policy `automaticInterceptorPolicy.interceptorType = .none`.
///
/// **Collector / `X-PX-AUTHORIZATION: 2:…` (iOS v4):** leading `2` is a status tier; the base64 payload may
/// still decode to JSON with **h, t, u, v** (healthy token — see Flutter `HumanService` logs).
/// If Collector is unreachable, verify Safari → `https://collector-<APP_ID>.perimeterx.net/...`, Xcode
/// `NSURLErrorDomain` (-1009 / -1022 / -1200), `X-PX-HELLO`, VPN/proxy, and `HumanSecurity.start` on main before traffic.
class HumanManager {

    static let shared = HumanManager()
    /// Set from Flutter `humanConfigure` (`lib/config/human_security_app_id.dart`); must match Enforcer 403 `appId`.
    private static var appId: String = ""
    private static var didStartSdk = false

    /// Fallback URL if Flutter omits `requestUrl` (should match the blocked request).
    private static let humanChallengeResponseUrl =
        URL(string: "https://vercel.bhenning.com/api/weather")!

    private static let humanOSLog = OSLog(subsystem: "com.weather.minneapolisWeather", category: "HumanSecurity")

    private static func trace(_ message: String) {
        print("[HumanSecurity] \(message)")
        os_log("%{public}@", log: HumanManager.humanOSLog, type: .info, message as NSString)
    }

    private static func intFromFlutter(_ value: Any?) -> Int {
        if let i = value as? Int { return i }
        if let n = value as? NSNumber { return n.intValue }
        if let i = value as? Int64 { return Int(i) }
        return 403
    }

    /// Flutter map → [String: String] for `HTTPURLResponse` header fields.
    private static func headerFieldsFromFlutter(_ raw: Any?) -> [String: String] {
        guard let raw = raw else { return [:] }
        if let d = raw as? [String: String] { return d }
        if let d = raw as? [String: Any] {
            var out: [String: String] = [:]
            for (k, v) in d {
                if let s = v as? String {
                    out[k] = s
                } else if let n = v as? NSNumber {
                    out[k] = n.stringValue
                }
            }
            return out
        }
        return [:]
    }

    /// If the server omits `Content-Type`, the SDK may not treat the payload as a block. Infer from bytes.
    private static func enrichHeadersForBlock(data: Data, headerFields: [String: String]) -> [String: String] {
        var h = headerFields
        let hasCT = h.keys.contains { $0.lowercased() == "content-type" }
        if hasCT { return h }
        if data.first == UInt8(ascii: "{") {
            h["Content-Type"] = "application/json; charset=utf-8"
            HumanManager.trace("enrichHeaders: added Content-Type application/json (body starts with '{')")
        } else if data.count >= 9,
                  let head = String(data: data.prefix(9), encoding: .utf8),
                  head.lowercased().hasPrefix("<!doctype") || head.lowercased().hasPrefix("<html") {
            h["Content-Type"] = "text/html; charset=utf-8"
            HumanManager.trace("enrichHeaders: added Content-Type text/html (HTML block page)")
        }
        return h
    }

    private static func blockDiagnosticsMap(
        result: String,
        canHandle: Bool?,
        handled: Bool?,
        bodyPrefix: String?,
        hint: String?
    ) -> [String: Any] {
        var m: [String: Any] = ["result": result]
        if let canHandle = canHandle { m["canHandle"] = canHandle }
        if let handled = handled { m["handled"] = handled }
        if let bodyPrefix = bodyPrefix { m["bodyPrefix"] = bodyPrefix }
        if let hint = hint { m["hint"] = hint }
        return m
    }

    /// True after Flutter sends a real app id via `humanConfigure`.
    private static var isConfigured: Bool {
        !appId.isEmpty && appId != "<APPID>"
    }

    /// Called from the method channel on the main queue with the app id from `lib/config/human_security_app_id.dart`.
    func configureAndStart(appId: String) {
        guard !appId.isEmpty && appId != "<APPID>" else {
            HumanManager.trace("HumanSecurity.start skipped — invalid appId from Flutter")
            return
        }
        HumanManager.appId = appId
        HumanManager.trace("HUMAN_APP_ID=\(appId)")
        if HumanManager.didStartSdk {
            HumanManager.trace("humanConfigure: SDK already started, appId=\(appId)")
            return
        }
        do {
            let policy = HSPolicy()
            policy.automaticInterceptorPolicy.interceptorType = .none
            // Hybrid policy: challenge UI uses WKWebView to load PX / collector URLs; root domains for cookies + WebView setup.
            // See https://docs.humansecurity.com/applications/hybrid-app-integration
            policy.hybridAppPolicy.automaticSetup = true
            // Flutter: challenge WKWebView is not created by app native code — required for handleResponse to present UI.
            // https://docs.humansecurity.com/applications/hybrid-app-integration
            policy.hybridAppPolicy.supportExternalWebViews = true
            policy.hybridAppPolicy.set(
                webRootDomains: Set([".vercel.bhenning.com", ".perimeterx.net"]),
                forAppId: HumanManager.appId
            )
            try HumanSecurity.start(appId: HumanManager.appId, policy: policy)
            HumanManager.didStartSdk = true
            HumanSecurity.BD.delegate = BotDefenderLogger.shared
            HumanManager.trace("HUMAN_APP_ID=\(HumanManager.appId) HumanSecurity.start OK (main thread, hybrid webRootDomains, BD.delegate=logger)")
        } catch {
            HumanManager.trace("HumanSecurity.start error: \(error.localizedDescription)")
        }
    }

    func setupChannel(with controller: FlutterViewController) {
        let humanChannel = FlutterMethodChannel(
            name: "com.humansecurity/sdk",
            binaryMessenger: controller.binaryMessenger
        )
        humanChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "humanConfigure" {
                if let args = call.arguments as? [String: Any],
                   let id = args["appId"] as? String {
                    DispatchQueue.main.async {
                        HumanManager.shared.configureAndStart(appId: id)
                        result(nil)
                    }
                } else {
                    result(FlutterError(code: "bad_args", message: "humanConfigure requires appId string", details: nil))
                }
                return
            }
            guard HumanManager.isConfigured else {
                if call.method == "humanGetHeaders" {
                    HumanManager.trace("humanGetHeaders stub (SDK not configured)")
                    result(nil)
                } else if call.method == "humanHandleResponse" {
                    HumanManager.trace("humanHandleResponse stub (SDK not configured)")
                    result("false")
                } else {
                    result("")
                }
                return
            }

            if call.method == "humanGetHeaders" {
                HumanManager.trace("HUMAN_APP_ID=\(HumanManager.appId) humanGetHeaders → BD.headersForURLRequest")
                var json: String?
                do {
                    let headers = HumanSecurity.BD.headersForURLRequest(forAppId: HumanManager.appId)
                    let keys = (headers as NSDictionary).allKeys.compactMap { $0 as? String }.sorted()
                    HumanManager.trace(
                        "humanGetHeaders: \(keys.count) key(s): \(keys.joined(separator: ", "))"
                    )
                    let data = try JSONSerialization.data(withJSONObject: headers)
                    json = String(data: data, encoding: .utf8)
                } catch {
                    HumanManager.trace("humanGetHeaders error: \(error.localizedDescription)")
                }
                result(json)
            } else if call.method == "humanHandleResponse" {
                // HSBotDefender has `canHandleResponse` / `handleResponse` — both need URLResponse + Data.
                // See ios/Pods/HUMAN/.../HUMAN.swiftinterface (HSBotDefender).
                if let map = call.arguments as? [String: Any] {
                    let data: Data
                    if let b64 = map["bodyBase64"] as? String,
                       let d = Data(base64Encoded: b64) {
                        data = d
                        HumanManager.trace("humanHandleResponse: using bodyBase64 (\(d.count) bytes)")
                    } else if let bodyString = map["body"] as? String,
                              let d = bodyString.data(using: .utf8) {
                        data = d
                        HumanManager.trace("humanHandleResponse: using UTF-8 body (\(d.count) bytes)")
                    } else {
                        HumanManager.trace("humanHandleResponse: missing body / bodyBase64")
                        result("false")
                        return
                    }
                    let status = HumanManager.intFromFlutter(map["statusCode"])
                    let urlString = (map["requestUrl"] as? String) ?? ""
                    let url = URL(string: urlString) ?? HumanManager.humanChallengeResponseUrl
                    var headerFields = HumanManager.headerFieldsFromFlutter(map["headers"])
                    headerFields = HumanManager.enrichHeadersForBlock(data: data, headerFields: headerFields)
                    HumanManager.trace(
                        "humanHandleResponse: url=\(url.absoluteString) status=\(status) headerCount=\(headerFields.count)"
                    )
                    guard let httpURLResponse = HTTPURLResponse(
                        url: url,
                        statusCode: status,
                        httpVersion: nil,
                        headerFields: headerFields
                    ) else {
                        HumanManager.trace("humanHandleResponse: HTTPURLResponse init failed")
                        result(HumanManager.blockDiagnosticsMap(
                            result: "false",
                            canHandle: nil,
                            handled: nil,
                            bodyPrefix: nil,
                            hint: "HTTPURLResponse initializer failed (invalid URL or headers)"
                        ))
                        return
                    }
                    // Challenge UI must run on the main thread.
                    DispatchQueue.main.async {
                        let pxHeaders = HumanSecurity.BD.headersForURLRequest(forAppId: HumanManager.appId) as NSDictionary
                        if let auth = pxHeaders["X-PX-AUTHORIZATION"] as? String {
                            let levelPrefix = String(auth.prefix(while: { $0 != ":" }))
                            HumanManager.trace("BD pre-handle: X-PX-AUTHORIZATION level prefix=\(levelPrefix) (if 2, decode payload in Flutter for h/t/u/v — healthy token vs degraded)")
                        } else {
                            HumanManager.trace("BD pre-handle: X-PX-AUTHORIZATION absent")
                        }
                        let can = HumanSecurity.BD.canHandleResponse(response: httpURLResponse, data: data)
                        HumanManager.trace("BD.canHandleResponse → \(can)")
                        if !can {
                            let preview = String(data: data.prefix(400), encoding: .utf8) ?? "<non-UTF8>"
                            let short = String(preview.prefix(220))
                            HumanManager.trace("canHandleResponse=false body prefix: \(short)")
                            result(HumanManager.blockDiagnosticsMap(
                                result: "false",
                                canHandle: false,
                                handled: false,
                                bodyPrefix: short,
                                hint: "SDK does not recognize this 403 as a Bot Defender block. Ensure Enforcer returns PX block JSON (appId, action, vid, …) matching \(HumanManager.appId), or fix server block format."
                            ))
                            return
                        }
                        let handled = HumanSecurity.BD.handleResponse(
                            response: httpURLResponse,
                            data: data
                        ) { challengeResult in
                            let out = challengeResult == .solved ? "solved" : "cancelled"
                            HumanManager.trace("humanHandleResponse challenge callback: \(out)")
                            result(HumanManager.blockDiagnosticsMap(
                                result: out,
                                canHandle: true,
                                handled: true,
                                bodyPrefix: nil,
                                hint: nil
                            ))
                        }
                        if !handled {
                            let preview = String(data: data.prefix(500), encoding: .utf8) ?? "<non-UTF8>"
                            let short = String(preview.prefix(280))
                            HumanManager.trace("handleResponse=false body prefix: \(short)")
                            result(HumanManager.blockDiagnosticsMap(
                                result: "false",
                                canHandle: true,
                                handled: false,
                                bodyPrefix: short,
                                hint:
                                    "canHandle was true but handleResponse returned false — often: "
                                    + "(1) Flutter: ensure hybridAppPolicy.supportExternalWebViews is true (set in this app); "
                                    + "(2) X-PX-AUTHORIZATION level 2 without healthy h/t/u/v payload — Collector or degraded state; "
                                    + "(3) challenge already active. Body prefix below should match Enforcer JSON."
                            ))
                        }
                    }
                    return
                }
                // Legacy: body string only (may not show challenge on iOS).
                if let response = call.arguments as? String,
                   let data = response.data(using: .utf8),
                   let httpURLResponse = HTTPURLResponse(
                       url: HumanManager.humanChallengeResponseUrl,
                       statusCode: 403,
                       httpVersion: "HTTP/1.1",
                       headerFields: nil
                   ) {
                    HumanManager.trace("humanHandleResponse (legacy string body only)")
                    let handled = HumanSecurity.BD.handleResponse(
                        response: httpURLResponse,
                        data: data
                    ) { challengeResult in
                        let out = challengeResult == .solved ? "solved" : "cancelled"
                        HumanManager.trace("humanHandleResponse result: \(out)")
                        result(out)
                    }
                    if handled {
                        return
                    }
                }
                HumanManager.trace("humanHandleResponse → false (not handled)")
                result("false")
            } else {
                result("")
            }
        }
    }

    /// Forwards Bot Defender / collector lifecycle events to [trace]. This is the supported way to
    /// observe SDK-side activity; raw HTTPS to `*.perimeterx.net` is not exposed as an API — use
    /// Proxyman on device, or `HUMAN_CFNETWORK_LOG=1` (see AppDelegate) for low-level URLSession logs.
    private final class BotDefenderLogger: NSObject, HSBotDefenderDelegate {
        static let shared = BotDefenderLogger()

        func botDefenderDidUpdateHeaders(headers: [String: String], forAppId appId: String) {
            let keys = headers.keys.sorted().joined(separator: ", ")
            HumanManager.trace("collector SDK: BD.didUpdateHeaders appId=\(appId) keys=[\(keys)]")
            let auth = headers["X-PX-AUTHORIZATION"]
                ?? headers.first { $0.key.caseInsensitiveCompare("X-PX-AUTHORIZATION") == .orderedSame }?.value
            if let auth {
                let level = String(auth.prefix(while: { $0 != ":" }))
                HumanManager.trace(
                    "collector SDK: BD.didUpdateHeaders X-PX-AUTHORIZATION level prefix=\(level) (headers refreshed after collector work)"
                )
            }
        }

        func botDefenderRequestBlocked(url: URL?, appId: String) {
            HumanManager.trace(
                "collector SDK: BD.requestBlocked appId=\(appId) url=\(url?.absoluteString ?? "nil")"
            )
        }

        func botDefenderChallengeSolved(forAppId appId: String) {
            HumanManager.trace("collector SDK: BD.challengeSolved appId=\(appId)")
        }

        func botDefenderChallengeCancelled(forAppId appId: String) {
            HumanManager.trace("collector SDK: BD.challengeCancelled appId=\(appId)")
        }

        func botDefenderChallengeRendered(forAppId appId: String) {
            HumanManager.trace("collector SDK: BD.challengeRendered appId=\(appId)")
        }

        func botDefenderChallengeRenderFailed(forAppId appId: String) {
            HumanManager.trace("collector SDK: BD.challengeRenderFailed appId=\(appId)")
        }
    }
}
