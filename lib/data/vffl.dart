import 'package:flutter/material.dart';

import 'models.dart';

/// Data statis kompetisi VFFL (Season 3, 4, 5) dan helper klasemen.
///
/// Season 4 (yang sedang berlangsung) disimpan di SQLite lewat `AppState`
/// supaya skornya bisa diedit. Season 3 (selesai) dan Season 5 (belum mulai)
/// bersifat statis sehingga datanya ada di file ini.

enum SeasonStatus { upcoming, live, ended }

/// Penghargaan individu pada musim yang sudah selesai.
class SeasonAward {
  const SeasonAward({required this.icon, required this.title, required this.name});
  final IconData icon;
  final String title;
  final String name;
}

/// Informasi deskriptif satu musim VFFL.
class SeasonMeta {
  const SeasonMeta({
    required this.season,
    required this.title,
    required this.city,
    required this.status,
    required this.about,
    required this.schedule,
    required this.venue,
    required this.feeAmount,
    required this.prize,
    required this.rules,
    this.archive = const [],
    this.awards = const [],
  });

  final int season;
  final String title;
  final String city;
  final SeasonStatus status;
  final String about;
  final String schedule;
  final String venue;

  /// Biaya pendaftaran per tim dalam rupiah.
  final int feeAmount;
  final String prize;
  final List<String> rules;

  /// Diskusi yang diarsipkan (penulis, isi). Hanya terisi untuk musim selesai.
  final List<(String, String)> archive;

  /// MVP & penghargaan lain. Hanya terisi untuk musim selesai.
  final List<SeasonAward> awards;

  String get feeLabel => rupiah(feeAmount);
}

/// Format angka rupiah dengan pemisah ribuan titik, mis. `Rp1.600.000`.
String rupiah(int amount) {
  final digits = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}Rp$buf';
}

/// Menghitung klasemen satu pool.
///
/// Setiap baris berisi `name`, `code`, `w` (menang), `l` (kalah), `diff`
/// (selisih skor) dan `pts` (3 poin per kemenangan). Urutan: poin, selisih
/// skor, lalu nama.
List<Map<String, dynamic>> poolTableOf(
  List<CompTeam> teams,
  List<PoolMatch> matches,
  String pool,
) {
  final rows = <String, Map<String, dynamic>>{
    for (final t in teams.where((t) => t.pool == pool))
      t.name: <String, dynamic>{'name': t.name, 'code': t.code, 'w': 0, 'l': 0, 'diff': 0, 'pts': 0},
  };

  for (final m in matches.where((m) => m.pool == pool)) {
    final a = rows[m.a];
    final b = rows[m.b];
    if (a == null || b == null) continue;
    a['diff'] = (a['diff'] as int) + m.scoreA - m.scoreB;
    b['diff'] = (b['diff'] as int) + m.scoreB - m.scoreA;
    if (m.scoreA > m.scoreB) {
      a['w'] = (a['w'] as int) + 1;
      b['l'] = (b['l'] as int) + 1;
    } else if (m.scoreB > m.scoreA) {
      b['w'] = (b['w'] as int) + 1;
      a['l'] = (a['l'] as int) + 1;
    }
  }

  final list = rows.values.toList();
  for (final r in list) {
    r['pts'] = (r['w'] as int) * 3;
  }
  list.sort((x, y) {
    final byPts = (y['pts'] as int).compareTo(x['pts'] as int);
    if (byPts != 0) return byPts;
    final byDiff = (y['diff'] as int).compareTo(x['diff'] as int);
    if (byDiff != 0) return byDiff;
    return (x['name'] as String).compareTo(y['name'] as String);
  });
  return list;
}

abstract final class Vffl {
  static SeasonMeta meta(int season) => switch (season) {
        3 => _s3,
        5 => _s5,
        _ => _s4,
      };

