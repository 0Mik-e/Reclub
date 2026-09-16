import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_page.dart';

class CompetePage extends StatefulWidget {
  const CompetePage({super.key});

  @override
  State<CompetePage> createState() => _CompetePageState();
}

class _CompetePageState extends State<CompetePage> {
  int _tab = 3;
  int _result = 1;
  String _pool = 'A';

  static const _tabs = ['DETAIL', 'PESERTA', 'MATCH', 'HASIL', 'DISKUSI'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.canvas,
        body: Column(
          children: [
            _hero(context),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  UnderlineTabs(
                    items: _tabs,
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                ],
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => _details(context),
                1 => _participants(context),
                2 => _matches(context),
                3 => _results(context),
                _ => const ChatPage(embedded: true, threadId: 't2'),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------- hero
  Widget _hero(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.inkGradient),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.yellow, borderRadius: R.pill),
                child: const Text('LIVE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: AppColors.ink)),
              ),
              const SizedBox(width: 8),
              Text('KOMPETISI · ${appState.city.toUpperCase()}',
                  style: T.caps.copyWith(color: Colors.white54)),
              const Spacer(),
              CircleIconButton(
                icon: Icons.ios_share_rounded,
                size: 34,
                bg: Colors.white.withValues(alpha: 0.14),
                fg: Colors.white,
                border: false,
                onTap: () => toast(context, 'Link kompetisi disalin', icon: Icons.link_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('VFFL SEASON 4',
              style: TextStyle(
                  fontSize: 28, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -0.8, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Playoffs · 9 tim · ${appState.compTeams.length * 4} pemain',
              style: T.small.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _heroStat('${appState.poolMatches.length}', 'MATCH')),
              _heroDivider(),
              Expanded(child: _heroStat('${appState.bracket.length}', 'PLAYOFF')),
              _heroDivider(),
              Expanded(child: _heroStat('2', 'GRUP')),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() {
                  _tab = 3;
                  _result = 2;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.yellow, borderRadius: R.pill),
                  child: const Text('Lihat bagan',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _heroStat(String v, String l) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(l,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white38)),
        ],
      );

  static Widget _heroDivider() => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.white.withValues(alpha: 0.14),
      );

  // ---------------------------------------------------------------- details
  Widget _details(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TENTANG TURNAMEN', style: T.caps),
              const SizedBox(height: 10),
              const Text(
                'VFFL Season 4 mempertemukan 9 tim dari klub-klub Jakarta. Babak pool dimainkan '
                'dengan sistem setengah kompetisi, dua tim teratas tiap pool lolos ke semifinal.',
                style: T.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            children: [
              _row(Icons.event_rounded, 'Jadwal', '12 – 20 Okt 2026'),
              const Divider(height: 22, color: AppColors.hairline),
              _row(Icons.place_outlined, 'Venue', 'GBK Arena, Gelora'),
              const Divider(height: 22, color: AppColors.hairline),
              _row(Icons.groups_rounded, 'Format', 'Pool + Playoff'),
              const Divider(height: 22, color: AppColors.hairline),
              _row(Icons.payments_outlined, 'Biaya tim', 'Rp750k'),
              const Divider(height: 22, color: AppColors.hairline),
              _row(Icons.emoji_events_outlined, 'Hadiah', 'Rp10jt + trofi'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          color: AppColors.cream,
          shadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rule_rounded, size: 18, color: AppColors.ink),
                  const SizedBox(width: 8),
                  Text('PERATURAN', style: T.caps.copyWith(color: AppColors.ink)),
                ],
              ),
              const SizedBox(height: 10),
              for (final r in const [
                'Game sampai 21 poin, menang selisih 2.',
                'Menang pool = 3 poin, kalah = 0.',
                'Seri poin diputus oleh selisih poin.',
                'Tim wajib hadir 15 menit sebelum jadwal.',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: T.body),
                      Expanded(child: Text(r, style: T.body.copyWith(color: AppColors.ink70))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Daftarkan tim',
          icon: Icons.add_rounded,
          onTap: () => toast(context, 'Pendaftaran tim dibuka lagi Season 5', icon: Icons.info_outline_rounded),
        ),
      ],
    );
  }

  static Widget _row(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 12),
          Text(label, style: T.label),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: T.bodyStrong, overflow: TextOverflow.ellipsis)),
        ],
      );

  // ----------------------------------------------------------- participants
  Widget _participants(BuildContext context) {
    final pools = <String, List<CompTeam>>{};
    for (final t in appState.compTeams) {
      pools.putIfAbsent(t.pool, () => []).add(t);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final e in pools.entries) ...[
          Row(
            children: [
              Text('POOL ${e.key}', style: T.caps.copyWith(color: AppColors.ink)),
              const Spacer(),
              Text('${e.value.length} tim', style: T.small),
            ],
          ),
          const SizedBox(height: 10),
          for (final t in e.value)
            SectionCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Avatar(label: t.name, size: 42, square: true, bold: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.title),
                        const SizedBox(height: 3),
                        Text('Kode ${t.code} · 4 pemain', style: T.small),
                      ],
                    ),
                  ),
                  Tag('POOL ${t.pool}', color: AppColors.blue, bg: AppColors.blueSoft, dense: true),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------- matches
  Widget _matches(BuildContext context) {
    return Column(
      children: [
        _poolSwitch(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              for (final m in appState.poolMatches.where((m) => m.pool == _pool))
                _poolMatchCard(context, m),
              const SizedBox(height: 8),
              Text('Ketuk kartu untuk mengubah skor. Klasemen pool ikut ter-update.',
                  textAlign: TextAlign.center, style: T.small),
            ],
          ),
        ),
      ],
    );
  }

  Widget _poolSwitch() {
    final pools = appState.compTeams.map((t) => t.pool).toSet().toList()..sort();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: PillSwitch(
        items: pools.map((p) => 'Pool $p').toList(),
        index: pools.indexOf(_pool).clamp(0, pools.length - 1),
        onChanged: (i) => setState(() => _pool = pools[i]),
      ),
    );
  }

  Widget _poolMatchCard(BuildContext context, PoolMatch m) {
    final aWin = m.scoreA > m.scoreB;
    return GestureDetector(
      onTap: () => _editPoolScore(context, m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: R.lg, boxShadow: Shadows.card),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Avatar(label: m.a, size: 30, square: true),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(m.a,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.bodyStrong.copyWith(color: aWin ? AppColors.ink : AppColors.muted)),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.chip, borderRadius: R.sm),
              child: Text('${m.scoreA} : ${m.scoreB}', style: T.num.copyWith(fontSize: 13.5)),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(m.b,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.bodyStrong.copyWith(color: aWin ? AppColors.muted : AppColors.ink)),
                  ),
                  const SizedBox(width: 9),
                  Avatar(label: m.b, size: 30, square: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editPoolScore(BuildContext context, PoolMatch m) {
    var a = m.scoreA;
    var b = m.scoreB;
    showAppSheet(
      context,
      title: 'Skor pool ${m.pool}',
      subtitle: '${m.a} vs ${m.b}',
      child: StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _stepper(m.a, a, (v) => setSheet(() => a = v)),
              const SizedBox(height: 12),
              _stepper(m.b, b, (v) => setSheet(() => b = v)),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Simpan skor',
                onTap: () {
                  appState.setPoolScore(m.id, a, b);
                  Navigator.pop(context);
                  toast(context, 'Klasemen pool ${m.pool} diperbarui', icon: Icons.check_circle_rounded);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _stepper(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Avatar(label: label, size: 34, square: true),
        const SizedBox(width: 12),
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.bodyStrong)),
        CircleIconButton(
          icon: Icons.remove_rounded,
          size: 34,
          bg: AppColors.chip,
          border: false,
          onTap: value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 46,
          child: Text('$value', textAlign: TextAlign.center, style: T.num.copyWith(fontSize: 18)),
        ),
        CircleIconButton(
          icon: Icons.add_rounded,
          size: 34,
          bg: AppColors.ink,
          fg: Colors.white,
          border: false,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- results
  Widget _results(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: PillSwitch(
            items: const ['Juara', 'Pool', 'Playoff', 'Statistik'],
            index: _result,
            onChanged: (i) => setState(() => _result = i),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.hairline),
        Expanded(
          child: switch (_result) {
            0 => _awards(context),
            1 => _pools(context),
            2 => _playoffs(context),
            _ => _stats(context),
          },
        ),
      ],
    );
  }

  Widget _awards(BuildContext context) {
    final finals = appState.bracket.where((b) => b.stage == 'FINALS').toList();
    final third = appState.bracket.where((b) => b.stage == 'THIRD PLACE').toList();
    final champ = finals.isEmpty ? '—' : (finals.first.aWins ? finals.first.teamA : finals.first.teamB);
    final runner = finals.isEmpty ? '—' : (finals.first.aWins ? finals.first.teamB : finals.first.teamA);
    final bronze = third.isEmpty ? '—' : (third.first.aWins ? third.first.teamA : third.first.teamB);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: R.xl, boxShadow: Shadows.raised),
          child: Column(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 42, color: AppColors.ink),
              const SizedBox(height: 10),
              Text('JUARA VFFL SEASON 4', style: T.caps.copyWith(color: AppColors.ink70)),
              const SizedBox(height: 6),
              Text(champ,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.ink)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _podium('2', runner, const Color(0xFFD7DBE3))),
            const SizedBox(width: 12),
            Expanded(child: _podium('3', bronze, const Color(0xFFE8B37A))),
          ],
        ),
        const SizedBox(height: 18),
        Text('MVP & PENGHARGAAN', style: T.caps),
        const SizedBox(height: 10),
        for (final a in const [
          ['MVP Turnamen', 'User', Icons.star_rounded],
          ['Top Scorer', 'Rina Ayu', Icons.local_fire_department_rounded],
          ['Best Defense', 'Bayu Pratama', Icons.shield_rounded],
          ['Fair Play', 'Sunrise Smash', Icons.handshake_rounded],
        ])
          SectionCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: R.md),
                  child: Icon(a[2] as IconData, size: 19, color: AppColors.yellowDeep),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a[0] as String, style: T.small),
                      const SizedBox(height: 2),
                      Text(a[1] as String, style: T.title),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Widget _podium(String place, String team, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: R.lg, boxShadow: Shadows.card),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(place, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
            ),
            const SizedBox(height: 10),
            Text(team, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.title),
          ],
        ),
      );

  Widget _pools(BuildContext context) {
    final pools = appState.compTeams.map((t) => t.pool).toSet().toList()..sort();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final p in pools) ...[
          Text('KLASEMEN POOL $p', style: T.caps.copyWith(color: AppColors.ink)),
          const SizedBox(height: 10),
          SectionCard(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.only(bottom: 18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                  decoration: const BoxDecoration(
                      color: AppColors.chip, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: Row(
                    children: [
                      SizedBox(width: 22, child: Text('#', style: T.caps)),
                      Expanded(child: Text('TIM', style: T.caps)),
                      SizedBox(width: 26, child: Text('W', textAlign: TextAlign.center, style: T.caps)),
                      SizedBox(width: 26, child: Text('L', textAlign: TextAlign.center, style: T.caps)),
                      SizedBox(width: 40, child: Text('+/-', textAlign: TextAlign.right, style: T.caps)),
                      SizedBox(width: 34, child: Text('PTS', textAlign: TextAlign.right, style: T.caps)),
                    ],
                  ),
                ),
                for (final (i, row) in appState.poolTable(p).indexed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: i < 2 ? AppColors.greenSoft.withValues(alpha: 0.5) : null,
                      border: i == 0 ? null : const Border(top: BorderSide(color: AppColors.hairline)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text('${i + 1}',
                              style: T.small.copyWith(
                                  fontWeight: FontWeight.w800, color: i < 2 ? AppColors.greenDark : AppColors.muted)),
                        ),
                        Expanded(
                          child: Text(row['name'] as String,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: T.bodyStrong),
                        ),
                        SizedBox(width: 26, child: Text('${row['w']}', textAlign: TextAlign.center, style: T.label)),
                        SizedBox(width: 26, child: Text('${row['l']}', textAlign: TextAlign.center, style: T.label)),
                        SizedBox(
                          width: 40,
                          child: Text(
                            (row['diff'] as int) >= 0 ? '+${row['diff']}' : '${row['diff']}',
                            textAlign: TextAlign.right,
                            style: T.small.copyWith(
                                color: (row['diff'] as int) >= 0 ? AppColors.ink70 : AppColors.red,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(
                          width: 34,
                          child: Text('${row['pts']}', textAlign: TextAlign.right, style: T.num.copyWith(fontSize: 13.5)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        Row(
          children: [
            Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text('Dua besar tiap pool lolos semifinal', style: T.small)),
          ],
        ),
      ],
    );
  }

  Widget _playoffs(BuildContext context) {
    final stages = <String, List<BracketSlot>>{};
    for (final b in appState.bracket) {
      stages.putIfAbsent(b.stage, () => []).add(b);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final e in stages.entries) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: e.key == 'FINALS' ? AppColors.yellow : AppColors.chip, borderRadius: R.pill),
                child: Text(e.key,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: e.key == 'FINALS' ? AppColors.ink : AppColors.muted)),
              ),
              const Spacer(),
              Text(e.value.first.time, style: T.small),
            ],
          ),
          const SizedBox(height: 10),
          for (final b in e.value)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: R.lg, boxShadow: Shadows.card),
              child: Column(
                children: [
                  _bracketSide(b.seedA, b.teamA, b.scoreA, b.aWins, true),
                  Container(height: 1, color: AppColors.hairline, margin: const EdgeInsets.symmetric(horizontal: 14)),
                  _bracketSide(b.seedB, b.teamB, b.scoreB, !b.aWins, false),
                ],
              ),
            ),
        ],
      ],
    );
  }

  static Widget _bracketSide(int seed, String team, int score, bool win, bool top) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: win ? AppColors.greenSoft.withValues(alpha: 0.45) : null,
        borderRadius: BorderRadius.vertical(
          top: top ? const Radius.circular(20) : Radius.zero,
          bottom: top ? Radius.zero : const Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text('$seed', style: T.small.copyWith(fontWeight: FontWeight.w800))),
          Avatar(label: team, size: 30, square: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(team,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.bodyStrong.copyWith(color: win ? AppColors.ink : AppColors.muted)),
          ),
          if (win) const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.green),
          const SizedBox(width: 8),
          Text('$score', style: T.num.copyWith(fontSize: 16, color: win ? AppColors.ink : AppColors.muted)),
        ],
      ),
    );
  }

  Widget _stats(BuildContext context) {
    final played = appState.poolMatches.length;
    final points = appState.poolMatches.fold<int>(0, (s, m) => s + m.scoreA + m.scoreB);
    final biggest = appState.poolMatches.isEmpty
        ? null
        : appState.poolMatches.reduce((a, b) =>
            (a.scoreA - a.scoreB).abs() >= (b.scoreA - b.scoreB).abs() ? a : b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(child: StatTile(value: '$played', label: 'Match pool')),
            Expanded(child: StatTile(value: '$points', label: 'Total poin', color: AppColors.blue)),
            Expanded(
                child: StatTile(
                    value: (points / (played == 0 ? 1 : played)).toStringAsFixed(1),
                    label: 'Rata/match',
                    color: AppColors.greenDark)),
          ],
        ),
        const SizedBox(height: 16),
        if (biggest != null) ...[
          Text('SELISIH TERBESAR', style: T.caps),
          const SizedBox(height: 10),
          SectionCard(
            child: Row(
              children: [
                Avatar(label: biggest.a, size: 38, square: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${biggest.a} vs ${biggest.b}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: T.title),
                      const SizedBox(height: 3),
                      Text('Pool ${biggest.pool} · selisih ${(biggest.scoreA - biggest.scoreB).abs()}',
                          style: T.small),
                    ],
                  ),
                ),
                Text('${biggest.scoreA}–${biggest.scoreB}', style: T.num.copyWith(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        Text('PEROLEHAN POIN TIM', style: T.caps),
        const SizedBox(height: 10),
        SectionCard(
          child: Column(
            children: [
              for (final row in _allTeamRows()) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(row['name'] as String,
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: T.bodyStrong),
                          ),
                          Text('${row['pts']} pts', style: T.small.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ProgressBar(value: (row['pts'] as int) / 12, color: AppColors.blue),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _allTeamRows() {
    final pools = appState.compTeams.map((t) => t.pool).toSet().toList()..sort();
    final rows = <Map<String, dynamic>>[];
    for (final p in pools) {
      rows.addAll(appState.poolTable(p));
    }
    rows.sort((a, b) => (b['pts'] as int).compareTo(a['pts'] as int));
    return rows;
  }
}
