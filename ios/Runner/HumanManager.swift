import Foundation
import Flutter
import HUMAN

class HumanManager {

    static let shared = HumanManager()
    private static let appId = "<APPID>"

    func start() {
        do {
            let policy = HSPolicy()
            policy.automaticInterceptorPolicy.interceptorType = .none
            try HumanSecurity.start(appId: HumanManager.appId, policy: policy)
        } catch {
            print("HumanSecurity start error: \(error)")
        }
    }

    func setupChannel(with controller: FlutterViewController) {
        let humanChannel = FlutterMethodChannel(
            name: "com.humansecurity/sdk",
            binaryMessenger: controller.binaryMessenger
        )
        humanChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "humanGetHeaders" {
                var json: String?
                do {
                    let headers = HumanSecurity.BD.headersForURLRequest(forAppId: HumanManager.appId)
                    let data = try JSONSerialization.data(withJSONObject: headers)
                    json = String(data: data, encoding: .utf8)
                } catch {
                    print("HumanSecurity headers error: \(error)")
                }
                result(json)
            } else if call.method == "humanHandleResponse" {
                let body: String?
                let requestUrl: URL?
                if let args = call.arguments as? [String: Any] {
                    body = args["body"] as? String
                    if let urlString = args["requestUrl"] as? String {
                        requestUrl = URL(string: urlString)
                    } else {
                        requestUrl = nil
                    }
                } else if let legacy = call.arguments as? String {
                    body = legacy
                    requestUrl = nil
                } else {
                    body = nil
                    requestUrl = nil
                }
                if let response = body,
                   let data = response.data(using: .utf8),
                   let url = requestUrl ?? URL(string: "about:blank"),
                   let httpURLResponse = HTTPURLResponse(
                       url: url,
                       statusCode: 403,
                       httpVersion: nil,
                       headerFields: nil
                   ) {
                    let handled = HumanSecurity.BD.handleResponse(
                        response: httpURLResponse,
                        data: data
                    ) { challengeResult in
                        result(challengeResult == .solved ? "solved" : "cancelled")
                    }
                    if handled {
                        return
                    }
                }
                result("false")
            } else {
                result("")
            }
        }
    }
}
