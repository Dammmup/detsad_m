import Flutter
import UIKit
import GoogleMaps
@main
 @UIApplicationMain
    @objc class AppDelegate: FlutterAppDelegate {
      override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
      ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyBjbrMYTTwWMSD8LtW9hPyRnQr300EA0oE") // <-- Добавьте эту строку
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }
    }