  static const List<String> _rules = [
    'Satu tim terdiri dari 4 pemain (maksimal 6 dengan cadangan).',
    'Fase pool dimainkan round-robin; 2 tim teratas tiap pool lolos ke playoff.',
    'Pertandingan sampai 11 poin (rally scoring), selisih minimal 2 poin.',
    'Hasil pool: menang = 3 poin. Jika poin sama, selisih skor menentukan.',
    'Pemain wajib hadir 15 menit sebelum jadwal; keterlambatan lebih dari 10 menit dianggap kalah WO.',
    'Keputusan wasit bersifat final.',
  ];

  // ---------------------------------------------------------------- Season 3
  static const SeasonMeta _s3 = SeasonMeta(
    season: 3,
    title: 'VFFL Season 3',
    city: 'Jakarta',
    status: SeasonStatus.ended,
    about:
        'Musim ketiga VFFL mempertemukan 8 tim dalam dua pool dan playoff empat besar. '
        'Turnamen ini sudah selesai; hasil dan arsip diskusinya masih bisa dilihat.',
    schedule: '18 – 19 Okt 2025',
    venue: 'USC Thanh My Loi, Kebayoran Baru',
    feeAmount: 1200000,
    prize: 'Rp15.000.000 + trofi',
    rules: _rules,
    archive: [
      ('Rina Ayu', 'Terima kasih semua, final tadi seru banget!'),
      ('Dimas Putra', 'Selamat untuk Rajawali. Sampai jumpa di musim berikutnya.'),
      ('Kyle Adhi', 'Jadwal semifinal sempat mundur 20 menit, tolong dicatat untuk panitia.'),
      ('Panitia VFFL', 'Foto dan highlight pertandingan akan diunggah dalam seminggu.'),
    ],
    awards: [
      SeasonAward(icon: Icons.star_rounded, title: 'MVP Turnamen', name: 'Raka Pratama'),
      SeasonAward(icon: Icons.bolt_rounded, title: 'Smash Terbaik', name: 'Dimas Putra'),
      SeasonAward(icon: Icons.shield_rounded, title: 'Pertahanan Terbaik', name: 'Salsa Nur'),
      SeasonAward(icon: Icons.favorite_rounded, title: 'Sportivitas', name: 'Tim Komodo'),
    ],
  );

  static final List<CompTeam> s3Teams = [
    CompTeam(code: 'RJ', name: 'Rajawali', pool: 'A'),
    CompTeam(code: 'KM', name: 'Komodo', pool: 'A'),
    CompTeam(code: 'BT', name: 'Banteng', pool: 'A'),
    CompTeam(code: 'CD', name: 'Cendrawasih', pool: 'A'),
    CompTeam(code: 'EJ', name: 'Elang Jawa', pool: 'B'),
    CompTeam(code: 'MK', name: 'Macan Kumbang', pool: 'B'),
    CompTeam(code: 'GM', name: 'Garuda Muda', pool: 'B'),
    CompTeam(code: 'BD', name: 'Badak', pool: 'B'),
  ];

