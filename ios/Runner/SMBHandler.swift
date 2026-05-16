import Foundation
import AMSMB2

class SMBHandler {

    private var smb: SMB2Client?

    func connect(host: String, share: String, username: String, password: String) async throws {
        await smb?.disconnectShare()
        smb = nil
        guard let url = URL(string: "smb://\(host)/") else {
            throw makeError("URLが無効です: \(host)")
        }
        let credential = URLCredential(
            user: username, password: password, persistence: .forSession)
        let client = SMB2Client(url: url, credential: credential)
        try await client.connectShare(name: share)
        smb = client
    }

    func disconnect() async {
        await smb?.disconnectShare()
        smb = nil
    }

    func listFiles(path: String) async throws -> [[String: Any]] {
        guard let smb = smb else { throw makeError("接続されていません") }
        let smbPath = (path == "/" || path.isEmpty) ? "" : path
        let entries = try await smb.contentsOfDirectory(atPath: smbPath)
        return entries.compactMap { entry -> [String: Any]? in
            guard let name = entry[URLResourceKey.nameKey] as? String,
                  !name.isEmpty, !name.hasPrefix(".") else { return nil }
            let isDir  = (entry[URLResourceKey.isDirectoryKey] as? Bool) ?? false
            let size   = (entry[URLResourceKey.fileSizeKey] as? NSNumber)?.intValue ?? 0
            let millis = (entry[URLResourceKey.contentModificationDateKey] as? Date)
                .map { Int($0.timeIntervalSince1970 * 1000) } ?? 0
            return ["name": name, "isDirectory": isDir, "size": size, "modifiedDate": millis]
        }
    }

    func downloadFile(remotePath: String) async throws -> String {
        guard let smb = smb else { throw makeError("接続されていません") }
        let fileName = URL(fileURLWithPath: remotePath).lastPathComponent
        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: localURL)
        try await smb.downloadItem(atPath: remotePath, to: localURL)
        return localURL.path
    }

    private func makeError(_ msg: String) -> NSError {
        NSError(domain: "SMBHandler", code: -1,
                userInfo: [NSLocalizedDescriptionKey: msg])
    }
}
