import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../home/screens/home_screen.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regPassConfirmCtrl = TextEditingController();

  bool _loginPassVisible = false;
  bool _regPassVisible = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() { if (mounted) setState(() => _error = null); });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regPassConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 입력해주세요');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.signInWithEmail(email, pass);
      if (!mounted) return;
      if (user == null) {
        setState(() => _error = '이메일 또는 비밀번호가 올바르지 않아요');
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) {
      if (mounted) setState(() => _error = '로그인 중 오류가 발생했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doRegister() async {
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final pass = _regPassCtrl.text;
    final confirm = _regPassConfirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = '모든 항목을 입력해주세요');
      return;
    }
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
      setState(() => _error = '올바른 이메일 형식이 아니에요');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = '비밀번호는 6자 이상이어야 해요');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = '비밀번호가 일치하지 않아요');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final exists = await AuthService.emailExists(email);
      if (!mounted) return;
      if (exists) {
        setState(() => _error = '이미 가입된 이메일이에요. 로그인 탭을 이용해주세요.');
        return;
      }
      await AuthService.registerWithEmail(name: name, email: email, password: pass);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) {
      if (mounted) setState(() => _error = '회원가입 중 오류가 발생했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          tabs: const [Tab(text: '로그인'), Tab(text: '회원가입')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _LoginTab(
            emailCtrl: _loginEmailCtrl,
            passCtrl: _loginPassCtrl,
            passVisible: _loginPassVisible,
            onTogglePass: () => setState(() => _loginPassVisible = !_loginPassVisible),
            error: _error,
            loading: _loading,
            onSubmit: _doLogin,
          ),
          _RegisterTab(
            nameCtrl: _regNameCtrl,
            emailCtrl: _regEmailCtrl,
            passCtrl: _regPassCtrl,
            passConfirmCtrl: _regPassConfirmCtrl,
            passVisible: _regPassVisible,
            onTogglePass: () => setState(() => _regPassVisible = !_regPassVisible),
            error: _error,
            loading: _loading,
            onSubmit: _doRegister,
          ),
        ],
      ),
    );
  }
}

class _LoginTab extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool passVisible;
  final VoidCallback onTogglePass;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  const _LoginTab({
    required this.emailCtrl, required this.passCtrl,
    required this.passVisible, required this.onTogglePass,
    required this.error, required this.loading, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('다시 돌아오셨군요!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('이메일과 비밀번호를 입력해주세요',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          _Field(ctrl: emailCtrl, label: '이메일', hint: 'hello@email.com',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _Field(
            ctrl: passCtrl, label: '비밀번호', hint: '••••••••',
            obscure: !passVisible,
            suffix: IconButton(
              icon: Icon(passVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: AppTheme.textSecondary),
              onPressed: onTogglePass,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: error!),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterTab extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController passConfirmCtrl;
  final bool passVisible;
  final VoidCallback onTogglePass;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  const _RegisterTab({
    required this.nameCtrl, required this.emailCtrl,
    required this.passCtrl, required this.passConfirmCtrl,
    required this.passVisible, required this.onTogglePass,
    required this.error, required this.loading, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('핀스팟에 오신 것을 환영해요!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('계정을 만들고 지도를 채워보세요',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          _Field(ctrl: nameCtrl, label: '닉네임', hint: '핀스팟 탐험가'),
          const SizedBox(height: 14),
          _Field(ctrl: emailCtrl, label: '이메일', hint: 'hello@email.com',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _Field(
            ctrl: passCtrl, label: '비밀번호', hint: '6자 이상',
            obscure: !passVisible,
            suffix: IconButton(
              icon: Icon(passVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: AppTheme.textSecondary),
              onPressed: onTogglePass,
            ),
          ),
          const SizedBox(height: 14),
          _Field(ctrl: passConfirmCtrl, label: '비밀번호 확인', hint: '동일하게 입력해주세요',
              obscure: !passVisible),
          if (error != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: error!),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('회원가입', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '가입 시 서비스 이용약관 및 개인정보 처리방침에 동의합니다',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _Field({
    required this.ctrl, required this.label, required this.hint,
    this.obscure = false, this.keyboardType, this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            filled: true,
            fillColor: AppTheme.background,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
