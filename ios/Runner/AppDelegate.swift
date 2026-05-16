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
                guard let args = call.arguments as? [String: Any],
                      let host  = args["host"]  as? String,
                      let share = args["share"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "引数が不正です", details: nil))
                    return
                }
                let user = args["username"] as? String ?? "guest"
                let pass = args["password"] as? String ?? ""
                Task {
                    do {
                        try await self.smbHandler.connect(
                            host: host, share: share, username: user, password: pass)
                        result(nil)
                    } catch {
                        result(FlutterError(code: "CONNECT_FAILED",
                                            message: error.localizedDescription, details: nil))
                    }
                }

            case "disconnect":
                Task {
                    await self.smbHandler.disconnect()
                    result(nil)
                }

            case "listFiles":
                guard let args = call.arguments as? [String: Any],
                      let path = args["path"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "pathが必要です", details: nil))
                    return
                }
                Task {
                    do {
                        let files = try await self.smbHandler.listFiles(path: path)
                        result(files)
                    } catch {
                        result(FlutterError(code: "LIST_FAILED",
                                            message: error.localizedDescription, details: nil))
                    }
                }

            case "downloadFile":
                guard let args = call.arguments as? [String: Any],
                      let remotePath = args["remotePath"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "remotePathが必要です", details: nil))
                    return
                }
                Task {
                    do {
                        let path = try await self.smbHandler.downloadFile(remotePath: remotePath)
                        result(path)
                    } catch {
                        result(FlutterError(code: "DOWNLOAD_FAILED",
                                            message: error.localizedDescription, details: nil))
                    }
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
