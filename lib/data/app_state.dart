import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'models.dart';
import 'vffl.dart';

enum BootStage { loading, onboarding, auth, ready }

/// App-wide store. Everything is persisted in SQLite (see [AppDb]); this class
/// keeps a hydrated copy in memory so the UI can stay synchronous, and writes
/// through to the database on every mutation.
class AppState extends ChangeNotifier {
  Database get _db => AppDb.instance.db;

  BootStage stage = BootStage.loading;
  User? me;
  bool get signedIn => me != null;

  // ---- Navigasi ----------------------------------------------------------
  /// Tab aktif di bottom navigation (0 Discover, 1 Klub, 2 Meet, 3 Compete, 4 Chat).
  int shellIndex = 0;

  int competeSeason = 4;

  Duration? authDelayOverride;
  final Random _rng = Random();

  void goToTab(int i) {
    shellIndex = i;
    notifyListeners();
  }

  void setCompeteSeason(int season) {
    competeSeason = season;
    notifyListeners();
  }

  /// Membuka halaman Compete langsung pada musim [season].
  void openCompetition(int season) {
    competeSeason = season;
    shellIndex = 3;
    notifyListeners();
  }

  // ---- Discover filters --------------------------------------------------
  String city = 'Jakarta';
  Sport sport = const Sport('Pickleball', Icons.sports_tennis);
  int discoverTab = 1; // 0 clubs, 1 meets, 2 comps, 3 venue, 4 people
  int dayIndex = 0;
  String query = '';
  bool socialOnly = false;
  String tagFilter = 'Semua';
  double maxDistance = 12;

  static const cities = ['Jakarta', 'Bandung', 'Surabaya', 'Bali', 'Medan'];
  static const sports = [
    Sport('Pickleball', Icons.sports_tennis),
    Sport('Padel', Icons.sports_handball),
    Sport('Futsal', Icons.sports_soccer),
    Sport('Basket', Icons.sports_basketball),
    Sport('Tenis', Icons.sports_baseball),
  ];
  static const levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const maxFavoriteSports = 3;
  static const selfChatMessage = 'Anda tidak dapat mengirim pesan ke diri anda sendiri';

  static IconData sportIcon(String name) =>
      sports.firstWhere((s) => s.name == name, orElse: () => sports.first).icon;
  static const tags = ['Semua', 'Social', 'Training', 'Comp'];

  DateTime get today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get selectedDay => today.add(Duration(days: dayIndex));

  // ---- Hydrated data -----------------------------------------------------
  final List<Meet> meets = [];
  final List<Activity> activities = [];
  final List<ClubPost> posts = [];
  final List<Player> members = [];
  final List<GameMatch> matches = [];
  final List<CompTeam> compTeams = [];
  final List<PoolMatch> poolMatches = [];
  final List<BracketSlot> bracket = [];
  final List<ChatThread> threads = [];
  final List<ChatMessage> chat = [];
  final List<CompRegistration> registrations = [];

  Club club = const Club(
    id: 'c-usc',
    name: 'USC Pickleball',
    sport: 'Pickleball',
    city: 'Jakarta',
    members: 16,
    about: '',
  );
  bool clubJoined = false;
  String chatThreadId = 't1';
  ChatThread get chatThread =>
      threads.firstWhere((t) => t.id == chatThreadId, orElse: () => threads.first);

  static const venues = [
    Venue(name: 'USC Thanh My Loi', area: 'Kebayoran Baru', courts: 6, rating: 4.8, priceFrom: 'Rp90k', distanceKm: 3.2),
    Venue(name: 'Padel House Senayan', area: 'Senayan', courts: 4, rating: 4.9, priceFrom: 'Rp180k', distanceKm: 2.4),
    Venue(name: 'GBK Arena', area: 'Gelora', courts: 8, rating: 4.6, priceFrom: 'Rp70k', distanceKm: 4.8),
    Venue(name: 'Kemang Sport Center', area: 'Kemang', courts: 3, rating: 4.4, priceFrom: 'Rp95k', distanceKm: 8.2),
    Venue(name: 'Thunder Dome Cilandak', area: 'Cilandak', courts: 5, rating: 4.7, priceFrom: 'Rp120k', distanceKm: 7.4),
  ];

