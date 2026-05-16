import 'package:flutter/material.dart';
import 'smb_service.dart';
import 'screens/connect_screen.dart';

void main() {
  runApp(const SmbViewerApp());
}

class SmbViewerApp extends StatelessWidget {
  const SmbViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // SmbServiceをシングルトンとして保持し、画面間で共有する
    final smbService = SmbService();

    return MaterialApp(
      title: 'SMB Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF)),
        fontFamily: '.SF Pro Text', // iOSシステムフォント
      ),
      home: ConnectScreen(smbService: smbService),
    );
  }
}
