import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final me = appState.me;
        if (me == null) return const SizedBox.shrink();
        final joined = appState.myMeets;
        final st = appState.standings;
        final mine = st.where((s) => s.player == me.firstName).toList();
        final played = mine.isEmpty ? 0 : mine.first.played;
        final wins = mine.isEmpty ? 0 : mine.first.wins;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 232,
                backgroundColor: AppColors.ink,
                surfaceTintColor: AppColors.ink,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editProfile(context, me),
                  ),
                ],
                title: const Text('Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.inkGradient),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 46, 20, 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Avatar(label: me.name, size: 62, ring: Colors.white24),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(me.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                                      const SizedBox(height: 3),
                                      Text(me.email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white60)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                Tag(me.level, color: Colors.white, bg: Colors.white.withValues(alpha: 0.14)),
                                Tag(me.city, color: Colors.white, bg: Colors.white.withValues(alpha: 0.14), icon: Icons.place_outlined),
                                if (me.isGoogle)
                                  Tag('Google', color: Colors.white, bg: Colors.white.withValues(alpha: 0.14), icon: Icons.verified_rounded),
                                if (me.isGuest)
                                  Tag('Mode tamu', color: AppColors.ink, bg: AppColors.yellow, icon: Icons.explore_outlined),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                sliver: SliverList.list(
                  children: [
                    if (me.isGuest) ...[
                      _guestCard(context),
                      const SizedBox(height: 14),
                    ],
                    SectionCard(
                      child: Row(
                        children: [
                          Expanded(child: StatTile(value: '${joined.length}', label: 'Meet diikuti')),
                          Container(width: 1, height: 34, color: AppColors.hairline),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: StatTile(value: '$played', label: 'Match dimainkan'),
                            ),
                          ),
                          Container(width: 1, height: 34, color: AppColors.hairline),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: StatTile(value: '$wins', label: 'Menang', color: AppColors.greenDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OLAHRAGA FAVORIT', style: T.caps),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final sp in me.sports)
                                Tag(sp,
                                    icon: AppState.sportIcon(sp),
                                    color: AppColors.blue,
                                    bg: AppColors.blueSoft),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (me.bio.isNotEmpty) ...[
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TENTANG', style: T.caps),
                            const SizedBox(height: 8),
                            Text(me.bio, style: T.body),
                            if (me.phone.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 15, color: AppColors.muted),
                                  const SizedBox(width: 7),
                                  Text(me.phone, style: T.bodyStrong),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SectionHeader('Meet yang kamu ikuti'),
                    if (joined.isEmpty)
                      SectionCard(
                        child: EmptyState(
                          icon: Icons.event_busy_rounded,
                          title: 'Belum ada meet',
                          subtitle: 'Gabung sesi dari halaman Discover, nanti muncul di sini.',
                          actionLabel: 'Cari meet',
                          onAction: () => Navigator.pop(context),
                        ),
                      )
                    else
                      ...joined.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SectionCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: R.md),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(_dayShort(m.start),
                                            style: const TextStyle(
                                                fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.greenDark)),
                                        Text('${m.start.day}',
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.greenDark)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.title),
                                        const SizedBox(height: 3),
                                        Text('${_time(m.start)} · ${m.venue}',
                                            maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      await appState.toggleJoinMeet(m.id);
                                      if (context.mounted) toast(context, 'Kamu keluar dari ${m.title}');
                                    },
                                    child: const Tag('Batal', color: AppColors.red, bg: AppColors.redSoft),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    const SizedBox(height: 8),
                    const SectionHeader('Akun'),
                    SectionCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _row(Icons.person_outline_rounded, 'Edit profil', () => _editProfile(context, me)),
                          _divider(),
                          _row(Icons.lock_outline_rounded, 'Ubah password', () => _changePassword(context)),
                          _divider(),
                          _row(Icons.storage_rounded, 'Reset data aplikasi', () => _resetData(context),
                              color: AppColors.orange),
                          _divider(),
                          _row(Icons.logout_rounded, 'Keluar', () => _signOut(context), color: AppColors.red),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text('Reclub Clone · data tersimpan lokal di SQLite',
                          style: T.small.copyWith(color: AppColors.faint)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _divider() => const Padding(
        padding: EdgeInsets.only(left: 54),
        child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
      );

  static Widget _row(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: color ?? AppColors.ink70),
      title: Text(label,
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: color ?? AppColors.ink)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faint),
      shape: const RoundedRectangleBorder(borderRadius: R.lg),
    );
  }

  static String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static String _dayShort(DateTime d) =>
      const ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'][d.weekday - 1];

  // ---- actions ----------------------------------------------------------
  static void _editProfile(BuildContext context, User me) {
    final name = TextEditingController(text: me.name);
    final bio = TextEditingController(text: me.bio);
    final phone = TextEditingController(text: me.phone);
    var level = me.level;
    var city = me.city;
    final sports = <String>[...me.sports];
    String? sportHint;

    showAppSheet(
      context,
      title: 'Edit profil',
      subtitle: 'Perubahan langsung tersimpan ke database.',
      child: StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppField(controller: name, label: 'Nama', hint: 'Nama lengkap'),
              const SizedBox(height: 14),
              AppField(controller: phone, label: 'No. HP', hint: '+62 ...', keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              AppField(controller: bio, label: 'Bio', hint: 'Ceritakan gaya mainmu', maxLines: 3),
              const SizedBox(height: 18),
              Text('Level', style: T.caps.copyWith(color: AppColors.ink70)),
              const SizedBox(height: 9),
              ChoiceRow<String>(
                options: AppState.levels,
                value: level,
                labelOf: (v) => v,
                onChanged: (v) => setSheet(() => level = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Olahraga Favorit', style: T.caps.copyWith(color: AppColors.ink70)),
                  const Spacer(),
                  Text('${sports.length}/${AppState.maxFavoriteSports} dipilih', style: T.small),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sp in AppState.sports)
                    _sportChip(
                      sp.name,
                      sports.contains(sp.name),
                      () => setSheet(() {
                        if (sports.contains(sp.name)) {
                          if (sports.length == 1) {
                            sportHint = 'Pilih minimal 1 olahraga favorit.';
                          } else {
                            sports.remove(sp.name);
                            sportHint = null;
                          }
                        } else if (sports.length >= AppState.maxFavoriteSports) {
                          sportHint = 'Maksimal ${AppState.maxFavoriteSports} olahraga favorit.';
                        } else {
                          sports.add(sp.name);
                          sportHint = null;
                        }
                      }),
                    ),
                ],
              ),
              if (sportHint != null) ...[
                const SizedBox(height: 8),
                Text(sportHint!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.red)),
              ],
              const SizedBox(height: 16),
              Text('Kota', style: T.caps.copyWith(color: AppColors.ink70)),
              const SizedBox(height: 9),
              ChoiceRow<String>(
                options: AppState.cities,
                value: city,
                labelOf: (v) => v,
                onChanged: (v) => setSheet(() => city = v),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Simpan perubahan',
                onTap: () async {
                  final err = await appState.updateProfile(
                    name: name.text,
                    level: level,
                    userCity: city,
                    userSports: sports,
                    bio: bio.text,
                    phone: phone.text,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  toast(context, err ?? 'Profil tersimpan', icon: err == null ? Icons.check_circle : Icons.error);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sportChip(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? AppColors.ink : Colors.white,
          borderRadius: R.pill,
          border: Border.all(color: on ? AppColors.ink : AppColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (on) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.ink70)),
          ],
        ),
      ),
    );
  }

  static void _changePassword(BuildContext context) {
    final oldPw = TextEditingController();
    final newPw = TextEditingController();
    showAppSheet(
      context,
      title: 'Ubah password',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppField(controller: oldPw, label: 'Password lama', hint: '••••••', obscure: true),
            const SizedBox(height: 14),
            AppField(controller: newPw, label: 'Password baru', hint: 'Minimal 6 karakter', obscure: true),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Simpan',
              onTap: () async {
                final err = await appState.changePassword(oldPw.text, newPw.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                toast(context, err ?? 'Password diperbarui',
                    icon: err == null ? Icons.check_circle : Icons.error);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _resetData(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset data?', style: T.h2),
        content: const Text(
          'Semua akun, meet, skor, dan chat akan dihapus lalu database dibuat ulang dari data awal.',
          style: T.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.resetData();
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static Widget _guestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: R.lg,
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_outlined, size: 17, color: AppColors.yellowDeep),
              const SizedBox(width: 8),
              Text('Kamu lagi mode tamu', style: T.caps.copyWith(color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Semua meet, chat, dan skor kamu sudah tersimpan. Buat akun biar tetap kepakai '
            'dan bisa dibuka dari email kamu.',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink70, height: 1.45),
          ),
          const SizedBox(height: 13),
          PrimaryButton(
            label: 'Buat akun sekarang',
            height: 44,
            onTap: () => _upgradeGuest(context),
          ),
        ],
      ),
    );
  }

  static void _upgradeGuest(BuildContext context) {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final error = ValueNotifier<String?>(null);
    showAppSheet<void>(
      context,
      title: 'Buat akun',
      subtitle: 'Data kamu sebagai tamu ikut pindah ke akun baru.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(controller: name, label: 'Nama lengkap', hint: 'Mis. Andi Pratama', icon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          AppField(
            controller: email,
            label: 'Email',
            hint: 'nama@email.com',
            icon: Icons.alternate_email_rounded,
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          AppField(
            controller: password,
            label: 'Password',
            hint: 'Minimal 6 karakter',
            icon: Icons.lock_outline_rounded,
            obscure: true,
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String?>(
            valueListenable: error,
            builder: (context, e, _) => e == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(e,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.red)),
                  ),
          ),
          PrimaryButton(
            label: 'Simpan akun',
            height: 50,
            onTap: () async {
              final err = await appState.upgradeGuest(
                name: name.text,
                email: email.text,
                password: password.text,
              );
              if (err != null) {
                error.value = err;
                return;
              }
              if (context.mounted) {
                Navigator.pop(context);
                toast(context, 'Akun kamu sudah aktif 🎉', icon: Icons.verified_rounded);
              }
            },
          ),
        ],
      ),
    );
  }

  static void _signOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?', style: T.h2),
        content: const Text('Data kamu tetap tersimpan dan bisa diakses lagi setelah masuk.', style: T.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.signOut();
            },
            child: const Text('Keluar', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}