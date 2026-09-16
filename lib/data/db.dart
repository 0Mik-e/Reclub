import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite storage for the whole app. One file on the device
/// (`<databases>/reclub.db`) that holds users, sessions, clubs, meets, matches,
/// chat and every per-user relation (joins, likes, RSVPs, reactions).
class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  Database? _db;
  Database get db => _db!;

  /// File name of the database. Tests override it so parallel suites do not
  /// share one file.
  String fileName = 'reclub.db';

  Future<Database> open() async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, fileName);
    _db = await openDatabase(
      path,
      version: 3,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, _) async {
        await _createSchema(d);
        await _seed(d);
      },
      // The seed is demo content, so an upgrade simply rebuilds it instead of
      // migrating row by row.
      onUpgrade: (d, _, _) async {
        await _dropSchema(d);
        await _createSchema(d);
        await _seed(d);
      },
    );
    await _rollMeetsForward(_db!);
    return _db!;
  }

  /// Wipes the file and rebuilds it from the seed. Used by "Reset data".
  Future<void> reset() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, fileName);
    await _db?.close();
    _db = null;
    await deleteDatabase(path);
    await open();
  }

  static Future<void> _dropSchema(Database d) async {
    final rows = await d.query('sqlite_master', columns: ['name'], where: "type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'");
    final b = d.batch();
    // Works inside the upgrade transaction, unlike `PRAGMA foreign_keys`.
    b.execute('PRAGMA defer_foreign_keys = ON');
    for (final r in rows) {
      b.execute('DROP TABLE IF EXISTS "${r['name']}"');
    }
    await b.commit(noResult: true);
  }

  // ---- password hashing --------------------------------------------------
  static String newSalt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static String hashPassword(String password, String salt) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  // ---- schema ------------------------------------------------------------
  static Future<void> _createSchema(Database d) async {
    final b = d.batch();
    b.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        level TEXT NOT NULL,
        city TEXT NOT NULL,
        sport TEXT NOT NULL,
        provider TEXT NOT NULL DEFAULT 'password',
        bio TEXT DEFAULT '',
        phone TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )''');
    b.execute('CREATE TABLE app_meta (k TEXT PRIMARY KEY, v TEXT NOT NULL)');
    b.execute('''
      CREATE TABLE clubs (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, sport TEXT NOT NULL,
        city TEXT NOT NULL, members INTEGER NOT NULL, about TEXT NOT NULL
      )''');
    b.execute('''
      CREATE TABLE club_members (
        club_id TEXT NOT NULL, user_id TEXT NOT NULL,
        PRIMARY KEY (club_id, user_id)
      )''');
    b.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY, name TEXT NOT NULL,
        level TEXT NOT NULL, team TEXT
      )''');
    b.execute('''
      CREATE TABLE meets (
        id TEXT PRIMARY KEY, club_name TEXT NOT NULL, title TEXT NOT NULL,
        venue TEXT NOT NULL, start TEXT NOT NULL, duration_min INTEGER NOT NULL,
        capacity INTEGER NOT NULL, taken INTEGER NOT NULL, tag TEXT NOT NULL,
        distance_km REAL NOT NULL, price_label TEXT NOT NULL, level TEXT NOT NULL,
        host TEXT NOT NULL, invited INTEGER NOT NULL DEFAULT 0,
        has_gift INTEGER NOT NULL DEFAULT 0
      )''');
    b.execute('''
      CREATE TABLE meet_participants (
        meet_id TEXT NOT NULL, user_id TEXT NOT NULL,
        joined_at TEXT NOT NULL, PRIMARY KEY (meet_id, user_id)
      )''');
    b.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY, title TEXT NOT NULL, day TEXT NOT NULL,
        time TEXT NOT NULL, capacity INTEGER NOT NULL, going INTEGER NOT NULL
      )''');
    b.execute('''
      CREATE TABLE activity_attendees (
        activity_id TEXT NOT NULL, user_id TEXT NOT NULL,
        PRIMARY KEY (activity_id, user_id)
      )''');
    b.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY, author TEXT NOT NULL, kind TEXT NOT NULL,
        created_at TEXT NOT NULL, body TEXT NOT NULL,
        likes INTEGER NOT NULL DEFAULT 0, comments INTEGER NOT NULL DEFAULT 0
      )''');
    b.execute('''
      CREATE TABLE post_likes (
        post_id TEXT NOT NULL, user_id TEXT NOT NULL,
        PRIMARY KEY (post_id, user_id)
      )''');
    b.execute('''
      CREATE TABLE matches (
        id TEXT PRIMARY KEY, round INTEGER NOT NULL, court TEXT NOT NULL,
        side_a TEXT NOT NULL, side_b TEXT NOT NULL,
        score_a INTEGER, score_b INTEGER
      )''');
    b.execute('''
      CREATE TABLE comp_teams (
        code TEXT PRIMARY KEY, name TEXT NOT NULL, pool TEXT NOT NULL
      )''');
    b.execute('''
      CREATE TABLE pool_matches (
        id TEXT PRIMARY KEY, pool TEXT NOT NULL, a TEXT NOT NULL, b TEXT NOT NULL,
        score_a INTEGER NOT NULL, score_b INTEGER NOT NULL
      )''');
    b.execute('''
      CREATE TABLE bracket (
        id TEXT PRIMARY KEY, stage TEXT NOT NULL, time TEXT NOT NULL,
        seed_a INTEGER NOT NULL, team_a TEXT NOT NULL, score_a INTEGER NOT NULL,
        seed_b INTEGER NOT NULL, team_b TEXT NOT NULL, score_b INTEGER NOT NULL,
        ord INTEGER NOT NULL
      )''');
    b.execute('''
      CREATE TABLE threads (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, subtitle TEXT NOT NULL,
        kind TEXT NOT NULL, unread INTEGER NOT NULL DEFAULT 0, ord INTEGER NOT NULL
      )''');
    b.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY, thread_id TEXT NOT NULL, author_id TEXT,
        author TEXT NOT NULL, text TEXT NOT NULL, created_at TEXT NOT NULL,
        meet_card_id TEXT, system TEXT
      )''');
    b.execute('''
      CREATE TABLE reactions (
        message_id TEXT NOT NULL, user_id TEXT NOT NULL,
        PRIMARY KEY (message_id, user_id)
      )''');
    b.execute('CREATE INDEX idx_messages_thread ON messages(thread_id, created_at)');
    b.execute('CREATE INDEX idx_meets_start ON meets(start)');
    await b.commit(noResult: true);
  }

  // ---- seed --------------------------------------------------------------
  static String _iso(DateTime t) => t.toIso8601String();

  static Future<void> _seed(Database d) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final b = d.batch();

    // Demo account. Credentials are printed in the README and on the login page.
    const demoSalt = 'ReclubDemoSalt2026';
    b.insert('users', {
      'id': 'u-demo',
      'name': 'User',
      'email': 'demo@reclub.id',
      'password_hash': hashPassword('reclub123', demoSalt),
      'salt': demoSalt,
      'level': 'Advanced',
      'city': 'Jakarta',
      'sport': 'Pickleball',
      'bio': 'Main hampir tiap sore. DUPR 4.1, suka americano & round robin.',
      'phone': '+62 812-1111-2222',
      'created_at': _iso(day.subtract(const Duration(days: 210))),
    });

    b.insert('app_meta', {'k': 'onboarded', 'v': '0'});
    b.insert('app_meta', {'k': 'seed_version', 'v': '3'});

    b.insert('clubs', {
      'id': 'c-usc',
      'name': 'USC Pickleball',
      'sport': 'Pickleball',
      'city': 'Jakarta',
      'members': 16,
      'about':
          'Klub pickleball terbesar di Jakarta Selatan. Sesi social tiap hari, '
              'clinic untuk pemula tiap Selasa, dan liga internal tiap bulan.',
    });

    const names = [
      ['User', 'Advanced'],
      ['Luis Prasetyo', 'Intermediate'],
      ['Ha Lan', 'Advanced'],
      ['Phuc Hoang', 'Beginner'],
      ['Rina Ayu', 'Intermediate'],
      ['Dimas Putra', 'Advanced'],
      ['Kyle Adhi', 'Intermediate'],
      ['Soham Raka', 'Beginner'],
      ['Leslie Alexander', 'Advanced'],
      ['Dianne Russell', 'Intermediate'],
      ['Floyd Miles', 'Intermediate'],
      ['Eleanor Pena', 'Advanced'],
      ['Annette Black', 'Beginner'],
      ['Cody Fisher', 'Intermediate'],
      ['Esther Howard', 'Advanced'],
      ['Gladys Wijaya', 'Beginner'],
    ];
    const teams = ['Red', 'Blue', 'Yellow', 'Green'];
    for (var i = 0; i < names.length; i++) {
      b.insert('players', {
        'id': 'u$i',
        'name': names[i][0],
        'level': names[i][1],
        'team': teams[i ~/ 4],
      });
    }
    b.insert('club_members', {'club_id': 'c-usc', 'user_id': 'u0'});

    final meets = <List<Object>>[
      // id, club, title, venue, dayOffset, hour, min, dur, cap, taken, tag, dist, price, level, host, invited, gift
      ['m1', 'BOOM SOCIAL CLUB', '🔥 BOOM SOCIAL CLUB 🔥 — 100k / 2 jam', '96 Jl. Nguyen Quy Duc', 0, 17, 0, 120, 24, 19, 'Social', 6.1, 'Rp100k', '2.5 - 3.5', 'Boom Crew', 0, 0],
      ['m2', 'BANG BANG PICKLEBALL', '[90K/2Hrs] Sunset 🌇 and Sweat 💦', 'Bang Bang Pickleball Club', 0, 17, 0, 120, 14, 11, 'Social', 6.4, 'Rp90k', 'Semua level', 'Bang Bang', 0, 0],
      ['m3', 'SOCIAL SPORT CLUB', '🟤 THAO DIEN WEDNESDAY — 2 jam', 'PickoLand Thao Dien Pickleball Club', 0, 17, 30, 120, 22, 17, 'Social', 6.7, 'Rp120k', '3.0 - 4.0', 'Social Sport', 0, 1],
      ['m4', 'MINIONS PICKLEBALL', '🔥 MINIONS DAILY | Level 2.5-3.5', 'Tổ hợp thể thao GOPICK', 0, 18, 0, 120, 22, 19, 'Social', 6.9, 'Rp85k', '2.5 - 3.5', 'Minions', 1, 0],
      ['m5', 'USC PICKLEBALL', 'USC PB — RANDOM AMERICANO 🎾', 'USC Thanh My Loi', 0, 19, 0, 150, 24, 24, 'Training', 3.2, 'Rp150k', '3.0+', 'User', 0, 0],
      ['m6', 'PADEL HOUSE', 'PADEL AMERICANO WITH TRI', 'Padel House Senayan', 1, 10, 0, 120, 12, 8, 'Comp', 2.4, 'Rp180k', 'Intermediate', 'Tri Wibowo', 0, 0],
      ['m7', 'SUNRISE SMASH', '☀️ Morning Rally — All Levels', 'GBK Arena Court 3', 1, 7, 0, 90, 16, 6, 'Social', 4.8, 'Rp70k', 'Semua level', 'Sunrise', 0, 0],
      ['m8', 'NIGHT OWLS PB', '🌙 Late Night Dinks', 'Kemang Sport Center', 2, 21, 0, 120, 20, 13, 'Social', 8.2, 'Rp95k', 'Semua level', 'Night Owls', 0, 0],
      ['m9', 'USC PICKLEBALL', 'USC BTD — Social Sore', 'USC Thanh My Loi', 2, 17, 30, 120, 20, 6, 'Social', 3.2, 'Rp110k', 'Semua level', 'User', 0, 0],
      ['m10', 'GARUDA PADEL', 'Ladies Night Padel 🎀', 'Garuda Padel Kuningan', 3, 19, 30, 120, 12, 9, 'Social', 5.5, 'Rp160k', 'Semua level', 'Garuda', 0, 1],
      ['m11', 'THUNDER CLUB', 'Thunder League — Matchday 4', 'Thunder Dome Cilandak', 4, 18, 0, 180, 32, 27, 'Comp', 7.4, 'Rp200k', '3.5+', 'Thunder', 0, 0],
      ['m12', 'SUNRISE SMASH', 'Weekend Warm Up ☀️', 'GBK Arena Court 1', 5, 8, 0, 120, 20, 4, 'Social', 4.8, 'Rp75k', 'Semua level', 'Sunrise', 0, 0],
      ['m13', 'USC PICKLEBALL', 'USC Beginner Clinic', 'USC Thanh My Loi', 6, 9, 30, 90, 14, 14, 'Training', 3.2, 'Rp90k', 'Beginner', 'Ha Lan', 0, 0],
    ];
    for (final m in meets) {
      final off = m[4] as int;
      final start = DateTime(day.year, day.month, day.day + off, m[5] as int, m[6] as int);
      b.insert('meets', {
        'id': m[0], 'club_name': m[1], 'title': m[2], 'venue': m[3],
        'start': _iso(start), 'duration_min': m[7], 'capacity': m[8],
        'taken': m[9], 'tag': m[10], 'distance_km': m[11], 'price_label': m[12],
        'level': m[13], 'host': m[14], 'invited': m[15], 'has_gift': m[16],
      });
    }

    const acts = [
      ['a1', 'USC BTD — Social 17:30', 'Sen', '5:30 PM', 20, 6],
      ['a2', 'USC PB Social — Advanced', 'Sen', '7:30 PM', 18, 13],
      ['a3', 'Beginner Clinic', 'Sel', '9:30 AM', 14, 14],
      ['a4', 'USC PB — Random Americano', 'Rab', '7:00 PM', 24, 21],
      ['a5', 'Ladies Only Session', 'Kam', '6:00 PM', 16, 9],
      ['a6', 'Weekend Open Play', 'Sab', '8:00 AM', 28, 17],
    ];
    for (final a in acts) {
      b.insert('activities', {
        'id': a[0], 'title': a[1], 'day': a[2], 'time': a[3],
        'capacity': a[4], 'going': a[5],
      });
    }

    b.insert('posts', {
      'id': 'p1',
      'author': 'USC Pickleball',
      'kind': 'Announcement',
      'created_at': _iso(day.subtract(const Duration(days: 62))),
      'body': '📣 PERUBAHAN JADWAL CABANG THANH MY LOI 📣\n\n'
          'Untuk memenuhi kebutuhan bermain & bersosialisasi teman-teman USC '
          'Pickleball, sesi Social di Thanh My Loi resmi diperpanjang jadi 3 jam '
          'setiap hari!\n\n'
          '🕕 Jam main baru: 18.00 – 21.00 setiap hari\n'
          '💰 Harga tetap tidak berubah!',
      'likes': 42,
      'comments': 8,
    });
    b.insert('posts', {
      'id': 'p2',
      'author': 'User',
      'kind': 'Post',
      'created_at': _iso(day.subtract(const Duration(days: 21))),
      'body': 'Sesi Advanced kemarin seru banget 🔥 Yang mau gabung minggu depan '
          'langsung daftar di tab Aktivitas ya, slot cepat penuh.',
      'likes': 18,
      'comments': 3,
    });
    b.insert('posts', {
      'id': 'p3',
      'author': 'Rina Ayu',
      'kind': 'Post',
      'created_at': _iso(day.subtract(const Duration(days: 4))),
      'body': 'Ada yang punya paddle bekas ukuran grip 4 1/8? Lagi cari buat '
          'adik saya yang baru mulai 🙏',
      'likes': 6,
      'comments': 5,
    });

    const matches = [
      ['g1', 1, 'Court 1', 'Kyle,Soham', 'Leslie,Dianne', 11, 3],
      ['g2', 1, 'Court 2', 'Rina,Dimas', 'Floyd,Eleanor', 9, 11],
      ['g3', 2, 'Court 1', 'User,Luis', 'Dianne,Cody', 8, 11],
      ['g4', 2, 'Court 2', 'Esther,Gladys', 'Annette,Kyle', 11, 7],
      ['g5', 3, 'Court 1', 'User,Eleanor', 'Rina,Leslie', null, null],
      ['g6', 3, 'Court 2', 'Luis,Floyd', 'Dimas,Soham', null, null],
      ['g7', 4, 'Court 1', 'User,Dimas', 'Kyle,Esther', null, null],
      ['g8', 4, 'Court 2', 'Rina,Cody', 'Luis,Annette', null, null],
    ];
    for (final m in matches) {
      b.insert('matches', {
        'id': m[0], 'round': m[1], 'court': m[2],
        'side_a': m[3], 'side_b': m[4], 'score_a': m[5], 'score_b': m[6],
      });
    }

    const compTeams = [
      ['ST', 'Thunder', 'A'], ['SW', 'Swarm', 'A'], ['SS', 'Sharks', 'A'],
      ['HT', 'Heat', 'A'], ['RM', 'RMIT', 'A'],
      ['SP', 'SSB Simple Play', 'B'], ['GR', 'Garuda', 'B'],
      ['BL', 'Blitz', 'B'], ['FX', 'Foxes', 'B'],
    ];
    for (final t in compTeams) {
      b.insert('comp_teams', {'code': t[0], 'name': t[1], 'pool': t[2]});
    }

    const pool = [
      ['A', 'Thunder', 'Swarm', 28, 21], ['A', 'Thunder', 'Sharks', 30, 26],
      ['A', 'Thunder', 'Heat', 24, 18], ['A', 'Thunder', 'RMIT', 33, 15],
      ['A', 'Swarm', 'Sharks', 22, 25], ['A', 'Swarm', 'Heat', 27, 19],
      ['A', 'Swarm', 'RMIT', 31, 20], ['A', 'Sharks', 'Heat', 26, 24],
      ['A', 'Sharks', 'RMIT', 29, 17], ['A', 'Heat', 'RMIT', 28, 22],
      ['B', 'SSB Simple Play', 'Garuda', 26, 20],
      ['B', 'SSB Simple Play', 'Blitz', 24, 22],
      ['B', 'SSB Simple Play', 'Foxes', 30, 19],
      ['B', 'Garuda', 'Blitz', 21, 25], ['B', 'Garuda', 'Foxes', 27, 23],
      ['B', 'Blitz', 'Foxes', 28, 26],
    ];
    for (var i = 0; i < pool.length; i++) {
      final m = pool[i];
      b.insert('pool_matches', {
        'id': 'pm$i', 'pool': m[0], 'a': m[1], 'b': m[2],
        'score_a': m[3], 'score_b': m[4],
      });
    }

    const bracket = [
      ['b1', 'SEMI FINALS', '1 Apr @1:00 PM', 1, 'Thunder', 28, 4, 'Heat', 25, 0],
      ['b2', 'SEMI FINALS', '1 Apr @1:00 PM', 3, 'Sharks', 31, 2, 'Swarm', 26, 1],
      ['b3', 'FINALS', '1 Apr @3:00 PM', 1, 'Thunder', 30, 3, 'Sharks', 27, 2],
      ['b4', 'THIRD PLACE', '1 Apr @3:00 PM', 2, 'Swarm', 29, 4, 'Heat', 24, 3],
    ];
    for (final s in bracket) {
      b.insert('bracket', {
        'id': s[0], 'stage': s[1], 'time': s[2], 'seed_a': s[3], 'team_a': s[4],
        'score_a': s[5], 'seed_b': s[6], 'team_b': s[7], 'score_b': s[8], 'ord': s[9],
      });
    }

    const threads = [
      ['t1', 'USC Pickleball', 'Klub · 16 anggota', 'club', 0],
      ['t2', 'PADEL AMERICANO WITH TRI', 'Meet · besok 10:00', 'meet', 1],
      ['t3', 'Beginner Clinic', 'Meet · Sel 9:30 · 14/14', 'meet', 2],
      ['t4', 'Rina Ayu', 'Pesan langsung', 'dm', 3],
    ];
    for (final t in threads) {
      b.insert('threads', {
        'id': t[0], 'name': t[1], 'subtitle': t[2], 'kind': t[3],
        'unread': 0, 'ord': t[4],
      });
    }

    final base = day.add(const Duration(hours: 18, minutes: 45));
    final msgs = <List<Object?>>[
      ['c1', 't1', null, 'Dimas Putra', 'Round robin minggu lalu seru banget. Minggu ini main lagi kan?', 3, null, null],
      ['c2', 't1', null, '', '', 4, 'm6', 'Sebuah meet baru telah dibuat'],
      ['c3', 't1', 'u-demo', 'User', 'Yes! Barusan aku bikin meet-nya 🎾', 5, null, null],
      ['c4', 't1', null, 'Rina Ayu', 'Mantap, aku langsung daftar 🙌', 6, null, null],
      ['c5', 't1', null, 'Kyle Adhi', 'Court 2 masih kosong ga? Aku bawa 2 temen', 9, null, null],
      ['c6', 't2', null, 'Tri Wibowo', 'Halo semua, besok kita mulai jam 10 tepat ya 🙏', 12, null, null],
      ['c7', 't2', null, 'Eleanor Pena', 'Siap! Aku bawa bola tambahan', 20, null, null],
      ['c8', 't3', null, 'Ha Lan', 'Clinic udah penuh ya, waiting list dibuka minggu depan.', 30, null, null],
      ['c9', 't4', null, 'Rina Ayu', 'Bro besok jadi main kan?', 40, null, null],
      ['c10', 't4', 'u-demo', 'User', 'Jadi dong, jam 7 di GBK', 45, null, null],
    ];
    for (final m in msgs) {
      b.insert('messages', {
        'id': m[0], 'thread_id': m[1], 'author_id': m[2], 'author': m[3],
        'text': m[4], 'created_at': _iso(base.add(Duration(minutes: m[5] as int))),
        'meet_card_id': m[6], 'system': m[7],
      });
    }
    // A couple of seeded reactions so the pill shows a count out of the box.
    b.insert('reactions', {'message_id': 'c1', 'user_id': 'u5'});
    b.insert('reactions', {'message_id': 'c1', 'user_id': 'u6'});
    b.insert('reactions', {'message_id': 'c1', 'user_id': 'u7'});

    await b.commit(noResult: true);
  }

  /// Keeps the seeded meets anchored to "today" so the 7-day strip is never
  /// empty when the app is opened days after first install.
  static Future<void> _rollMeetsForward(Database d) async {
    final rows = await d.rawQuery('SELECT MIN(start) AS s FROM meets');
    final minStr = rows.first['s'] as String?;
    if (minStr == null) return;
    final min = DateTime.parse(minStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minDay = DateTime(min.year, min.month, min.day);
    final shift = today.difference(minDay).inDays;
    if (shift <= 0) return;
    final all = await d.query('meets');
    final b = d.batch();
    for (final m in all) {
      final s = DateTime.parse(m['start'] as String).add(Duration(days: shift));
      b.update('meets', {'start': _iso(s)}, where: 'id = ?', whereArgs: [m['id']]);
    }
    await b.commit(noResult: true);
  }
}
