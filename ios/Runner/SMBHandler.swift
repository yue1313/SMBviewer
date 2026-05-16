import Foundation
import AMSMB2

/// AMSMB2 を操作する Swift ハンドラ
/// AppDelegate の MethodChannel コールバックから呼ばれる
class SMBHandler {

    private var client: SMB2Client?

    // MARK: - 接続

    func connect(
        host: String,
        share: String,
        username: String,
        password: String,
        completion: @escaping (Error?) -> Void
    ) {
        // 既存の接続を先に切断する
        client?.disconnectShare { _ in }
        client = nil

        guard let url = URL(string: "smb://\(host)/\(share)") else {
            completion(smbError("URLが無効です: smb://\(host)/\(share)"))
            return
        }

        let credential = URLCredential(
            user: username,
            password: password,
            persistence: .forSession
        )

        let newClient = SMB2Client(url: url, credential: credential)

        newClient.connectShare(name: share) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error)
                    return
                }
                self?.client = newClient
                completion(nil)
            }
        }
    }

    // MARK: - 切断

    func disconnect(completion: @escaping () -> Void) {
        guard let c = client else {
            completion()
            return
        }
        c.disconnectShare { _ in
            DispatchQueue.main.async {
                self.client = nil
                completion()
            }
        }
    }

    // MARK: - ファイル一覧

    func listFiles(
        path: String,
        completion: @escaping ([[String: Any]]?, Error?) -> Void
    ) {
        guard let client = client else {
            completion(nil, smbError("SMBサーバーに接続されていません"))
            return
        }

        // AMSMB2 は空文字列をルートとして扱う
        let smbPath = path == "/" ? "" : path

        client.contentsOfDirectory(atPath: smbPath) { files, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }

                let result: [[String: Any]] = (files ?? []).compactMap { entry in
                    guard let name = entry.fileName else { return nil }
                    // 隠しファイルとシステムエントリを除外
                    guard !name.hasPrefix("."),
                          name != "." && name != ".." else { return nil }

                    let isDir = entry.isDirectory
                    let size = Int(entry.fileSize ?? 0)
                    let modified = entry.contentModificationDate
                        .map { Int($0.timeIntervalSince1970 * 1000) } ?? 0

                    return [
                        "name":         name,
                        "isDirectory":  isDir,
                        "size":         size,
                        "modifiedDate": modified,
                    ]
                }
                completion(result, nil)
            }
        }
    }

    // MARK: - ファイルダウンロード

    func downloadFile(
        remotePath: String,
        completion: @escaping (String?, Error?) -> Void
    ) {
        guard let client = client else {
            completion(nil, smbError("SMBサーバーに接続されていません"))
            return
        }

        let fileName = URL(fileURLWithPath: remotePath).lastPathComponent
        let localURL  = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        // 既存ファイルがあれば削除してから保存
        try? FileManager.default.removeItem(at: localURL)

        client.downloadItem(atPath: remotePath, to: localURL) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                completion(localURL.path, nil)
            }
        }
    }

    // MARK: - Private

    private func smbError(_ message: String) -> Error {
        NSError(
            domain: "SMBHandler",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
