import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../data/vffl.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _terms = [
  'Satu tim terdiri dari 4 pemain: 1 kapten (pendaftar) dan 3 anggota yang dipilih dari daftar teman.',
  'Susunan tim tidak dapat diganti setelah pembayaran diselesaikan.',
  'Biaya pendaftaran bersifat final dan tidak dapat dikembalikan, kecuali turnamen dibatalkan penyelenggara.',
  'Tim wajib hadir 15 menit sebelum jadwal pertandingan dimulai.',
  'Penyelenggara berhak mendiskualifikasi tim yang melanggar prinsip fair play.',
  'Jadwal dan venue dapat berubah dengan pemberitahuan sebelumnya.',
];

// Mengisi nama tim, anggota tim, syarat & ketentuan
class VfflRegisterPage extends StatefulWidget {
  const VfflRegisterPage({super.key, required this.season});
  final int season;

  @override
  State<VfflRegisterPage> createState() => _VfflRegisterPageState();
}

class _VfflRegisterPageState extends State<VfflRegisterPage> {
  String _teamName = '';
  final List<Player> _mates = [];
  bool _agree = false;

  SeasonMeta get _meta => Vffl.meta(widget.season);

  bool get _nameOk => _teamName.trim().length >= 3;
  bool get _matesOk => _mates.length == 3;
  bool get _ready => _nameOk && _matesOk && _agree;

