import 'package:flutter/services.dart';
import 'models/smb_file.dart';

/// Flutter側のSMBサービス
/// MethodChannel経由でiOS（AMSMB2）と通信する
class SmbService {
  static const _channel = MethodChannel('com.yourapp/smb');

  // 現在の接続情報（UI表示用）
  String? currentHost;
  String? currentShare;

  // ─────────────────────────────────────────
  // 接続・切断
  // ─────────────────────────────────────────

  /// SMBサーバーに接続する
  Future<void> connect({
    required String host,
    required String share,
    String username = 'guest',
    String password = '',
  }) async {
    try {
      await _channel.invokeMethod('connect', {
        'host': host,
        'share': share,
        'username': username,
        'password': password,
      });
      currentHost = host;
      currentShare = share;
    } on PlatformException catch (e) {
      throw SmbException(e.message ?? '接続に失敗しました');
    }
  }

  /// 接続を切断する
  Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
    currentHost = null;
    currentShare = null;
  }

  // ─────────────────────────────────────────
  // ファイル操作
  // ─────────────────────────────────────────

  /// 指定パスのファイル・フォルダ一覧を取得する
  Future<List<SmbFile>> listFiles(String path) async {
    try {
      final result = await _channel.invokeListMethod<Map>('listFiles', {
        'path': path,
      });
      final files = result?.map((m) => SmbFile.fromMap(m)).toList() ?? [];
      // フォルダを先に、ファイルを後に並べる
      files.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return files;
    } on PlatformException catch (e) {
      throw SmbException(e.message ?? 'ファイル一覧の取得に失敗しました');
    }
  }

  /// ファイルをダウンロードしてローカルパスを返す
  Future<String> downloadFile(String remotePath) async {
    try {
      final localPath = await _channel.invokeMethod<String>(
        'downloadFile',
        {'remotePath': remotePath},
      );
      return localPath!;
    } on PlatformException catch (e) {
      throw SmbException(e.message ?? 'ダウンロードに失敗しました');
    }
  }
}

/// SMB操作のエラークラス
class SmbException implements Exception {
  final String message;
  const SmbException(this.message);

  @override
  String toString() => message;
}
