import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'meet_page.dart';
import 'profile_page.dart';

const _dayNames = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];
const _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String timeLabel(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

String dateLabel(DateTime d) =>
    '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]}';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final s = appState;
        return Scaffold(
          backgroundColor: AppColors.canvas,
          floatingActionButton: s.discoverTab == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _createMeet(context),
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Buat meet',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(context, s),
                Container(
                  color: Colors.white,
                  child: UnderlineTabs(
                    items: const ['KLUB', 'MEET', 'KOMPETISI', 'VENUE', 'ORANG'],
                    index: s.discoverTab,
                    onChanged: s.setDiscoverTab,
                    accent: AppColors.blue,
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                Expanded(
                  child: switch (s.discoverTab) {
                    0 => _clubsTab(context),
                    1 => _meetsTab(context, s),
                    2 => _compsTab(context),
                    3 => _venuesTab(context),
                    _ => _peopleTab(context, s),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ header
  Widget _header(BuildContext context, AppState s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, ${s.me?.firstName ?? ''} 👋', style: T.h2),
                    const SizedBox(height: 2),
                    Text('${s.visibleMeets.length} sesi ${s.sport.name} di ${s.city}',
                        style: T.small),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                child: Avatar(label: s.me?.name ?? 'Kamu', size: 40),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _selector(
                  icon: Icons.place_outlined,
                  label: s.city,
                  onTap: () => _pickCity(context, s),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _selector(
                  icon: s.sport.icon,
                  label: s.sport.name,
                  onTap: () => _pickSport(context, s),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: R.md,
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: s.setQuery,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Cari klub, meet, atau venue…',
                      hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.faint),
                      prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.muted),
                      suffixIcon: s.query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.muted),
                              onPressed: () {
                                _search.clear();
                                s.setQuery('');
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleIconButton(
                icon: Icons.tune_rounded,
                size: 42,
                badge: s.filtersActive,
                onTap: () => _openFilters(context, s),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selector({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: R.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.ink70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: T.bodyStrong.copyWith(fontSize: 13.5)),
            ),
            const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ meets
  Widget _meetsTab(BuildContext context, AppState s) {
    final meets = s.visibleMeets;
    final groups = <String, List<Meet>>{};
    for (final m in meets) {
      groups.putIfAbsent(timeLabel(m.start), () => []).add(m);
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 7,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = s.today.add(Duration(days: i));
                final on = i == s.dayIndex;
                final count = s.meetsOnDay(i);
                return GestureDetector(
                  onTap: () => s.setDay(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: on ? AppColors.greenGradient : null,
                      color: on ? null : Colors.white,
                      borderRadius: R.md,
                      border: Border.all(color: on ? Colors.transparent : AppColors.hairline),
                      boxShadow: on ? Shadows.soft : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_dayNames[d.weekday - 1],
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: on ? Colors.white70 : AppColors.muted)),
                        const SizedBox(height: 2),
                        Text('${d.day}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: on ? Colors.white : AppColors.ink)),
                        const SizedBox(height: 3),
                        Container(
                          width: 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: count == 0
                                ? Colors.transparent
                                : (on ? Colors.white70 : AppColors.yellow),
                            borderRadius: R.pill,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.hairline),
        Expanded(
          child: meets.isEmpty
              ? EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'Tidak ada meet',
                  subtitle: s.filtersActive || s.query.isNotEmpty
                      ? 'Coba longgarkan filter atau pilih hari lain.'
                      : 'Belum ada sesi di ${dateLabel(s.selectedDay)}. Buat satu, yuk?',
                  actionLabel: s.filtersActive || s.query.isNotEmpty ? 'Reset filter' : 'Buat meet',
                  onAction: () {
                    if (s.filtersActive || s.query.isNotEmpty) {
                      _search.clear();
                      s.setQuery('');
                      s.clearFilters();
                    } else {
                      _createMeet(context);
                    }
                  },
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
                  children: [
                    for (final entry in groups.entries) ...[
                      Container(
                        color: AppColors.lavender,
                        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
                        child: Row(
                          children: [
                            Text(entry.key,
                                style: const TextStyle(
                                    fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                            const SizedBox(width: 8),
                            Container(width: 1, height: 12, color: AppColors.faint),
                            const SizedBox(width: 8),
                            Text('${entry.value.length} meet', style: T.small),
                          ],
                        ),
                      ),
                      for (var i = 0; i < entry.value.length; i++)
                        Reveal(delayMs: i * 40, child: _meetRow(context, entry.value[i])),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _meetRow(BuildContext context, Meet m) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => MeetPage(meetId: m.id))),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        margin: const EdgeInsets.only(bottom: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              label: m.clubName,
              size: 42,
              badge: m.hasGift
                  ? Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, size: 9, color: AppColors.ink),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.clubName, style: T.caps),
                  const SizedBox(height: 3),
                  Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.title),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (m.invited)
                        const Tag('Diundang', color: AppColors.ink, bg: AppColors.yellowSoft, dense: true),
                      Tag(m.tag, dense: true, color: _tagColor(m.tag), bg: _tagBg(m.tag)),
                      Tag(m.priceLabel, dense: true),
                      if (m.joined)
                        const Tag('Kamu ikut', dense: true, color: AppColors.greenDark, bg: AppColors.greenSoft),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 13, color: AppColors.faint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(m.venue,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CapacityBadge(taken: m.taken, capacity: m.capacity),
                const SizedBox(height: 8),
                Text('${m.distanceKm.toStringAsFixed(1)}km', style: T.small),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final ok = await appState.toggleJoinMeet(m.id);
                    if (!context.mounted) return;
                    toast(
                      context,
                      ok
                          ? (m.joined ? 'Berhasil gabung ${m.title}' : 'Kamu keluar dari meet')
                          : 'Meet sudah penuh',
                      icon: ok ? Icons.check_circle_rounded : Icons.info_outline,
                    );
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: m.joined ? AppColors.greenSoft : AppColors.chip,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      m.joined ? Icons.check_rounded : Icons.add_rounded,
                      size: 19,
                      color: m.joined ? AppColors.greenDark : AppColors.ink70,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _tagColor(String tag) => switch (tag) {
        'Comp' => AppColors.violet,
        'Training' => AppColors.blue,
        _ => AppColors.greenDark,
      };

  static Color _tagBg(String tag) => switch (tag) {
        'Comp' => const Color(0xFFF0EBFF),
        'Training' => AppColors.blueSoft,
        _ => AppColors.greenSoft,
      };

  // ------------------------------------------------------------------ clubs
  Widget _clubsTab(BuildContext context) {
    final q = appState.query.trim().toLowerCase();
    final list = AppState.clubs
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q))
        .toList();
    if (list.isEmpty) {
      return const EmptyState(
          icon: Icons.groups_outlined, title: 'Klub tidak ditemukan', subtitle: 'Coba kata kunci lain.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final c = list[i];
        final joined = c.id == appState.club.id && appState.clubJoined;
        return Reveal(
          delayMs: i * 40,
          child: SectionCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Avatar(label: c.name, size: 48, square: true),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.title),
                      const SizedBox(height: 3),
                      Text('${c.sport} · ${c.members} anggota',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                      const SizedBox(height: 5),
                      Text(c.about, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 84,
                  child: PrimaryButton(
                    label: joined ? 'Anggota' : 'Gabung',
                    height: 36,
                    kind: joined ? BtnKind.soft : BtnKind.outline,
                    onTap: () {
                      if (c.id == appState.club.id) {
                        appState.toggleClubJoin();
                        toast(context, joined ? 'Keluar dari ${c.name}' : 'Kamu gabung ${c.name}');
                      } else {
                        toast(context, 'Permintaan gabung ${c.name} dikirim');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ comps
  Widget _compsTab(BuildContext context) {
    final pools = ['A', 'B'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: AppColors.inkGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tag('SEDANG BERLANGSUNG',
                              color: AppColors.ink, bg: AppColors.yellow, dense: true),
                          const SizedBox(height: 9),
                          const Text('VFFL SEASON 4',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${appState.compTeams.length} tim · 2 pool · playoff',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white60)),
                        ],
                      ),
                    ),
                    const Icon(Icons.emoji_events_rounded, size: 40, color: AppColors.yellow),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(child: StatTile(value: '${appState.poolMatches.length}', label: 'Match pool')),
                    Expanded(child: StatTile(value: '${appState.bracket.length}', label: 'Match playoff')),
                    Expanded(
                        child: StatTile(
                            value: appState.poolTable('A').first['name'] as String,
                            label: 'Puncak pool A',
                            color: AppColors.greenDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final p in pools) ...[
          SectionHeader('Pool $p'),
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final row in appState.poolTable(p))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text('${appState.poolTable(p).indexOf(row) + 1}',
                              style: T.small.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        Avatar(label: row['name'] as String, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(row['name'] as String,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: T.bodyStrong),
                        ),
                        Text('${row['w']}M-${row['l']}K', style: T.small),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 30,
                          child: Text('${row['pts']}', textAlign: TextAlign.right, style: T.num),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ----------------------------------------------------------------- venues
  Widget _venuesTab(BuildContext context) {
    final q = appState.query.trim().toLowerCase();
    final list = AppState.venues
        .where((v) => q.isEmpty || v.name.toLowerCase().contains(q) || v.area.toLowerCase().contains(q))
        .toList();
    if (list.isEmpty) {
      return const EmptyState(
          icon: Icons.stadium_outlined, title: 'Venue tidak ditemukan', subtitle: 'Coba kata kunci lain.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final v = list[i];
        return Reveal(
          delayMs: i * 40,
          child: SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Container(
                  height: 74,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.tintFor(v.name).withValues(alpha: 0.85),
                        AppColors.tintFor(v.area),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(v.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: R.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: AppColors.yellowDeep),
                            const SizedBox(width: 3),
                            Text('${v.rating}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${v.area} · ${v.courts} lapangan', style: T.small),
                            const SizedBox(height: 4),
                            Text('Mulai ${v.priceFrom} / jam', style: T.bodyStrong),
                          ],
                        ),
                      ),
                      Text('${v.distanceKm.toStringAsFixed(1)} km', style: T.small),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 78,
                        child: PrimaryButton(
                          label: 'Booking',
                          height: 34,
                          kind: BtnKind.outline,
                          onTap: () => toast(context, 'Permintaan booking ${v.name} dikirim',
                              icon: Icons.event_available_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------- people
  Widget _peopleTab(BuildContext context, AppState s) {
    final q = s.query.trim().toLowerCase();
    final list = s.members.where((p) => q.isEmpty || p.name.toLowerCase().contains(q)).toList();
    if (list.isEmpty) {
      return const EmptyState(
          icon: Icons.person_search_rounded, title: 'Tidak ada orang', subtitle: 'Coba kata kunci lain.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = list[i];
        return Reveal(
          delayMs: i * 25,
          child: SectionCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Avatar(label: p.name, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.title),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Tag(p.level, dense: true),
                          if (p.team != null) ...[
                            const SizedBox(width: 6),
                            Tag('Tim ${p.team}', dense: true, color: AppColors.blue, bg: AppColors.blueSoft),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                CircleIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  size: 34,
                  onTap: () => toast(context, 'Undangan chat dikirim ke ${p.name}'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------- sheets
  void _pickCity(BuildContext context, AppState s) {
    showAppSheet(
      context,
      title: 'Pilih kota',
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        children: [
          for (final c in AppState.cities)
            ListTile(
              shape: const RoundedRectangleBorder(borderRadius: R.md),
              leading: Icon(Icons.place_outlined,
                  size: 20, color: c == s.city ? AppColors.green : AppColors.muted),
              title: Text(c, style: T.bodyStrong),
              trailing: c == s.city ? const Icon(Icons.check_rounded, color: AppColors.green, size: 20) : null,
              onTap: () {
                s.setCity(c);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _pickSport(BuildContext context, AppState s) {
    showAppSheet(
      context,
      title: 'Pilih olahraga',
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        children: [
          for (final sp in AppState.sports)
            ListTile(
              shape: const RoundedRectangleBorder(borderRadius: R.md),
              leading: Icon(sp.icon, size: 20, color: sp == s.sport ? AppColors.green : AppColors.muted),
              title: Text(sp.name, style: T.bodyStrong),
              trailing: sp == s.sport ? const Icon(Icons.check_rounded, color: AppColors.green, size: 20) : null,
              onTap: () {
                s.setSport(sp);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _openFilters(BuildContext context, AppState s) {
    showAppSheet(
      context,
      title: 'Filter',
      subtitle: 'Menyaring daftar meet pada hari terpilih.',
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipe sesi', style: T.caps.copyWith(color: AppColors.ink70)),
              const SizedBox(height: 10),
              ChoiceRow<String>(
                options: AppState.tags,
                value: s.tagFilter,
                labelOf: (v) => v,
                onChanged: (v) => setSheet(() => s.setTagFilter(v)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Jarak maksimum', style: T.caps.copyWith(color: AppColors.ink70)),
                  const Spacer(),
                  Text('${s.maxDistance.toStringAsFixed(0)} km', style: T.bodyStrong),
                ],
              ),
              Slider(
                value: s.maxDistance,
                min: 1,
                max: 12,
                divisions: 11,
                activeColor: AppColors.green,
                onChanged: (v) => setSheet(() => s.setMaxDistance(v)),
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: s.socialOnly,
                activeThumbColor: AppColors.green,
                title: const Text('Hanya sesi social', style: T.bodyStrong),
                subtitle: const Text('Sembunyikan training & kompetisi', style: T.small),
                onChanged: (_) => setSheet(s.toggleSocialOnly),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Reset',
                      kind: BtnKind.outline,
                      onTap: () {
                        s.clearFilters();
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Lihat ${s.visibleMeets.length} meet',
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createMeet(BuildContext context) {
    final title = TextEditingController();
    final venue = TextEditingController(text: 'USC Thanh My Loi');
    final price = TextEditingController(text: 'Rp100k');
    var day = appState.dayIndex;
    var hour = 19;
    var capacity = 16;
    var tag = 'Social';
    var level = 'Semua level';

    showAppSheet(
      context,
      title: 'Buat meet baru',
      subtitle: 'Tersimpan di database dan langsung muncul di Discover.',
      child: StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppField(controller: title, label: 'Judul', hint: 'Mis. Sunset Rally 🎾', autofocus: true),
              const SizedBox(height: 14),
              AppField(controller: venue, label: 'Venue', hint: 'Nama lapangan'),
              const SizedBox(height: 14),
              AppField(controller: price, label: 'Harga', hint: 'Rp100k'),
              const SizedBox(height: 18),
              Text('Hari', style: T.caps.copyWith(color: AppColors.ink70)),
              const SizedBox(height: 9),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final d = appState.today.add(Duration(days: i));
                    final on = i == day;
                    return GestureDetector(
                      onTap: () => setSheet(() => day = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: on ? AppColors.ink : Colors.white,
                          borderRadius: R.pill,
                          border: Border.all(color: on ? AppColors.ink : AppColors.hairline),
                        ),
                        alignment: Alignment.center,
                        child: Text('${_dayNames[d.weekday - 1]} ${d.day}',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: on ? Colors.white : AppColors.ink70)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Jam mulai', style: T.caps.copyWith(color: AppColors.ink70)),
                  const Spacer(),
                  Text('$hour:00', style: T.bodyStrong),
                ],
              ),
              Slider(
                value: hour.toDouble(),
                min: 6,
                max: 22,
                divisions: 16,
                activeColor: AppColors.green,
                onChanged: (v) => setSheet(() => hour = v.round()),
              ),
              Row(
                children: [
                  Text('Kapasitas', style: T.caps.copyWith(color: AppColors.ink70)),
                  const Spacer(),
                  Text('$capacity orang', style: T.bodyStrong),
                ],
              ),
              Slider(
                value: capacity.toDouble(),
                min: 4,
                max: 32,
                divisions: 14,
                activeColor: AppColors.green,
                onChanged: (v) => setSheet(() => capacity = v.round()),
              ),
              const SizedBox(height: 6),
              Text('Tipe', style: T.caps.copyWith(color: AppColors.ink70)),
              const SizedBox(height: 9),
              ChoiceRow<String>(
                options: const ['Social', 'Training', 'Comp'],
                value: tag,
                labelOf: (v) => v,
                onChanged: (v) => setSheet(() => tag = v),
              ),
              const SizedBox(height: 16),
              Text('Level', style: T.caps.copyWith(color: AppColors.ink70)),
              const SizedBox(height: 9),
              ChoiceRow<String>(
                options: const ['Semua level', 'Beginner', '2.5 - 3.5', '3.0+'],
                value: level,
                labelOf: (v) => v,
                onChanged: (v) => setSheet(() => level = v),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Buat meet',
                icon: Icons.add_rounded,
                onTap: () async {
                  if (title.text.trim().isEmpty) {
                    toast(ctx, 'Judul meet belum diisi');
                    return;
                  }
                  final d = appState.today.add(Duration(days: day));
                  final meet = await appState.createMeet(
                    title: title.text,
                    venue: venue.text,
                    start: DateTime(d.year, d.month, d.day, hour),
                    durationMin: 120,
                    capacity: capacity,
                    tag: tag,
                    priceLabel: price.text.trim().isEmpty ? 'Gratis' : price.text.trim(),
                    level: level,
                  );
                  appState.setDay(day);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  toast(context, 'Meet "${meet.title}" dibuat', icon: Icons.check_circle_rounded);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
