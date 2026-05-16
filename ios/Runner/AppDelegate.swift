import UIKit
import Flutter

@main
class AppDelegate: FlutterAppDelegate {

    private let smbHandler = SMBHandler()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.yourapp/smb",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {

            case "connect":
                guard
                    let args = call.arguments as? [String: Any],
                    let host = args["host"] as? String,
                    let share = args["share"] as? String
                else {
                    result(FlutterError(code: "INVALID_ARGS", message: "引数が不正です", details: nil))
                    return
                }
                let username = args["username"] as? String ?? "guest"
                let password = args["password"] as? String ?? ""
                self.smbHandler.connect(host: host, share: share, username: username, password: password) { error in
                    if let error = error {
                        result(FlutterError(code: "CONNECT_FAILED", message: error.localizedDescription, details: nil))
                    } else {
                        result(nil)
                    }
                }

            case "disconnect":
                self.smbHandler.disconnect { result(nil) }

            case "listFiles":
                guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "pathが必要です", details: nil))
                    return
                }
                self.smbHandler.listFiles(path: path) { files, error in
                    if let error = error {
                        result(FlutterError(code: "LIST_FAILED", message: error.localizedDescription, details: nil))
                    } else {
                        result(files ?? [])
                    }
                }

            case "downloadFile":
                guard let args = call.arguments as? [String: Any], let remotePath = args["remotePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "remotePathが必要です", details: nil))
                    return
                }
                self.smbHandler.downloadFile(remotePath: remotePath) { localPath, error in
                    if let error = error {
                        result(FlutterError(code: "DOWNLOAD_FAILED", message: error.localizedDescription, details: nil))
                    } else {
                        result(localPath)
                    }
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