  static final List<PoolMatch> s3PoolMatches = [
    PoolMatch(id: 's3pm0', pool: 'A', a: 'Rajawali', b: 'Komodo', scoreA: 27, scoreB: 22),
    PoolMatch(id: 's3pm1', pool: 'A', a: 'Rajawali', b: 'Banteng', scoreA: 30, scoreB: 25),
    PoolMatch(id: 's3pm2', pool: 'A', a: 'Rajawali', b: 'Cendrawasih', scoreA: 28, scoreB: 19),
    PoolMatch(id: 's3pm3', pool: 'A', a: 'Komodo', b: 'Banteng', scoreA: 26, scoreB: 24),
    PoolMatch(id: 's3pm4', pool: 'A', a: 'Komodo', b: 'Cendrawasih', scoreA: 29, scoreB: 21),
    PoolMatch(id: 's3pm5', pool: 'A', a: 'Banteng', b: 'Cendrawasih', scoreA: 25, scoreB: 23),
    PoolMatch(id: 's3pm6', pool: 'B', a: 'Macan Kumbang', b: 'Elang Jawa', scoreA: 24, scoreB: 26),
    PoolMatch(id: 's3pm7', pool: 'B', a: 'Macan Kumbang', b: 'Garuda Muda', scoreA: 28, scoreB: 20),
    PoolMatch(id: 's3pm8', pool: 'B', a: 'Macan Kumbang', b: 'Badak', scoreA: 31, scoreB: 18),
    PoolMatch(id: 's3pm9', pool: 'B', a: 'Elang Jawa', b: 'Garuda Muda', scoreA: 27, scoreB: 25),
    PoolMatch(id: 's3pm10', pool: 'B', a: 'Elang Jawa', b: 'Badak', scoreA: 29, scoreB: 22),
    PoolMatch(id: 's3pm11', pool: 'B', a: 'Garuda Muda', b: 'Badak', scoreA: 26, scoreB: 23),
  ];

  static final List<BracketSlot> s3Bracket = [
    BracketSlot(
      id: 's3b1',
      stage: 'SEMI FINALS',
      time: '19 Okt @10:00 AM',
      seedA: 1,
      teamA: 'Rajawali',
      scoreA: 29,
      seedB: 4,
      teamB: 'Macan Kumbang',
      scoreB: 24,
    ),
    BracketSlot(
      id: 's3b2',
      stage: 'SEMI FINALS',
      time: '19 Okt @10:00 AM',
      seedA: 2,
      teamA: 'Elang Jawa',
      scoreA: 27,
      seedB: 3,
      teamB: 'Komodo',
      scoreB: 30,
    ),
    BracketSlot(
      id: 's3b3',
      stage: 'FINALS',
      time: '19 Okt @1:00 PM',
      seedA: 1,
      teamA: 'Rajawali',
      scoreA: 31,
      seedB: 3,
      teamB: 'Komodo',
      scoreB: 27,
    ),
    BracketSlot(
      id: 's3b4',
      stage: 'THIRD PLACE',
      time: '19 Okt @1:00 PM',
      seedA: 2,
      teamA: 'Elang Jawa',
      scoreA: 28,
      seedB: 4,
      teamB: 'Macan Kumbang',
      scoreB: 26,
    ),
  ];

  /// Juara Season 3, diambil dari pertandingan FINALS.
  static String get s3Champion {
    final f = s3Bracket.firstWhere((b) => b.stage == 'FINALS');
    return f.aWins ? f.teamA : f.teamB;
  }

  // ---------------------------------------------------------------- Season 4
  static const SeasonMeta _s4 = SeasonMeta(
    season: 4,
    title: 'VFFL Season 4',
    city: 'Jakarta',
    status: SeasonStatus.live,
    about:
        'Musim keempat VFFL diikuti 9 tim dalam dua pool. Fase pool sudah selesai dan '
        'turnamen kini berada di babak playoff.',
    schedule: '30 Mar – 1 Apr',
    venue: 'USC Thanh My Loi, Kebayoran Baru',
    feeAmount: 1400000,
    prize: 'Rp20.000.000 + trofi',
    rules: _rules,
  );

  // ---------------------------------------------------------------- Season 5
  static const SeasonMeta _s5 = SeasonMeta(
    season: 5,
    title: 'VFFL Season 5',
    city: 'Bandung',
    status: SeasonStatus.upcoming,
    about:
        'Musim kelima VFFL hadir di Bandung. Pendaftaran tim dibuka sekarang; '
        'daftarkan timmu sebelum slot penuh.',
    schedule: '9 – 10 Jan 2027',
    venue: 'GOR Pajajaran, Bandung',
    feeAmount: 1600000,
    prize: 'Rp25.000.000 + trofi',
    rules: _rules,
  );
}