  static const clubs = [
    Club(id: 'c-usc', name: 'USC Pickleball', sport: 'Pickleball', city: 'Jakarta', members: 16, about: 'Social tiap hari · clinic Selasa'),
    Club(id: 'c-boom', name: 'Boom Social Club', sport: 'Pickleball', city: 'Jakarta', members: 128, about: 'Vibes dulu, menang belakangan'),
    Club(id: 'c-thunder', name: 'Thunder Club', sport: 'Pickleball', city: 'Jakarta', members: 94, about: 'Liga kompetitif 3.5+'),
    Club(id: 'c-garuda', name: 'Garuda Padel', sport: 'Padel', city: 'Jakarta', members: 61, about: 'Padel Kuningan, ladies night tiap Kamis'),
    Club(id: 'c-sunrise', name: 'Sunrise Smash', sport: 'Pickleball', city: 'Jakarta', members: 47, about: 'Sesi pagi sebelum kerja'),
  ];

  // ---- Boot --------------------------------------------------------------
  Future<void> boot() async {
    await AppDb.instance.open();
    final onboarded = await _meta('onboarded') == '1';
    final userId = await _meta('user_id');
    if (userId != null) {
      final rows = await _db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
      if (rows.isNotEmpty) me = User.fromMap(rows.first);
    }
    if (me != null) {
      city = me!.city;
      sport = sports.firstWhere((s) => s.name == me!.primarySport, orElse: () => sports.first);
      await _hydrate();
      stage = BootStage.ready;
    } else {
      stage = onboarded ? BootStage.auth : BootStage.onboarding;
    }
    notifyListeners();
  }

  Future<String?> _meta(String k) async {
    final r = await _db.query('app_meta', where: 'k = ?', whereArgs: [k], limit: 1);
    return r.isEmpty ? null : r.first['v'] as String;
  }

