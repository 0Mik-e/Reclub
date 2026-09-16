import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _signUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController(text: 'demo@reclub.id');
  final _password = TextEditingController(text: 'reclub123');
  String _level = 'Intermediate';
  String _city = 'Jakarta';
  String _sport = 'Pickleball';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = _signUp
        ? await appState.signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            level: _level,
            userCity: _city,
            userSport: _sport,
          )
        : await appState.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  Widget _divider() => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.hairline, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('atau', style: T.small),
          ),
          const Expanded(child: Divider(color: AppColors.hairline, thickness: 1)),
        ],
      );

  Widget _socialButton({
    required Widget leading,
    required String label,
    required VoidCallback onTap,
    Color bg = Colors.white,
    bool border = true,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: R.pill,
          border: border ? Border.all(color: AppColors.hairline, width: 1.4) : null,
          boxShadow: border ? Shadows.soft : null,
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                leading,
                const SizedBox(width: 11),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runAuth(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  Future<void> _google() async {
    final picked = await showAppSheet<GoogleAccount>(
      context,
      title: 'Pilih akun',
      subtitle: 'untuk melanjutkan ke reclub',
      child: const _GoogleAccountSheet(),
    );
    if (picked == null) return;
    await _runAuth(() => appState.signInWithGoogle(name: picked.name, email: picked.email));
  }

  Future<void> _guest() => _runAuth(appState.continueAsGuest);

  void _switchMode(bool signUp) {
    setState(() {
      _signUp = signUp;
      _error = null;
      if (signUp) {
        _name.clear();
        _email.clear();
        _password.clear();
      } else {
        _email.text = 'demo@reclub.id';
        _password.text = 'reclub123';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Row(
                children: [
                  const ReclubWordmark(size: 34),
                ],
              ),
              const SizedBox(height: 28),
              Text(_signUp ? 'Buat akun baru' : 'Selamat datang\nkembali 👋', style: T.display),
              const SizedBox(height: 10),
              Text(
                _signUp
                    ? 'Sekali daftar, semua klub, meet, dan skormu tersimpan di perangkat ini.'
                    : 'Masuk untuk melanjutkan ke klub dan jadwal mainmu.',
                style: T.body,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.chip, borderRadius: R.pill),
                child: Row(
                  children: [
                    Expanded(child: _modeTab('Masuk', !_signUp, () => _switchMode(false))),
                    Expanded(child: _modeTab('Daftar', _signUp, () => _switchMode(true))),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (_signUp) ...[
                AppField(controller: _name, label: 'Nama lengkap', hint: 'Mis. Andi Pratama', icon: Icons.person_outline_rounded),
                const SizedBox(height: 14),
              ],
              AppField(
                controller: _email,
                label: 'Email',
                hint: 'nama@email.com',
                icon: Icons.alternate_email_rounded,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AppField(
                controller: _password,
                label: 'Password',
                hint: 'Minimal 6 karakter',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 19, color: AppColors.muted),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              if (_signUp) ...[
                const SizedBox(height: 18),
                Text('Level bermain', style: T.caps.copyWith(color: AppColors.ink70)),
                const SizedBox(height: 9),
                ChoiceRow<String>(
                  options: AppState.levels,
                  value: _level,
                  labelOf: (v) => v,
                  onChanged: (v) => setState(() => _level = v),
                ),
                const SizedBox(height: 18),
                Text('Olahraga utama', style: T.caps.copyWith(color: AppColors.ink70)),
                const SizedBox(height: 9),
                ChoiceRow<Sport>(
                  options: AppState.sports,
                  value: AppState.sports.firstWhere((s) => s.name == _sport),
                  labelOf: (s) => s.name,
                  onChanged: (s) => setState(() => _sport = s.name),
                ),
                const SizedBox(height: 18),
                Text('Kota', style: T.caps.copyWith(color: AppColors.ink70)),
                const SizedBox(height: 9),
                ChoiceRow<String>(
                  options: AppState.cities,
                  value: _city,
                  labelOf: (v) => v,
                  onChanged: (v) => setState(() => _city = v),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: R.md),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              PrimaryButton(
                label: _signUp ? 'Daftar & masuk' : 'Masuk',
                height: 52,
                loading: _busy,
                onTap: _submit,
              ),
              const SizedBox(height: 20),
              _divider(),
              const SizedBox(height: 20),
              _socialButton(
                leading: const GoogleG(size: 20),
                label: 'Lanjutkan dengan Google',
                onTap: _google,
              ),
              const SizedBox(height: 12),
              _socialButton(
                leading: const Icon(Icons.explore_outlined, size: 20, color: AppColors.ink70),
                label: 'Lanjut sebagai tamu',
                onTap: _guest,
                bg: AppColors.chip,
                border: false,
              ),
              const SizedBox(height: 10),
              Text('Sebagai tamu kamu bisa langsung lihat-lihat; datanya tetap tersimpan dan bisa '
                  'diubah jadi akun beneran kapan saja.',
                  textAlign: TextAlign.center,
                  style: T.small),
              const SizedBox(height: 18),
              if (!_signUp)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: R.md,
                    border: Border.all(color: AppColors.yellow.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.key_rounded, size: 16, color: AppColors.yellowDeep),
                          const SizedBox(width: 8),
                          Text('Akun demo', style: T.caps.copyWith(color: AppColors.ink)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('demo@reclub.id  ·  reclub123',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      const Text('Sudah terisi otomatis — tinggal tekan Masuk.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink70)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTab(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: R.pill,
          boxShadow: on ? Shadows.soft : null,
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: on ? AppColors.ink : AppColors.muted)),
      ),
    );
  }
}

/// One entry in the Google account chooser.
class GoogleAccount {
  const GoogleAccount(this.name, this.email);
  final String name;
  final String email;
}

/// Account picker that mirrors the Google sheet: pick a suggested account or
/// type another one.
class _GoogleAccountSheet extends StatefulWidget {
  const _GoogleAccountSheet();

  @override
  State<_GoogleAccountSheet> createState() => _GoogleAccountSheetState();
}

class _GoogleAccountSheetState extends State<_GoogleAccountSheet> {
  static const _suggested = [
    GoogleAccount('User', 'demo@reclub.id'),
    GoogleAccount('Andi Pratama', 'andi.pratama@gmail.com'),
    GoogleAccount('Sinta Dewi', 'sinta.dewi@gmail.com'),
  ];

  bool _other = false;
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_other) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(controller: _name, label: 'Nama', hint: 'Nama di akun Google', icon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          AppField(
            controller: _email,
            label: 'Email Google',
            hint: 'nama@gmail.com',
            icon: Icons.alternate_email_rounded,
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Lanjutkan',
            height: 50,
            onTap: () => Navigator.pop(context, GoogleAccount(_name.text, _email.text)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _other = false),
            child: const Text('Kembali ke daftar akun',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in _suggested)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Avatar(label: a.name, size: 42),
            title: Text(a.name, style: T.title),
            subtitle: Text(a.email, style: T.small),
            onTap: () => Navigator.pop(context, a),
          ),
        const Divider(color: AppColors.hairline, height: 26),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: AppColors.chip, shape: BoxShape.circle),
            child: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppColors.ink70),
          ),
          title: Text('Gunakan akun lain', style: T.title),
          subtitle: Text('Masuk dengan email Google kamu sendiri', style: T.small),
          onTap: () => setState(() => _other = true),
        ),
        const SizedBox(height: 6),
        Text('reclub hanya menyimpan nama dan email untuk membuat profilmu.',
            style: T.small),
      ],
    );
  }
}
