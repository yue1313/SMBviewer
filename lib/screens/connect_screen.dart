import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../smb_service.dart';
import 'file_list_screen.dart';

class ConnectScreen extends StatefulWidget {
  final SmbService smbService;
  const ConnectScreen({super.key, required this.smbService});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _hostController = TextEditingController();
  final _shareController = TextEditingController();
  final _userController = TextEditingController(text: 'guest');
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isConnecting = false;
  bool _obscurePassword = true;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('connection_history') ?? [];
    });
  }

  Future<void> _saveHistory(String host, String share) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = '$host/$share';
    _history.remove(entry);
    _history.insert(0, entry);
    if (_history.length > 5) _history = _history.take(5).toList();
    await prefs.setStringList('connection_history', _history);
    setState(() {});
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isConnecting = true);

    try {
      await widget.smbService.connect(
        host: _hostController.text.trim(),
        share: _shareController.text.trim(),
        username: _userController.text.trim(),
        password: _passController.text,
      );
      await _saveHistory(
        _hostController.text.trim(),
        _shareController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FileListScreen(
          smbService: widget.smbService,
          path: '/',
          title: _shareController.text.trim(),
        ),
      ));
    } on SmbException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _fillFromHistory(String entry) {
    final parts = entry.split('/');
    if (parts.length >= 2) {
      _hostController.text = parts[0];
      _shareController.text = parts.sublist(1).join('/');
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _shareController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('SMB Viewer'),
        backgroundColor: const Color(0xFFF2F2F7),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 接続フォームカード
              _Card(
                child: Column(
                  children: [
                    _Field(
                      controller: _hostController,
                      label: 'ホスト / IPアドレス',
                      hint: '192.168.1.10',
                      icon: Icons.computer,
                      keyboardType: TextInputType.url,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? '必須項目です' : null,
                    ),
                    const _Divider(),
                    _Field(
                      controller: _shareController,
                      label: '共有フォルダ名',
                      hint: 'Documents',
                      icon: Icons.folder_outlined,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? '必須項目です' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  children: [
                    _Field(
                      controller: _userController,
                      label: 'ユーザー名',
                      hint: 'guest',
                      icon: Icons.person_outline,
                    ),
                    const _Divider(),
                    _Field(
                      controller: _passController,
                      label: 'パスワード',
                      hint: '（省略可）',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 接続ボタン
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isConnecting ? null : _connect,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('接続',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),

              // 接続履歴
              if (_history.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text(
                  '最近の接続',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C6C70),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _Card(
                  child: Column(
                    children: _history.asMap().entries.map((e) {
                      final isLast = e.key == _history.length - 1;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () => _fillFromHistory(e.value),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.history,
                                      size: 18, color: Color(0xFF8E8E93)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      size: 18, color: Color(0xFFC7C7CC)),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast) const _Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 共通ウィジェット ───────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 48, color: Color(0xFFE5E5EA));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF8E8E93)),
        suffixIcon: suffixIcon,
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