  Future<void> _setMeta(String k, String v) =>
      _db.insert('app_meta', {'k': k, 'v': v}, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> completeOnboarding() async {
    await _setMeta('onboarded', '1');
    stage = BootStage.auth;
    notifyListeners();
  }

  // ---- Auth --------------------------------------------------------------
  /// Menjalankan [body] sambil menampilkan animasi loading 3-5 detik. Halaman
  /// baru (stage `ready`) baru dibuka setelah animasi selesai; kalau gagal,
  /// pesan error langsung dikembalikan tanpa menunggu.
  Future<String?> _authFlow(Future<String?> Function() body) async {
    final delay = authDelayOverride ?? Duration(milliseconds: 3000 + _rng.nextInt(2001));
    final wait = Future<void>.delayed(delay);
    final err = await body();
    if (err != null) return err;
    await wait;
    shellIndex = 0;
    competeSeason = 4;
    stage = BootStage.ready;
    notifyListeners();
    return null;
  }

  /// Returns null on success, or a human-readable error message.
  Future<String?> signIn(String email, String password) =>
      _authFlow(() => _signInRaw(email, password));

  Future<String?> _signInRaw(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return 'Email belum diisi.';
    if (password.isEmpty) return 'Password belum diisi.';
    final rows = await _db.query('users', where: 'LOWER(email) = ?', whereArgs: [e], limit: 1);
    if (rows.isEmpty) return 'Email belum terdaftar.';
    final row = rows.first;
    final hash = AppDb.hashPassword(password, row['salt'] as String);
    if (hash != row['password_hash']) return 'Password salah.';
    await _startSession(row);
    return null;
  }

  /// Loads [row] as the signed-in user and hydrates the app from SQLite.
  Future<void> _startSession(Map<String, Object?> row) async {
    me = User.fromMap(row);
    city = me!.city;
    sport = sports.firstWhere((s) => s.name == me!.primarySport, orElse: () => sports.first);
    await _setMeta('user_id', me!.id);
    await _hydrate();
    // `stage` sengaja tidak diubah di sini: [_authFlow] yang membukanya
    // setelah animasi loading selesai.
    notifyListeners();
  }

  Future<Map<String, Object?>?> _userByEmail(String email) async {
    final rows = await _db.query('users', where: 'LOWER(email) = ?', whereArgs: [email], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, Object?>> _createUser({
    required String name,
    required String email,
    required String password,
    required String provider,
    String level = 'Intermediate',
    String? userCity,
    String? userSport,
    String bio = '',
  }) async {
    final salt = AppDb.newSalt();
    final id = 'u-${DateTime.now().microsecondsSinceEpoch}';
    final row = <String, Object?>{
      'id': id,
      'name': name.trim(),
      'email': email,
      'password_hash': AppDb.hashPassword(password, salt),
      'salt': salt,
      'level': level,
      'city': userCity ?? city,
      'sport': userSport ?? sport.name,
      'provider': provider,
      'bio': bio,
      'phone': '',
      'created_at': DateTime.now().toIso8601String(),
    };
    await _db.insert('users', row);
    return row;
  }

  /// Signs in with a Google account. Existing emails reuse their account, new
  /// ones get a `google` account created on the spot (no password to type).
  Future<String?> signInWithGoogle({required String name, required String email}) =>
      _authFlow(() => _googleRaw(name: name, email: email));

  Future<String?> _googleRaw({required String name, required String email}) async {
    final e = email.trim().toLowerCase();
    if (name.trim().length < 2) return 'Nama Google tidak valid.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) return 'Format email tidak valid.';
    final existing = await _userByEmail(e);
    if (existing != null) {
      await _startSession(existing);
      return null;
    }
    final row = await _createUser(
      name: name,
      email: e,
      password: AppDb.newSalt(),
      provider: 'google',
      bio: 'Masuk lewat Google.',
    );
    await _startSession(row);
    return null;
  }

  /// Browses without an account. The guest is a real row in SQLite, so
  /// everything a guest does is still saved and can be upgraded later.
  Future<String?> continueAsGuest() => _authFlow(_guestRaw);

  Future<String?> _guestRaw() async {
    const email = 'tamu@reclub.local';
    final existing = await _userByEmail(email);
    if (existing != null) {
      await _startSession(existing);
      return null;
    }
    final row = await _createUser(
      name: 'Tamu',
      email: email,
      password: AppDb.newSalt(),
      provider: 'guest',
      bio: 'Lagi coba-coba dulu 👀',
    );
    await _startSession(row);
    return null;
  }

  /// Turns the current guest session into a real account, keeping every meet,
  /// message and score the guest already created.
  Future<String?> upgradeGuest({
    required String name,
    required String email,
    required String password,
  }) async {
    final u = me;
    if (u == null || !u.isGuest) return 'Kamu bukan tamu.';
    final e = email.trim().toLowerCase();
    if (name.trim().length < 2) return 'Nama minimal 2 karakter.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) return 'Format email tidak valid.';
    if (password.length < 6) return 'Password minimal 6 karakter.';
    final dupe = await _userByEmail(e);
    if (dupe != null) return 'Email sudah terdaftar. Coba masuk.';
    final salt = AppDb.newSalt();
    await _db.update(
      'users',
      {
        'name': name.trim(),
        'email': e,
        'password_hash': AppDb.hashPassword(password, salt),
        'salt': salt,
        'provider': 'password',
      },
      where: 'id = ?',
      whereArgs: [u.id],
    );
    final row = await _userByEmail(e);
    await _startSession(row!);
    return null;
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String level,
    required String userCity,
    required String userSport,
  }) =>
      _authFlow(() => _signUpRaw(
            name: name,
            email: email,
            password: password,
            level: level,
            userCity: userCity,
            userSport: userSport,
          ));

  Future<String?> _signUpRaw({
    required String name,
    required String email,
    required String password,
    required String level,
    required String userCity,
    required String userSport,
  }) async {
    final e = email.trim().toLowerCase();
    if (name.trim().length < 2) return 'Nama minimal 2 karakter.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) return 'Format email tidak valid.';
    if (password.length < 6) return 'Password minimal 6 karakter.';
    final dupe = await _db.query('users', where: 'LOWER(email) = ?', whereArgs: [e], limit: 1);
    if (dupe.isNotEmpty) return 'Email sudah terdaftar. Coba masuk.';
    await _createUser(
      name: name,
      email: e,
      password: password,
      provider: 'password',
      level: level,
      userCity: userCity,
      userSport: userSport,
    );
    return _signInRaw(e, password);
  }

  Future<void> signOut() async {
    await _db.delete('app_meta', where: 'k = ?', whereArgs: ['user_id']);
    me = null;
    _clear();
    shellIndex = 0;
    competeSeason = 4;
    stage = BootStage.auth;
    notifyListeners();
  }

  Future<String?> updateProfile({
    required String name,
    required String level,
    required String userCity,
    required List<String> userSports,
    required String bio,
    required String phone,
  }) async {
    if (me == null) return 'Belum masuk.';
    if (name.trim().length < 2) return 'Nama minimal 2 karakter.';
    if (userSports.isEmpty) return 'Pilih minimal 1 olahraga favorit.';
    if (userSports.length > maxFavoriteSports) {
      return 'Olahraga favorit maksimal $maxFavoriteSports.';
    }
    final userSport = userSports.join(',');
    await _db.update(
      'users',
      {
        'name': name.trim(),
        'level': level,
        'city': userCity,
        'sport': userSport,
        'bio': bio.trim(),
        'phone': phone.trim(),
      },
      where: 'id = ?',
      whereArgs: [me!.id],
    );
    me!
      ..name = name.trim()
      ..level = level
      ..city = userCity
      ..sport = userSport
      ..bio = bio.trim()
      ..phone = phone.trim();
    city = userCity;
    sport = sports.firstWhere((s) => s.name == userSports.first, orElse: () => sports.first);
    notifyListeners();
    return null;
  }

  Future<String?> changePassword(String current, String next) async {
    if (me == null) return 'Belum masuk.';
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [me!.id], limit: 1);
    final row = rows.first;
    if (AppDb.hashPassword(current, row['salt'] as String) != row['password_hash']) {
      return 'Password lama salah.';
    }
    if (next.length < 6) return 'Password baru minimal 6 karakter.';
    final salt = AppDb.newSalt();
    await _db.update(
      'users',
      {'salt': salt, 'password_hash': AppDb.hashPassword(next, salt)},
      where: 'id = ?',
      whereArgs: [me!.id],
    );
    return null;
  }

  Future<void> resetData() async {
    await AppDb.instance.reset();
    me = null;
    _clear();
    shellIndex = 0;
    competeSeason = 4;
    stage = BootStage.onboarding;
    notifyListeners();
  }

  void _clear() {
    for (final l in [meets, activities, posts, members, matches, compTeams, poolMatches, bracket, threads, chat, registrations]) {
      l.clear();
    }
  }

  // ---- Hydration ---------------------------------------------------------
  Future<void> _hydrate() async {
    final meId = me?.id ?? '';
    _clear();

    final clubRow = await _db.query('clubs', where: 'id = ?', whereArgs: ['c-usc'], limit: 1);
    if (clubRow.isNotEmpty) {
      final c = clubRow.first;
      club = Club(
        id: c['id'] as String,
        name: c['name'] as String,
        sport: c['sport'] as String,
        city: c['city'] as String,
        members: c['members'] as int,
        about: c['about'] as String,
      );
    }
    clubJoined = (await _db.query('club_members',
            where: 'club_id = ? AND user_id = ?', whereArgs: [club.id, meId]))
        .isNotEmpty;

    final joinedIds = (await _db.query('meet_participants', where: 'user_id = ?', whereArgs: [meId]))
        .map((r) => r['meet_id'] as String)
        .toSet();
    for (final r in await _db.query('meets', orderBy: 'start')) {
      meets.add(Meet.fromMap(r)..joined = joinedIds.contains(r['id']));
    }

    final attending = (await _db.query('activity_attendees', where: 'user_id = ?', whereArgs: [meId]))
        .map((r) => r['activity_id'] as String)
        .toSet();
    for (final r in await _db.query('activities')) {
      activities.add(Activity.fromMap(r)..attending = attending.contains(r['id']));
    }

    final liked = (await _db.query('post_likes', where: 'user_id = ?', whereArgs: [meId]))
        .map((r) => r['post_id'] as String)
        .toSet();
    for (final r in await _db.query('posts', orderBy: 'created_at DESC')) {
      posts.add(ClubPost.fromMap(r)..liked = liked.contains(r['id']));
    }

    for (final r in await _db.query('players')) {
      members.add(Player.fromMap(r));
    }
    for (final r in await _db.query('matches', orderBy: 'round, id')) {
      matches.add(GameMatch.fromMap(r));
    }
    for (final r in await _db.query('comp_teams')) {
      compTeams.add(CompTeam.fromMap(r));
    }
    for (final r in await _db.query('pool_matches')) {
      poolMatches.add(PoolMatch.fromMap(r));
    }
    for (final r in await _db.query('bracket', orderBy: 'ord')) {
      bracket.add(BracketSlot.fromMap(r));
    }
    for (final r in await _db.query('threads', orderBy: 'ord')) {
      threads.add(ChatThread.fromMap(r));
    }
    for (final r in await _db.query('comp_registrations',
        where: 'owner_id = ?', whereArgs: [meId], orderBy: 'created_at')) {
      registrations.add(CompRegistration.fromMap(r));
    }
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    final meId = me?.id ?? '';
    chat.clear();
    final counts = <String, int>{};
    final mine = <String>{};
    for (final r in await _db.query('reactions')) {
      final id = r['message_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
      if (r['user_id'] == meId) mine.add(id);
    }
    for (final r in await _db.query('messages', orderBy: 'created_at')) {
      final m = ChatMessage.fromMap(r, meId);
      chat.add(ChatMessage(
        id: m.id,
        threadId: m.threadId,
        author: m.author,
        text: m.text,
        createdAt: m.createdAt,
        mine: m.mine,
        reactions: counts[m.id] ?? 0,
        reacted: mine.contains(m.id),
        meetCardId: m.meetCardId,
        system: m.system,
      ));
    }
  }

  // ---- Derived -----------------------------------------------------------
  List<Meet> get visibleMeets {
    final day = selectedDay;
    final q = query.trim().toLowerCase();
    return meets.where((m) {
      final sameDay = m.start.year == day.year && m.start.month == day.month && m.start.day == day.day;
      final matchesQ = q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          m.clubName.toLowerCase().contains(q) ||
          m.venue.toLowerCase().contains(q);
      final matchesTag = tagFilter == 'Semua' || m.tag == tagFilter;
      final matchesSocial = !socialOnly || m.tag == 'Social';
      return sameDay && matchesQ && matchesTag && matchesSocial && m.distanceKm <= maxDistance;
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  bool get filtersActive => socialOnly || tagFilter != 'Semua' || maxDistance < 12;

  int meetsOnDay(int offset) {
    final d = today.add(Duration(days: offset));
    return meets.where((m) => m.start.year == d.year && m.start.month == d.month && m.start.day == d.day).length;
  }

  List<Meet> get myMeets =>
      meets.where((m) => m.joined).toList()..sort((a, b) => a.start.compareTo(b.start));

  Meet? meetById(String id) {
    for (final m in meets) {
      if (m.id == id) return m;
    }
    return null;
  }

  Meet get featuredMeet =>
      myMeets.isNotEmpty ? myMeets.first : (meetById('m6') ?? meets.first);

  List<ChatMessage> messagesFor(String threadId) =>
      chat.where((m) => m.threadId == threadId).toList();

  ChatMessage? lastMessageOf(String threadId) {
    final list = messagesFor(threadId).where((m) => m.system == null).toList();
    return list.isEmpty ? null : list.last;
  }

  List<Player> get roster => members;

  List<GameMatch> get myMatches {
    final first = me?.firstName ?? '';
    return matches
        .where((m) => m.sideA.contains(first) || m.sideB.contains(first))
        .toList();
  }

  List<Standing> get standings {
    final table = <String, Standing>{};
    Standing at(String n) => table.putIfAbsent(n, () => Standing(n));
    for (final m in matches) {
      if (!m.played) continue;
      for (final p in m.sideA) {
        final s = at(p);
        s.played++;
        s.pointsFor += m.scoreA!;
        s.pointsAgainst += m.scoreB!;
        if (m.scoreA! > m.scoreB!) s.wins++;
      }
      for (final p in m.sideB) {
        final s = at(p);
        s.played++;
        s.pointsFor += m.scoreB!;
        s.pointsAgainst += m.scoreA!;
        if (m.scoreB! > m.scoreA!) s.wins++;
      }
    }
    return table.values.toList()
      ..sort((a, b) {
        final w = b.wins.compareTo(a.wins);
        if (w != 0) return w;
        final d = b.diff.compareTo(a.diff);
        if (d != 0) return d;
        return b.pointsFor.compareTo(a.pointsFor);
      });
  }

  List<Map<String, dynamic>> poolTable(String pool) => poolTableOf(compTeams, poolMatches, pool);

  // ---- Teman (halaman sosial) --------------------------------------------
  /// Apakah [p] adalah akun yang sedang masuk.
  bool isSelf(Player p) {
    final u = me;
    if (u == null) return false;
    return p.id == u.id || p.name.trim().toLowerCase() == u.name.trim().toLowerCase();
  }

  Player? get _selfPlayer {
    final u = me;
    if (u == null) return null;
    return Player(id: u.id, name: u.name, level: u.level, sports: u.sports, bio: u.bio);
  }

  /// Daftar teman untuk tab TEMAN. Data akun sendiri selalu diambil dari profil
  /// terbaru, dan akun sendiri ditaruh di daftar walau belum ada di roster.
  List<Player> get friends {
    final self = _selfPlayer;
    final out = [for (final p in members) isSelf(p) && self != null ? self : p];
    if (self != null && !members.any(isSelf)) out.insert(0, self);
    return out;
  }

  /// Membuka (atau membuat) obrolan pribadi dengan [p]. Mengembalikan id thread,
  /// atau `null` bila [p] adalah akun sendiri.
  Future<String?> openDirectThread(Player p) async {
    if (me == null || isSelf(p)) return null;
    ChatThread? t;
    for (final x in threads) {
      if (x.kind == 'dm' && x.name == p.name) {
        t = x;
        break;
      }
    }
    if (t == null) {
      t = ChatThread(id: 'dm-${p.id}', name: p.name, subtitle: 'Pesan langsung', kind: 'dm');
      threads.add(t);
      await _db.insert(
        'threads',
        {'id': t.id, 'name': t.name, 'subtitle': t.subtitle, 'kind': 'dm', 'unread': 0, 'ord': threads.length + 10},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await openThread(t.id);
    return t.id;
  }

  // ---- Pendaftaran kompetisi ---------------------------------------------
  CompRegistration? registrationFor(int season) {
    for (final r in registrations) {
      if (r.season == season) return r;
    }
    return null;
  }

  /// Mendaftarkan tim ke musim [season]. [memberNames] berisi 4 nama, kapten
  /// (akun ini) di urutan pertama.
  Future<String?> registerCompTeam({
    required int season,
    required String teamName,
    required List<String> memberNames,
    required String method,
  }) async {
    final u = me;
    if (u == null) return 'Belum masuk.';
    if (registrationFor(season) != null) return 'Tim kamu sudah terdaftar di musim ini.';
    final name = teamName.trim();
    if (name.length < 3) return 'Nama tim minimal 3 karakter.';
    if (memberNames.length != 4) return 'Tim harus terdiri dari 4 pemain.';
    final reg = CompRegistration(
      id: 'reg-${DateTime.now().microsecondsSinceEpoch}',
      season: season,
      teamName: name,
      members: memberNames,
      method: method,
      createdAt: DateTime.now(),
    );
    await _db.insert('comp_registrations', {
      'id': reg.id,
      'season': season,
      'owner_id': u.id,
      'team_name': name,
      'members': memberNames.join('|'),
      'method': method,
      'created_at': reg.createdAt.toIso8601String(),
    });
    registrations.add(reg);
    competeSeason = season;
    shellIndex = 3;
    notifyListeners();
    return null;
  }

  // ---- Filters (no persistence needed) -----------------------------------
  void setCity(String v) {
    city = v;
    notifyListeners();
  }

  void setSport(Sport v) {
    sport = v;
    notifyListeners();
  }

  void setDiscoverTab(int i) {
    discoverTab = i;
    notifyListeners();
  }

  void setDay(int i) {
    dayIndex = i;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void setTagFilter(String t) {
    tagFilter = t;
    notifyListeners();
  }

  void setMaxDistance(double d) {
    maxDistance = d;
    notifyListeners();
  }

  void clearFilters() {
    socialOnly = false;
    tagFilter = 'Semua';
    maxDistance = 12;
    notifyListeners();
  }

  void toggleSocialOnly() {
    socialOnly = !socialOnly;
    notifyListeners();
  }

  void setChatThread(String id) {
    chatThreadId = id;
    notifyListeners();
  }

  /// Opens a thread and clears its unread badge (persisted).
  Future<void> openThread(String id) async {
    chatThreadId = id;
    for (final t in threads) {
      if (t.id == id && t.unread != 0) {
        t.unread = 0;
        await _db.update('threads', {'unread': 0}, where: 'id = ?', whereArgs: [id]);
      }
    }
    notifyListeners();
  }

  // ---- Persisted mutations ----------------------------------------------
  Future<bool> toggleJoinMeet(String id) async {
    final m = meetById(id);
    if (m == null || me == null) return false;
    if (m.joined) {
      m.joined = false;
      m.taken--;
      await _db.delete('meet_participants',
          where: 'meet_id = ? AND user_id = ?', whereArgs: [id, me!.id]);
    } else {
      if (m.full) return false;
      m.joined = true;
      m.taken++;
      await _db.insert(
        'meet_participants',
        {'meet_id': id, 'user_id': me!.id, 'joined_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await _db.update('meets', {'taken': m.taken}, where: 'id = ?', whereArgs: [id]);
    notifyListeners();
    return true;
  }

  Future<void> toggleClubJoin() async {
    if (me == null) return;
    clubJoined = !clubJoined;
    if (clubJoined) {
      await _db.insert('club_members', {'club_id': club.id, 'user_id': me!.id},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await _db.delete('club_members',
          where: 'club_id = ? AND user_id = ?', whereArgs: [club.id, me!.id]);
    }
    notifyListeners();
  }

  Future<bool> toggleAttend(String activityId) async {
    if (me == null) return false;
    final a = activities.firstWhere((x) => x.id == activityId);
    if (a.attending) {
      a.attending = false;
      a.going--;
      await _db.delete('activity_attendees',
          where: 'activity_id = ? AND user_id = ?', whereArgs: [activityId, me!.id]);
    } else {
      if (a.going >= a.capacity) return false;
      a.attending = true;
      a.going++;
      await _db.insert('activity_attendees', {'activity_id': activityId, 'user_id': me!.id},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await _db.update('activities', {'going': a.going}, where: 'id = ?', whereArgs: [activityId]);
    notifyListeners();
    return true;
  }

  Future<void> toggleLike(String postId) async {
    if (me == null) return;
    final p = posts.firstWhere((x) => x.id == postId);
    p.liked = !p.liked;
    p.likes += p.liked ? 1 : -1;
    if (p.liked) {
      await _db.insert('post_likes', {'post_id': postId, 'user_id': me!.id},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await _db.delete('post_likes',
          where: 'post_id = ? AND user_id = ?', whereArgs: [postId, me!.id]);
    }
    await _db.update('posts', {'likes': p.likes}, where: 'id = ?', whereArgs: [postId]);
    notifyListeners();
  }

  Future<void> addPost(String body, {String kind = 'Post'}) async {
    if (me == null || body.trim().isEmpty) return;
    final post = ClubPost(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}',
      author: me!.name,
      kind: kind,
      createdAt: DateTime.now(),
      body: body.trim(),
    );
    posts.insert(0, post);
    await _db.insert('posts', {
      'id': post.id,
      'author': post.author,
      'kind': post.kind,
      'created_at': post.createdAt.toIso8601String(),
      'body': post.body,
      'likes': 0,
      'comments': 0,
    });
    notifyListeners();
  }

  Future<void> deletePost(String id) async {
    posts.removeWhere((p) => p.id == id);
    await _db.delete('posts', where: 'id = ?', whereArgs: [id]);
    await _db.delete('post_likes', where: 'post_id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> setScore(String matchId, int? a, int? b) async {
    final m = matches.firstWhere((x) => x.id == matchId);
    m.scoreA = a;
    m.scoreB = b;
    await _db.update('matches', {'score_a': a, 'score_b': b},
        where: 'id = ?', whereArgs: [matchId]);
    notifyListeners();
  }

  Future<void> setPoolScore(String id, int a, int b) async {
    final m = poolMatches.firstWhere((x) => x.id == id);
    m.scoreA = a;
    m.scoreB = b;
    await _db.update('pool_matches', {'score_a': a, 'score_b': b},
        where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? threadId}) async {
    if (me == null || text.trim().isEmpty) return;
    final tid = threadId ?? chatThreadId;
    final msg = ChatMessage(
      id: 'c-${DateTime.now().microsecondsSinceEpoch}',
      threadId: tid,
      author: me!.name,
      text: text.trim(),
      createdAt: DateTime.now(),
      mine: true,
    );
    chat.add(msg);
    await _db.insert('messages', {
      'id': msg.id,
      'thread_id': tid,
      'author_id': me!.id,
      'author': msg.author,
      'text': msg.text,
      'created_at': msg.createdAt.toIso8601String(),
    });
    notifyListeners();
  }

  Future<void> deleteMessage(String id) async {
    chat.removeWhere((m) => m.id == id);
    await _db.delete('messages', where: 'id = ?', whereArgs: [id]);
    await _db.delete('reactions', where: 'message_id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> react(String messageId) async {
    if (me == null) return;
    final m = chat.firstWhere((x) => x.id == messageId);
    if (m.reacted) {
      m.reacted = false;
      m.reactions--;
      await _db.delete('reactions',
          where: 'message_id = ? AND user_id = ?', whereArgs: [messageId, me!.id]);
    } else {
      m.reacted = true;
      m.reactions++;
      await _db.insert('reactions', {'message_id': messageId, 'user_id': me!.id},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    notifyListeners();
  }

  /// Creates a meet, auto-joins the host and announces it in the club thread.
  Future<Meet> createMeet({
    required String title,
    required String venue,
    required DateTime start,
    required int durationMin,
    required int capacity,
    required String tag,
    required String priceLabel,
    required String level,
  }) async {
    final id = 'm-${DateTime.now().microsecondsSinceEpoch}';
    final meet = Meet(
      id: id,
      clubName: club.name.toUpperCase(),
      title: title.trim(),
      venue: venue.trim(),
      start: start,
      durationMin: durationMin,
      capacity: capacity,
      taken: 1,
      tag: tag,
      distanceKm: 3.2,
      priceLabel: priceLabel,
      level: level,
      host: me?.name ?? 'Kamu',
      joined: true,
    );
    meets.add(meet);
    meets.sort((a, b) => a.start.compareTo(b.start));
    await _db.insert('meets', {
      'id': id,
      'club_name': meet.clubName,
      'title': meet.title,
      'venue': meet.venue,
      'start': meet.start.toIso8601String(),
      'duration_min': meet.durationMin,
      'capacity': meet.capacity,
      'taken': meet.taken,
      'tag': meet.tag,
      'distance_km': meet.distanceKm,
      'price_label': meet.priceLabel,
      'level': meet.level,
      'host': meet.host,
      'invited': 0,
      'has_gift': 0,
    });
    if (me != null) {
      await _db.insert('meet_participants',
          {'meet_id': id, 'user_id': me!.id, 'joined_at': DateTime.now().toIso8601String()});
      final msgId = 'c-${DateTime.now().microsecondsSinceEpoch}';
      final card = ChatMessage(
        id: msgId,
        threadId: 't1',
        author: '',
        text: '',
        createdAt: DateTime.now(),
        system: 'Sebuah meet baru telah dibuat',
        meetCardId: id,
      );
      chat.add(card);
      await _db.insert('messages', {
        'id': msgId,
        'thread_id': 't1',
        'author_id': me!.id,
        'author': '',
        'text': '',
        'created_at': card.createdAt.toIso8601String(),
        'meet_card_id': id,
        'system': card.system,
      });
    }
    notifyListeners();
    return meet;
  }

  Future<void> deleteMeet(String id) async {
    meets.removeWhere((m) => m.id == id);
    await _db.delete('meets', where: 'id = ?', whereArgs: [id]);
    await _db.delete('meet_participants', where: 'meet_id = ?', whereArgs: [id]);
    notifyListeners();
  }
}

final appState = AppState();