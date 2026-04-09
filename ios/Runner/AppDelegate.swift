import Darwin
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    // Xcode scheme → Run → Arguments → Environment: HUMAN_CFNETWORK_LOG=1
    // Verbose CFNetwork / URLSession logs (includes SDK collector traffic) in Xcode console.
    if ProcessInfo.processInfo.environment["HUMAN_CFNETWORK_LOG"] == "1" {
      setenv("CFNETWORK_DIAGNOSTICS", "3", 1)
    }
    #endif

    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    HumanManager.shared.setupChannel(with: controller)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
