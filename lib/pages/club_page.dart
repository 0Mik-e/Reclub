import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ClubPage extends StatefulWidget {
  const ClubPage({super.key});

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  int _tab = 0;
  String _memberFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final s = appState;
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_cover(context, s), _identity(context, s)],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        UnderlineTabs(
                          items: const ['BERANDA', 'AKTIVITAS', 'ANGGOTA', 'TENTANG'],
                          index: _tab,
                          spread: true,
                          onChanged: (i) => setState(() => _tab = i),
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: switch (_tab) {
                  0 => _feed(context, s),
                  1 => _activities(context, s),
                  2 => _members(context, s),
                  _ => _about(context, s),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ cover
  Widget _cover(BuildContext context, AppState s) {
    return SizedBox(
      height: 178,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _CoverPainter()),
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).padding.top + 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: R.pill,
                    ),
                    child: const Text('KLUB SAYA',
                        style: TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.9)),
                  ),
                  const Spacer(),
                  CircleIconButton(
                    icon: Icons.ios_share_rounded,
                    size: 34,
                    bg: Colors.white.withValues(alpha: 0.22),
                    fg: Colors.white,
                    border: false,
                    onTap: () => toast(context, 'Tautan disalin', icon: Icons.link_rounded),
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: Icons.more_horiz_rounded,
                    size: 34,
                    bg: Colors.white.withValues(alpha: 0.22),
                    fg: Colors.white,
                    border: false,
                    onTap: () => _clubMenu(context, s),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity(BuildContext context, AppState s) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 90),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.club.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.h2),
                        const SizedBox(height: 4),
                        Text('Publik · ${s.club.sport} · ${s.club.members} anggota',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: s.clubJoined ? 'Anggota ✓' : 'Gabung klub',
                      kind: s.clubJoined ? BtnKind.soft : BtnKind.primary,
                      onTap: () {
                        appState.toggleClubJoin();
                        toast(context, s.clubJoined ? 'Kamu keluar dari klub' : 'Selamat datang di ${s.club.name}!',
                            icon: Icons.groups_rounded);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Tulis post',
                      kind: BtnKind.outline,
                      icon: Icons.edit_outlined,
                      onTap: () => _composePost(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: -38,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Avatar(label: s.club.name, size: 70, bold: true),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- feed
  Widget _feed(BuildContext context, AppState s) {
    final upcoming = s.meets.where((m) => m.clubName.contains('USC')).take(3).toList();
    return SliverList.list(
      children: [
        SectionCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(child: StatTile(value: '${s.club.members}', label: 'Anggota')),
              Expanded(child: StatTile(value: '${s.activities.length}', label: 'Aktivitas rutin')),
              Expanded(
                  child: StatTile(
                      value: '${s.activities.fold<int>(0, (a, x) => a + x.going)}',
                      label: 'Ikut minggu ini',
                      color: AppColors.greenDark)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (upcoming.isNotEmpty) ...[
          const SectionHeader('Sesi terdekat'),
          SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: upcoming.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final m = upcoming[i];
                return Container(
                  width: 224,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: R.lg,
                    boxShadow: Shadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Tag(m.tag, dense: true, color: AppColors.greenDark, bg: AppColors.greenSoft),
                          const Spacer(),
                          Text('${m.spotsLeft} slot', style: T.small),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.title),
                      const SizedBox(height: 10),
                      const Spacer(),
                      ProgressBar(value: m.taken / m.capacity),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 13, color: AppColors.faint),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][m.start.weekday - 1]} '
                              '${m.start.hour}:${m.start.minute.toString().padLeft(2, '0')}',
                              style: T.small,
                            ),
                          ),
                          Text('${m.taken}/${m.capacity}', style: T.small),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        SectionHeader('Postingan', action: 'Tulis', onAction: () => _composePost(context)),
        for (var i = 0; i < s.posts.length; i++)
          Reveal(delayMs: i * 50, child: _postCard(context, s.posts[i])),
        if (s.posts.isEmpty)
          const EmptyState(
            icon: Icons.forum_outlined,
            title: 'Belum ada postingan',
            subtitle: 'Jadilah yang pertama berbagi kabar di klub ini.',
          ),
      ],
    );
  }

  Widget _postCard(BuildContext context, ClubPost p) {
    final isAnnouncement = p.kind == 'Announcement';
    final mine = p.author == appState.me?.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: R.lg,
        boxShadow: Shadows.card,
        border: isAnnouncement ? Border.all(color: AppColors.yellow.withValues(alpha: 0.55), width: 1.4) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAnnouncement)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.yellowSoft,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, size: 16, color: AppColors.yellowDeep),
                  const SizedBox(width: 7),
                  Text('PENGUMUMAN', style: T.caps.copyWith(color: AppColors.ink)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(label: p.author, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.title),
                          const SizedBox(height: 2),
                          Text(p.age, style: T.small),
                        ],
                      ),
                    ),
                    if (mine)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.faint),
                        onPressed: () async {
                          await appState.deletePost(p.id);
                          if (context.mounted) toast(context, 'Postingan dihapus');
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(p.body, style: T.body),
                const SizedBox(height: 14),
                const DottedLine(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => appState.toggleLike(p.id),
                      child: Row(
                        children: [
                          Icon(p.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 18, color: p.liked ? AppColors.red : AppColors.muted),
                          const SizedBox(width: 6),
                          Text('${p.likes}',
                              style: T.label.copyWith(color: p.liked ? AppColors.red : AppColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => toast(context, 'Komentar belum tersedia di versi ini'),
                      child: Row(
                        children: [
                          const Icon(Icons.mode_comment_outlined, size: 17, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Text('${p.comments}', style: T.label),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => toast(context, 'Tautan disalin', icon: Icons.link_rounded),
                      child: const Icon(Icons.ios_share_rounded, size: 17, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- activities
  Widget _activities(BuildContext context, AppState s) {
    return SliverList.list(
      children: [
        SectionCard(
          color: AppColors.lavender,
          shadow: false,
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 19, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Tekan "Ikut" untuk mendaftar. Kuota tersimpan di database.',
                    style: T.small.copyWith(color: AppColors.ink70)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < s.activities.length; i++)
          Reveal(delayMs: i * 40, child: _activityRow(context, s.activities[i])),
      ],
    );
  }

  Widget _activityRow(BuildContext context, Activity a) {
    final full = a.going >= a.capacity && !a.attending;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: R.lg, boxShadow: Shadows.card),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 56,
                decoration: BoxDecoration(color: AppColors.chip, borderRadius: R.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(a.day.toUpperCase(), style: T.caps.copyWith(fontSize: 9.5)),
                    const SizedBox(height: 1),
                    Text(a.time.split(' ').first,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.title),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(a.attending ? Icons.check_circle_rounded : Icons.people_outline_rounded,
                            size: 13, color: a.attending ? AppColors.greenDark : AppColors.faint),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text('${a.going}/${a.capacity} ikut',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 78,
                child: PrimaryButton(
                  label: a.attending ? 'Batal' : (full ? 'Penuh' : 'Ikut'),
                  height: 34,
                  kind: a.attending ? BtnKind.soft : (full ? BtnKind.outline : BtnKind.dark),
                  onTap: full
                      ? null
                      : () async {
                          final ok = await appState.toggleAttend(a.id);
                          if (!context.mounted) return;
                          toast(context, ok ? (a.attending ? 'Terdaftar di ${a.title}' : 'Pendaftaran dibatalkan') : 'Kuota penuh');
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            value: a.going / a.capacity,
            color: a.going >= a.capacity ? AppColors.orange : AppColors.green,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- members
  Widget _members(BuildContext context, AppState s) {
    final list = _memberFilter == 'Semua'
        ? s.members
        : s.members.where((m) => m.level == _memberFilter).toList();
    return SliverList.list(
      children: [
        ChoiceRow<String>(
          options: const ['Semua', ...AppState.levels],
          value: _memberFilter,
          labelOf: (v) => v,
          onChanged: (v) => setState(() => _memberFilter = v),
        ),
        const SizedBox(height: 14),
        Text('${list.length} anggota', style: T.caps),
        const SizedBox(height: 10),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Padding(padding: EdgeInsets.only(left: 62), child: Divider(height: 1, color: AppColors.hairline)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Avatar(label: list[i].name, size: 40),
                  title: Text(list[i].name, style: T.title),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('${list[i].level}${list[i].team != null ? ' · Tim ${list[i].team}' : ''}',
                        style: T.small),
                  ),
                  trailing: CircleIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    size: 32,
                    onTap: () => toast(context, 'Pesan ke ${list[i].name} dikirim'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ about
  Widget _about(BuildContext context, AppState s) {
    final byLevel = <String, int>{};
    for (final m in s.members) {
      byLevel[m.level] = (byLevel[m.level] ?? 0) + 1;
    }
    return SliverList.list(
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TENTANG KLUB', style: T.caps),
              const SizedBox(height: 10),
              Text(s.club.about, style: T.body),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KOMPOSISI LEVEL', style: T.caps),
              const SizedBox(height: 14),
              for (final e in byLevel.entries) ...[
                Row(
                  children: [
                    Expanded(child: Text(e.key, style: T.bodyStrong)),
                    Text('${e.value} orang', style: T.small),
                  ],
                ),
                const SizedBox(height: 7),
                ProgressBar(
                  value: e.value / s.members.length,
                  color: AppColors.tintFor(e.key),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: [
              _infoRow(Icons.place_outlined, 'Lokasi', '${s.club.city}, Indonesia'),
              const Divider(height: 22, color: AppColors.hairline),
              _infoRow(Icons.sports_tennis_rounded, 'Olahraga', s.club.sport),
              const Divider(height: 22, color: AppColors.hairline),
              _infoRow(Icons.lock_open_rounded, 'Tipe', 'Publik — siapa saja bisa gabung'),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 12),
        Text(label, style: T.label),
        const Spacer(),
        Flexible(
          child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.bodyStrong),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- sheets
  void _composePost(BuildContext context) {
    final body = TextEditingController();
    var kind = 'Post';
    showAppSheet(
      context,
      title: 'Tulis postingan',
      subtitle: 'Muncul di beranda klub dan tersimpan permanen.',
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChoiceRow<String>(
                options: const ['Post', 'Announcement'],
                value: kind,
                labelOf: (v) => v == 'Post' ? 'Postingan' : 'Pengumuman',
                onChanged: (v) => setSheet(() => kind = v),
              ),
              const SizedBox(height: 14),
              AppField(controller: body, hint: 'Apa yang ingin kamu bagikan?', maxLines: 5, autofocus: true),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Posting',
                icon: Icons.send_rounded,
                onTap: () async {
                  if (body.text.trim().isEmpty) {
                    toast(ctx, 'Tulis sesuatu dulu');
                    return;
                  }
                  await appState.addPost(body.text, kind: kind);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  toast(context, 'Postingan terkirim', icon: Icons.check_circle_rounded);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clubMenu(BuildContext context, AppState s) {
    showAppSheet(
      context,
      title: s.club.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined, size: 20),
            title: const Text('Notifikasi klub', style: T.bodyStrong),
            onTap: () {
              Navigator.pop(context);
              toast(context, 'Notifikasi klub diaktifkan');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_outlined, size: 20),
            title: const Text('Undang teman', style: T.bodyStrong),
            onTap: () {
              Navigator.pop(context);
              toast(context, 'Tautan disalin', icon: Icons.link_rounded);
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app_rounded, size: 20, color: AppColors.red),
            title: const Text('Keluar dari klub',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.red)),
            enabled: s.clubJoined,
            onTap: () {
              Navigator.pop(context);
              appState.toggleClubJoin();
              toast(context, 'Kamu keluar dari klub');
            },
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => old.child != child;
}

/// Decorative club cover: no image assets needed, and it scales to any width.
class _CoverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE23B3B), Color(0xFF9E1B32)],
        ).createShader(rect),
    );

    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = AppColors.yellow.withValues(alpha: 0.45);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.28), 26.0 + i * 22, gold);
    }

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.12);
    for (var y = 0; y < 6; y++) {
      for (var x = 0; x < 12; x++) {
        canvas.drawCircle(Offset(14 + x * 18, 16 + y * 20), 2.1, dot);
      }
    }

    final swoosh = Path()
      ..moveTo(0, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.6, size.width, size.height * 0.94)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(swoosh, Paint()..color = Colors.black.withValues(alpha: 0.16));

    final ball = Paint()..color = AppColors.yellow.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(size.width * 0.17, size.height * 0.34), 15, ball);
    final hole = Paint()..color = const Color(0xFFB3241F);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(
        Offset(size.width * 0.17, size.height * 0.34) + Offset(math.cos(a), math.sin(a)) * 7,
        1.9,
        hole,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}