import Foundation
import AMSMB2

class SMBHandler {

    private var client: SMB2Client?

    func connect(host: String, share: String, username: String, password: String) async throws {
        await client?.disconnectShare()
        client = nil
        guard let url = URL(string: "smb://\(host)/") else {
            throw makeError("URLが無効です: \(host)")
        }
        let credential = URLCredential(
            user: username, password: password, persistence: .forSession)
        let c = SMB2Client(url: url, credential: credential)
        try await c.connectShare(name: share)
        client = c
    }

    func disconnect() async {
        await client?.disconnectShare()
        client = nil
    }

    func listFiles(path: String) async throws -> [[String: Any]] {
        guard let client = client else { throw makeError("接続されていません") }
        let smbPath = (path == "/" || path.isEmpty) ? "" : path
        let entries = try await client.contentsOfDirectory(atPath: smbPath)
        return entries.compactMap { entry -> [String: Any]? in
            guard let name = entry[.nameKey] as? String,
                  !name.isEmpty, !name.hasPrefix(".") else { return nil }
            let isDir   = (entry[.isDirectoryKey] as? Bool) ?? false
            let size    = (entry[.fileSizeKey] as? NSNumber)?.intValue ?? 0
            let millis  = (entry[.contentModificationDateKey] as? Date)
                .map { Int($0.timeIntervalSince1970 * 1000) } ?? 0
            return [
                "name":         name,
                "isDirectory":  isDir,
                "size":         size,
                "modifiedDate": millis,
            ]
        }
    }

    func downloadFile(remotePath: String) async throws -> String {
        guard let client = client else { throw makeError("接続されていません") }
        let fileName = URL(fileURLWithPath: remotePath).lastPathComponent
        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: localURL)
        try await client.downloadItem(atPath: remotePath, to: localURL)
        return localURL.path
    }

    private func makeError(_ msg: String) -> NSError {
        NSError(domain: "SMBHandler", code: -1,
                userInfo: [NSLocalizedDescriptionKey: msg])
    }
}
