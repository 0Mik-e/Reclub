import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_page.dart';
import 'discover_page.dart' show timeLabel, dateLabel;

class MeetPage extends StatefulWidget {
  const MeetPage({super.key, required this.meetId, this.showBack = true});
  final String meetId;
  final bool showBack;

  @override
  State<MeetPage> createState() => _MeetPageState();
}

class _MeetPageState extends State<MeetPage> {
  int _tab = 0;
  int _matchTab = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final m = appState.meetById(widget.meetId) ?? appState.featuredMeet;
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: Column(
            children: [
              _header(context, m),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    UnderlineTabs(
                      items: const ['DETAIL', 'PESERTA', 'MATCH', 'CHAT'],
                      index: _tab,
                      spread: true,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                  ],
                ),
              ),
              Expanded(
                child: switch (_tab) {
                  0 => _details(context, m),
                  1 => _participants(context, m),
                  2 => _matches(context),
                  _ => const ChatPage(embedded: true, threadId: 't2'),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------- header
  Widget _header(BuildContext context, Meet m) {
    final joined = m.joined;
    return Container(
      decoration: BoxDecoration(gradient: joined ? AppColors.greenGradient : AppColors.brandGradient),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.showBack)
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  size: 34,
                  bg: Colors.white.withValues(alpha: 0.28),
                  fg: joined ? Colors.white : AppColors.ink,
                  border: false,
                  onTap: () => Navigator.pop(context),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.28), borderRadius: R.pill),
                  child: Text('MEET SAYA',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: joined ? Colors.white : AppColors.ink)),
                ),
              const Spacer(),
              CircleIconButton(
                icon: Icons.ios_share_rounded,
                size: 34,
                bg: Colors.white.withValues(alpha: 0.28),
                fg: joined ? Colors.white : AppColors.ink,
                border: false,
                onTap: () => toast(context, 'Tautan disalin', icon: Icons.link_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(m.clubName,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: joined ? Colors.white70 : AppColors.ink70)),
          const SizedBox(height: 6),
          Text(m.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: joined ? Colors.white : AppColors.ink)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: joined ? Colors.white70 : AppColors.ink70),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${dateLabel(m.start)} · ${timeLabel(m.start)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: joined ? Colors.white : AppColors.ink70)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: joined ? 'Kamu ikut ✓' : (m.full ? 'Meet penuh' : 'Gabung meet'),
                  kind: joined ? BtnKind.dark : (m.full ? BtnKind.outline : BtnKind.dark),
                  onTap: m.full && !joined
                      ? null
                      : () async {
                          final ok = await appState.toggleJoinMeet(m.id);
                          if (!context.mounted) return;
                          toast(context, ok ? (m.joined ? 'Berhasil gabung!' : 'Kamu keluar dari meet') : 'Meet penuh',
                              icon: Icons.check_circle_rounded);
                        },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: Colors.white, borderRadius: R.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${m.taken}/${m.capacity}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    Text('slot', style: T.small.copyWith(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- details
  Widget _details(BuildContext context, Meet m) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SectionCard(
          child: Column(
            children: [
              _infoRow(Icons.place_outlined, 'Venue', m.venue),
              const Divider(height: 22, color: AppColors.hairline),
              _infoRow(Icons.schedule_rounded, 'Waktu',
                  '${timeLabel(m.start)} – ${timeLabel(m.end)} (${m.durationMin} menit)'),
              const Divider(height: 22, color: AppColors.hairline),
              _infoRow(Icons.payments_outlined, 'Biaya', '${m.priceLabel} per orang'),
              const Divider(height: 22, color: AppColors.hairline),
              _infoRow(Icons.bar_chart_rounded, 'Level', m.level),
              const Divider(height: 22, color: AppColors.hairline),
              _infoRow(Icons.person_outline_rounded, 'Host', m.host),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('KAPASITAS', style: T.caps),
                  const Spacer(),
                  Text('${m.spotsLeft} slot tersisa',
                      style: T.small.copyWith(
                          color: m.spotsLeft <= 3 ? AppColors.orange : AppColors.muted,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              ProgressBar(
                value: m.taken / m.capacity,
                height: 8,
                color: m.full ? AppColors.orange : AppColors.green,
              ),
              const SizedBox(height: 12),
              AvatarStack(
                labels: appState.members.take(m.taken.clamp(0, 8)).map((p) => p.name).toList(),
                size: 30,
                max: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FORMAT PERMAINAN', style: T.caps),
              const SizedBox(height: 10),
              const Text(
                'Americano — pasangan diacak tiap ronde, poin individu diakumulasi. '
                'Setiap game dimainkan sampai 11 poin, menang minimal selisih 2.',
                style: T.body,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: StatTile(value: '${appState.matches.length}', label: 'Total match')),
                  Expanded(
                      child: StatTile(
                          value: '${appState.matches.where((x) => x.played).length}',
                          label: 'Selesai',
                          color: AppColors.greenDark)),
                  Expanded(
                      child: StatTile(
                          value: '${appState.matches.map((x) => x.round).toSet().length}', label: 'Ronde')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          color: AppColors.lavender,
          shadow: false,
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 19, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Datang 10 menit lebih awal untuk pemanasan. Bawa paddle sendiri kalau ada.',
                    style: T.small.copyWith(color: AppColors.ink70)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 12),
        Text(label, style: T.label),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value, textAlign: TextAlign.right, style: T.bodyStrong),
        ),
      ],
    );
  }

  // ----------------------------------------------------------- participants
  Widget _participants(BuildContext context, Meet m) {
    final list = appState.members;
    final teams = <String, List<Player>>{};
    for (final p in list) {
      teams.putIfAbsent(p.team ?? 'Tanpa tim', () => []).add(p);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Text('${list.length} peserta terdaftar', style: T.caps),
            const Spacer(),
            GestureDetector(
              onTap: () => toast(context, 'Tautan disalin', icon: Icons.link_rounded),
              child: const Tag('Undang', color: AppColors.blue, bg: AppColors.blueSoft, icon: Icons.person_add_alt),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final entry in teams.entries) ...[
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: _teamColor(entry.key), borderRadius: R.pill),
              ),
              const SizedBox(width: 8),
              Text('TIM ${entry.key.toUpperCase()}', style: T.caps.copyWith(color: AppColors.ink)),
              const Spacer(),
              Text('${entry.value.length} orang', style: T.small),
            ],
          ),
          const SizedBox(height: 8),
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < entry.value.length; i++) ...[
                  if (i > 0)
                    const Padding(
                        padding: EdgeInsets.only(left: 60), child: Divider(height: 1, color: AppColors.hairline)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: Avatar(label: entry.value[i].name, size: 38),
                    title: Text(entry.value[i].name, style: T.title),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(entry.value[i].level, style: T.small),
                    ),
                    trailing: entry.value[i].name == appState.me?.name
                        ? const Tag('Kamu', color: AppColors.greenDark, bg: AppColors.greenSoft, dense: true)
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  static Color _teamColor(String team) => switch (team) {
        'Merah' => AppColors.red,
        'Biru' => AppColors.blue,
        'Kuning' => AppColors.yellowDeep,
        'Hijau' => AppColors.green,
        _ => AppColors.muted,
      };

  // ---------------------------------------------------------------- matches
  Widget _matches(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: PillSwitch(
            items: const ['Klasemen', 'Semua match', 'Match saya'],
            index: _matchTab,
            onChanged: (i) => setState(() => _matchTab = i),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.hairline),
        Expanded(
          child: switch (_matchTab) {
            0 => _standings(context),
            1 => _matchList(context, appState.matches),
            _ => _matchList(context, appState.myMatches, mineOnly: true),
          },
        ),
      ],
    );
  }

  Widget _standings(BuildContext context) {
    final rows = appState.standings;
    if (rows.isEmpty) {
      return const EmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'Belum ada skor',
        subtitle: 'Isi skor di tab "Semua match" — klasemen langsung terhitung.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: const BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 26, child: Text('#', style: T.caps)),
                    const SizedBox(width: 40),
                    Expanded(child: Text('PEMAIN', style: T.caps)),
                    SizedBox(width: 30, child: Text('M', textAlign: TextAlign.center, style: T.caps)),
                    SizedBox(width: 30, child: Text('W', textAlign: TextAlign.center, style: T.caps)),
                    SizedBox(width: 42, child: Text('+/-', textAlign: TextAlign.right, style: T.caps)),
                  ],
                ),
              ),
              for (var i = 0; i < rows.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: rows[i].player == appState.me?.firstName ? AppColors.greenSoft : null,
                    border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.hairline)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: i < 3
                            ? Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: [AppColors.yellow, const Color(0xFFD7DBE3), const Color(0xFFE8B37A)][i],
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.ink)),
                              )
                            : Text('${i + 1}', style: T.small.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 10),
                      Avatar(label: rows[i].player, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(rows[i].player,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: T.bodyStrong),
                      ),
                      SizedBox(width: 30, child: Text('${rows[i].played}', textAlign: TextAlign.center, style: T.label)),
                      SizedBox(
                          width: 30,
                          child: Text('${rows[i].wins}',
                              textAlign: TextAlign.center,
                              style: T.label.copyWith(color: AppColors.greenDark, fontWeight: FontWeight.w800))),
                      SizedBox(
                        width: 42,
                        child: Text(
                          rows[i].diff >= 0 ? '+${rows[i].diff}' : '${rows[i].diff}',
                          textAlign: TextAlign.right,
                          style: T.num.copyWith(
                              fontSize: 13, color: rows[i].diff >= 0 ? AppColors.ink : AppColors.red),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Klasemen dihitung ulang otomatis setiap skor disimpan.',
            textAlign: TextAlign.center, style: T.small),
      ],
    );
  }

  Widget _matchList(BuildContext context, List<GameMatch> list, {bool mineOnly = false}) {
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.sports_tennis_rounded,
        title: mineOnly ? 'Belum ada match kamu' : 'Belum ada match',
        subtitle: mineOnly
            ? 'Match yang memuat nama "${appState.me?.firstName}" akan tampil di sini.'
            : 'Jadwal match belum dibuat.',
      );
    }
    final rounds = <int, List<GameMatch>>{};
    for (final m in list) {
      rounds.putIfAbsent(m.round, () => []).add(m);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final entry in rounds.entries) ...[
          Row(
            children: [
              Text('RONDE ${entry.key}', style: T.caps.copyWith(color: AppColors.ink)),
              const SizedBox(width: 8),
              if (entry.value.every((m) => m.played))
                const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.green),
              const Spacer(),
              GestureDetector(
                onTap: () => _roundMenu(context, entry.key, entry.value),
                child: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final m in entry.value) _matchCard(context, m),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _matchCard(BuildContext context, GameMatch m) {
    return GestureDetector(
      onTap: () => _editScore(context, m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: R.lg, boxShadow: Shadows.card),
        child: Column(
          children: [
            Row(
              children: [
                Text(m.court, style: T.caps),
                const Spacer(),
                if (m.played)
                  const Tag('Selesai', color: AppColors.greenDark, bg: AppColors.greenSoft, dense: true)
                else
                  const Tag('Belum main', dense: true),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined, size: 15, color: AppColors.faint),
              ],
            ),
            const SizedBox(height: 12),
            _side(m.sideA, m.scoreA, m.played && m.scoreA! > m.scoreB!),
            const SizedBox(height: 10),
            const DottedLine(),
            const SizedBox(height: 10),
            _side(m.sideB, m.scoreB, m.played && m.scoreB! > m.scoreA!),
          ],
        ),
      ),
    );
  }

  Widget _side(List<String> players, int? score, bool winner) {
    return Row(
      children: [
        AvatarStack(labels: players, size: 30, max: 2),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            players.join(' / '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: T.bodyStrong.copyWith(
              color: winner ? AppColors.ink : AppColors.ink70,
              fontWeight: winner ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 34,
          decoration: BoxDecoration(
            color: winner ? AppColors.ink : AppColors.chip,
            borderRadius: R.sm,
          ),
          alignment: Alignment.center,
          child: Text(
            score?.toString() ?? '–',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: winner ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  void _editScore(BuildContext context, GameMatch m) {
    final a = TextEditingController(text: m.scoreA?.toString() ?? '');
    final b = TextEditingController(text: m.scoreB?.toString() ?? '');
    showAppSheet(
      context,
      title: 'Input skor',
      subtitle: '${m.court} · Ronde ${m.round}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _scoreField(m.labelA, a),
            const SizedBox(height: 12),
            _scoreField(m.labelB, b),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Hapus skor',
                    kind: BtnKind.outline,
                    onTap: () {
                      appState.setScore(m.id, null, null);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Simpan',
                    onTap: () {
                      final av = int.tryParse(a.text.trim());
                      final bv = int.tryParse(b.text.trim());
                      if (av == null || bv == null) {
                        toast(context, 'Isi kedua skor dengan angka');
                        return;
                      }
                      appState.setScore(m.id, av, bv);
                      Navigator.pop(context);
                      toast(context, 'Skor tersimpan, klasemen diperbarui',
                          icon: Icons.check_circle_rounded);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _scoreField(String label, TextEditingController c) {
    return Row(
      children: [
        AvatarStack(labels: label.split('/'), size: 30, max: 2),
        const SizedBox(width: 12),
        Expanded(child: Text(label.replaceAll('/', ' / '), style: T.bodyStrong)),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: '0',
              filled: true,
              fillColor: AppColors.canvas,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: R.md, borderSide: const BorderSide(color: AppColors.hairline)),
              enabledBorder: OutlineInputBorder(borderRadius: R.md, borderSide: const BorderSide(color: AppColors.hairline)),
              focusedBorder: OutlineInputBorder(borderRadius: R.md, borderSide: const BorderSide(color: AppColors.green, width: 1.6)),
            ),
          ),
        ),
      ],
    );
  }

  void _roundMenu(BuildContext context, int round, List<GameMatch> list) {
    showAppSheet(
      context,
      title: 'Ronde $round',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.auto_fix_high_rounded, size: 20),
            title: const Text('Isi skor contoh', style: T.bodyStrong),
            subtitle: const Text('Mengisi 11-x agar klasemen langsung terlihat', style: T.small),
            onTap: () {
              Navigator.pop(context);
              for (var i = 0; i < list.length; i++) {
                appState.setScore(list[i].id, 11, 5 + i * 2);
              }
              toast(context, 'Skor contoh ronde $round diisi');
            },
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded, size: 20, color: AppColors.red),
            title: const Text('Reset skor ronde',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.red)),
            onTap: () {
              Navigator.pop(context);
              for (final m in list) {
                appState.setScore(m.id, null, null);
              }
              toast(context, 'Skor ronde $round dihapus');
            },
          ),
        ],
      ),
    );
  }
}