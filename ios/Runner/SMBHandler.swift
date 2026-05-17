import Foundation

// NOTE: AMSMB2の型名確認中。ビルドを通すための一時スタブ。
class SMBHandler {

    private var _client: AnyObject?

    func connect(host: String, share: String, username: String, password: String) async throws {
        throw NSError(domain: "SMBHandler", code: 0,
                      userInfo: [NSLocalizedDescriptionKey: "実装待ち"])
    }

    func disconnect() async {
        _client = nil
    }

    func listFiles(path: String) async throws -> [[String: Any]] {
        return []
    }

    func downloadFile(remotePath: String) async throws -> String {
        return ""
    }
}
