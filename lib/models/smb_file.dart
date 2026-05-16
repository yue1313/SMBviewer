class SmbFile {
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime? modifiedDate;

  const SmbFile({
    required this.name,
    required this.isDirectory,
    required this.size,
    this.modifiedDate,
  });

  factory SmbFile.fromMap(Map<dynamic, dynamic> map) {
    return SmbFile(
      name: map['name'] as String,
      isDirectory: map['isDirectory'] as bool,
      size: (map['size'] as int?) ?? 0,
      modifiedDate: map['modifiedDate'] != null && (map['modifiedDate'] as int) > 0
          ? DateTime.fromMillisecondsSinceEpoch(map['modifiedDate'] as int)
          : null,
    );
  }

  /// ファイルサイズを人間が読みやすい文字列に変換
  String get formattedSize {
    if (isDirectory) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(size / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  /// ファイル拡張子を取得
  String get extension {
    if (isDirectory) return '';
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// ファイル種別に応じたアイコン文字列（SF Symbols名）
  String get iconName {
    if (isDirectory) return 'folder.fill';
    switch (extension) {
      case 'pdf': return 'doc.fill';
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'heic':
        return 'photo.fill';
      case 'mp4': case 'mov': case 'avi': case 'mkv':
        return 'film.fill';
      case 'mp3': case 'aac': case 'flac': case 'm4a':
        return 'music.note';
      case 'txt': case 'md': return 'doc.text.fill';
      case 'zip': case 'rar': case '7z': return 'archivebox.fill';
      default: return 'doc.fill';
    }
  }
}
