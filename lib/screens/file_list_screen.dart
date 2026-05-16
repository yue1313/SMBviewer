import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../smb_service.dart';
import '../models/smb_file.dart';

class FileListScreen extends StatefulWidget {
  final SmbService smbService;
  final String path;
  final String title;

  const FileListScreen({
    super.key,
    required this.smbService,
    required this.path,
    required this.title,
  });

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  List<SmbFile> _files = [];
  bool _isLoading = true;
  String? _error;

  // ダウンロード中のファイル名セット
  final Set<String> _downloading = {};

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final files = await widget.smbService.listFiles(widget.path);
      if (mounted) setState(() => _files = files);
    } on SmbException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openFolder(SmbFile folder) {
    final newPath = widget.path == '/'
        ? '/${folder.name}'
        : '${widget.path}/${folder.name}';
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FileListScreen(
        smbService: widget.smbService,
        path: newPath,
        title: folder.name,
      ),
    ));
  }

  Future<void> _openFile(SmbFile file) async {
    if (_downloading.contains(file.name)) return;

    setState(() => _downloading.add(file.name));

    try {
      final remotePath = widget.path == '/'
          ? '/${file.name}'
          : '${widget.path}/${file.name}';

      final localPath = await widget.smbService.downloadFile(remotePath);

      if (!mounted) return;

      // iOSのシステムビューアで開く
      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('開けませんでした: ${result.message}')),
        );
      }
    } on SmbException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading.remove(file.name));
    }
  }

  Future<void> _disconnect() async {
    await widget.smbService.disconnect();
    if (mounted) {
      // すべての画面をポップしてトップへ戻る
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFF2F2F7),
        surfaceTintColor: Colors.transparent,
        actions: [
          // ルートパスの場合のみ切断ボタンを表示
          if (widget.path == '/')
            TextButton(
              onPressed: _disconnect,
              child: const Text('切断', style: TextStyle(color: Colors.red)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadFiles, child: const Text('再試行')),
            ],
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: Color(0xFFC7C7CC)),
            SizedBox(height: 12),
            Text('ファイルがありません',
                style: TextStyle(color: Color(0xFF8E8E93))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        // フォルダとファイルの間にセクションヘッダーを挿入
        final file = _files[index];
        final prevFile = index > 0 ? _files[index - 1] : null;
        final showHeader = prevFile != null &&
            prevFile.isDirectory &&
            !file.isDirectory;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0 && file.isDirectory)
              _sectionHeader('フォルダ'),
            if (showHeader) ...[
              const SizedBox(height: 16),
              _sectionHeader('ファイル'),
            ],
            _FileRow(
              file: file,
              isDownloading: _downloading.contains(file.name),
              onTap: () =>
                  file.isDirectory ? _openFolder(file) : _openFile(file),
            ),
            if (index < _files.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Divider(height: 1, color: Color(0xFFE5E5EA)),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6C6C70),
        ),
      ),
    );
  }
}

// ─── ファイル行ウィジェット ─────────────────────────────

class _FileRow extends StatelessWidget {
  final SmbFile file;
  final bool isDownloading;
  final VoidCallback onTap;

  const _FileRow({
    required this.file,
    required this.isDownloading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDownloading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // アイコン
              _FileIcon(file: file),
              const SizedBox(width: 12),

              // ファイル名・サイズ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!file.isDirectory && file.size > 0)
                      Text(
                        file.formattedSize,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                  ],
                ),
              ),

              // ダウンロード中インジケーター or 矢印
              if (isDownloading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (file.isDirectory)
                const Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFFC7C7CC))
              else
                const Icon(Icons.arrow_circle_down_outlined,
                    size: 20, color: Color(0xFF007AFF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  final SmbFile file;
  const _FileIcon({required this.file});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolveIcon(file);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  (IconData, Color) _resolveIcon(SmbFile file) {
    if (file.isDirectory) return (Icons.folder, const Color(0xFFFFCC00));
    switch (file.extension) {
      case 'pdf': return (Icons.picture_as_pdf, Colors.red);
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'heic':
        return (Icons.image, Colors.green);
      case 'mp4': case 'mov': case 'avi': case 'mkv':
        return (Icons.video_file, Colors.purple);
      case 'mp3': case 'aac': case 'flac': case 'm4a':
        return (Icons.audio_file, Colors.orange);
      case 'txt': case 'md':
        return (Icons.description, Colors.blue);
      case 'zip': case 'rar': case '7z':
        return (Icons.archive, Colors.brown);
      default:
        return (Icons.insert_drive_file, const Color(0xFF8E8E93));
    }
  }
}