  String get _hint {
    final missing = [
      if (!_nameOk) 'isi nama tim',
      if (!_matesOk) 'pilih 3 anggota tim',
      if (!_agree) 'centang syarat dan ketentuan',
    ];
    return missing.isEmpty ? '' : 'Belum lengkap: ${missing.join(', ')}.';
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: _teamName);
    await showAppSheet<void>(
      context,
      title: 'Nama tim',
      subtitle: 'Minimal 3 karakter, maksimal 24 karakter.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppField(
              controller: c,
              hint: 'Mis. Bandung Smashers',
              icon: Icons.groups_rounded,
              autofocus: true,
            ),
            const SizedBox(height: 18),
            Builder(
              builder: (ctx) => PrimaryButton(
                label: 'Simpan nama tim',
                onTap: () {
                  final v = c.text.trim();
                  if (v.length < 3) {
                    toast(ctx, 'Nama tim minimal 3 karakter');
                    return;
                  }
                  if (v.length > 24) {
                    toast(ctx, 'Nama tim maksimal 24 karakter');
                    return;
                  }
                  setState(() => _teamName = v);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMates() async {
    final candidates = appState.friends.where((p) => !appState.isSelf(p)).toList();
    final picked = List<Player>.from(_mates);
    await showAppSheet<void>(
      context,
      title: 'Pilih anggota tim',
      subtitle: 'Dari halaman Sosial · pilih tepat 3 teman',
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 340,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                children: [
                  for (final p in candidates)
                    Builder(builder: (_) {
                      final on = picked.any((x) => x.id == p.id);
                      return ListTile(
                        shape: const RoundedRectangleBorder(borderRadius: R.md),
                        leading: Avatar(label: p.name, size: 38),
                        title: Text(p.name, style: T.title),
                        subtitle: Text(
                          [p.level, if (p.sports.isNotEmpty) p.sports.join(', ')].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.small,
                        ),
                        trailing: Icon(
                          on ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: on ? AppColors.green : AppColors.faint,
                        ),
                        onTap: () {
                          if (on) {
                            setSheet(() => picked.removeWhere((x) => x.id == p.id));
                          } else if (picked.length >= 3) {
                            toast(ctx, 'Maksimal 3 anggota tim');
                          } else {
                            setSheet(() => picked.add(p));
                          }
                        },
                      );
                    }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: PrimaryButton(
                label: 'Simpan (${picked.length}/3)',
                onTap: () {
                  setState(() {
                    _mates
                      ..clear()
                      ..addAll(picked);
                  });
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTerms() {
    showAppSheet<void>(
      context,
      title: 'Syarat dan ketentuan',
      subtitle: _meta.title,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, t) in _terms.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 24, child: Text('${i + 1}.', style: T.bodyStrong)),
                    Expanded(child: Text(t, style: T.body)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Builder(
              builder: (ctx) => PrimaryButton(label: 'Mengerti', onTap: () => Navigator.pop(ctx)),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VfflPaymentPage(
          season: widget.season,
          teamName: _teamName.trim(),
          mates: List<Player>.of(_mates),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    final me = appState.me;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _Header(title: m.title, caption: 'PENDAFTARAN TIM', detail: '${m.city} · ${m.feeLabel} / tim'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text('NAMA TIM', style: T.caps.copyWith(color: AppColors.ink)),
                const SizedBox(height: 8),
                SectionCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.chip, borderRadius: R.md),
                        child: const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.ink70),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _nameOk ? _teamName : 'Belum diisi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _nameOk ? T.title : T.title.copyWith(color: AppColors.faint),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 112,
                        child: PrimaryButton(
                          label: _nameOk ? 'Ubah nama' : 'Isi nama tim',
                          height: 38,
                          kind: BtnKind.outline,
                          onTap: _editName,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('ANGGOTA TIM', style: T.caps.copyWith(color: AppColors.ink)),
                    const Spacer(),
                    Text('${_mates.length + 1}/4 pemain', style: T.small),
                  ],
                ),
                const SizedBox(height: 8),
                SectionCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      _memberRow(
                        leading: Avatar(label: me?.name ?? 'Kamu', size: 36),
                        title: me?.name ?? 'Kamu',
                        subtitle: 'Kapten tim',
                        trailing: const Tag('Kamu', dense: true, color: AppColors.greenDark, bg: AppColors.greenSoft),
                      ),
                      for (var i = 0; i < 3; i++) ...[
                        const Divider(height: 1, color: AppColors.hairline, indent: 62),
                        if (i < _mates.length)
                          _memberRow(
                            leading: Avatar(label: _mates[i].name, size: 36),
                            title: _mates[i].name,
                            subtitle: _mates[i].level,
                            trailing: GestureDetector(
                              onTap: () => setState(() => _mates.removeAt(i)),
                              child: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                            ),
                          )
                        else
                          _memberRow(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.chip,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: const Icon(Icons.person_add_alt_1_rounded, size: 17, color: AppColors.muted),
                            ),
                            title: 'Anggota ${i + 2}',
                            subtitle: 'Ketuk untuk tambah dari Sosial',
                            muted: true,
                            onTap: _pickMates,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: _mates.isEmpty ? 'Tambah 3 anggota dari Sosial' : 'Ubah anggota tim',
                  icon: Icons.group_add_rounded,
                  kind: BtnKind.outline,
                  onTap: _pickMates,
                ),
                const SizedBox(height: 20),
                SectionCard(
                  color: AppColors.cream,
                  shadow: false,
                  padding: const EdgeInsets.fromLTRB(8, 8, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agree,
                            activeColor: AppColors.green,
                            onChanged: (v) => setState(() => _agree = v ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 11),
                              child: GestureDetector(
                                onTap: () => setState(() => _agree = !_agree),
                                child: const Text(
                                  'Saya menyetujui syarat dan ketentuan turnamen ini.',
                                  style: TextStyle(
                                      fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w700, color: AppColors.ink),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: GestureDetector(
                          onTap: _showTerms,
                          child: const Text('Baca syarat dan ketentuan',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue,
                                  decoration: TextDecoration.underline)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_ready) ...[
                  Text(_hint, textAlign: TextAlign.center, style: T.small),
                  const SizedBox(height: 8),
                ],
                PrimaryButton(
                  label: 'Lanjut ke pembayaran · ${m.feeLabel}',
                  height: 50,
                  onTap: _ready ? _next : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberRow({
    required Widget leading,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool muted = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted ? T.title.copyWith(color: AppColors.faint) : T.title),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class VfflPaymentPage extends StatefulWidget {
  const VfflPaymentPage({
    super.key,
    required this.season,
    required this.teamName,
    required this.mates,
  });
  final int season;
  final String teamName;
  final List<Player> mates;

  @override
  State<VfflPaymentPage> createState() => _VfflPaymentPageState();
}

class _VfflPaymentPageState extends State<VfflPaymentPage> {
  String? _method; // 'Google Play' | 'QRIS' | 'Kartu Debit/Kredit'
  bool _busy = false;

  SeasonMeta get _meta => Vffl.meta(widget.season);

  Future<void> _finish() async {
    final method = _method;
    if (method == null || _busy) return;
    setState(() => _busy = true);
    final rootContext = Navigator.of(context).context;
    final err = await appState.registerCompTeam(
      season: widget.season,
      teamName: widget.teamName,
      memberNames: [appState.me?.name ?? 'Kamu', ...widget.mates.map((p) => p.name)],
      method: method,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _busy = false);
      toast(context, err, icon: Icons.error_outline_rounded);
      return;
    }

    Navigator.of(context).popUntil((r) => r.isFirst);
    if (rootContext.mounted) {
      toast(rootContext, 'Tim ${widget.teamName} resmi bergabung di ${_meta.title}',
          icon: Icons.check_circle_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    final names = [appState.me?.name ?? 'Kamu', ...widget.mates.map((p) => p.name)];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _Header(title: 'Pembayaran', caption: m.title, detail: 'Total ${rupiah(m.feeAmount)}'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text('RINGKASAN', style: T.caps.copyWith(color: AppColors.ink)),
                const SizedBox(height: 8),
                SectionCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Avatar(label: widget.teamName, size: 40, square: true, bold: true),
                          const SizedBox(width: 12),
                          Expanded(child: Text(widget.teamName, style: T.title)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(names.join(' · '), style: T.small),
                      const Divider(height: 26, color: AppColors.hairline),
                      Row(
                        children: [
                          Text('Biaya tim', style: T.label),
                          const Spacer(),
                          Text(rupiah(m.feeAmount), style: T.num),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('METODE PEMBAYARAN', style: T.caps.copyWith(color: AppColors.ink)),
                const SizedBox(height: 8),
                _methodTile('Google Play', 'Bayar lewat akun Google Play', Icons.shop_2_rounded),
                const SizedBox(height: 10),
                _methodTile('QRIS', 'Scan dari e-wallet atau mobile banking', Icons.qr_code_2_rounded),
                const SizedBox(height: 10),
                _methodTile('Kartu Debit/Kredit', 'Visa, Mastercard, JCB', Icons.credit_card_rounded),
                const SizedBox(height: 14),
                if (_method == 'QRIS')
                  SectionCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: 168,
                          height: 168,
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: R.md,
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, size: 132, color: AppColors.ink70),
                        ),
                        const SizedBox(height: 10),
                        Text('Kode QRIS contoh', style: T.bodyStrong),
                        const SizedBox(height: 2),
                        Text('Placeholder · belum terhubung ke pembayaran asli',
                            textAlign: TextAlign.center, style: T.small),
                      ],
                    ),
                  )
                else
                  Text('Tombol metode pembayaran masih berupa placeholder: tidak ada transaksi nyata.',
                      textAlign: TextAlign.center, style: T.small),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: PrimaryButton(
              label: 'Selesai',
              height: 50,
              icon: Icons.check_rounded,
              loading: _busy,
              onTap: _method == null ? null : _finish,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile(String id, String subtitle, IconData icon) {
    final on = _method == id;
    return GestureDetector(
      onTap: () => setState(() => _method = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: R.lg,
          border: Border.all(color: on ? AppColors.green : AppColors.hairline, width: on ? 1.8 : 1.2),
          boxShadow: Shadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: on ? AppColors.greenSoft : AppColors.chip, borderRadius: R.md),
              child: Icon(icon, size: 22, color: on ? AppColors.greenDark : AppColors.ink70),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id, style: T.title),
                  const SizedBox(height: 2),
                  Text(subtitle, style: T.small),
                ],
              ),
            ),
            Icon(
              on ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: on ? AppColors.green : AppColors.faint,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.caption, required this.detail});
  final String title;
  final String caption;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.greenGradient),
      padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 8, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleIconButton(
                icon: Icons.arrow_back_rounded,
                size: 36,
                bg: Colors.white.withValues(alpha: 0.18),
                fg: Colors.white,
                border: false,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Text(caption, style: T.caps.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 26, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -0.6, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(detail, style: T.small.copyWith(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}