import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclub/data/app_state.dart';
import 'package:reclub/data/db.dart';
import 'package:reclub/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _boot(WidgetTester tester) async {
  // Real database I/O must run outside the fake-async zone of testWidgets.
  await tester.runAsync(() async {
    await AppDb.instance.reset();
    await appState.signIn('demo@reclub.id', 'reclub123');
  });
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ReclubApp());
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDb.instance.fileName = 'reclub_smoke_test.db';
  });

  setUp(() async {
    await AppDb.instance.reset();
    appState.stage = BootStage.loading;
    appState.me = null;
    appState.authDelayOverride = Duration.zero; // lewati animasi loading 3-5 detik
    appState.shellIndex = 0;
    appState.competeSeason = 4;
  });

  group('database', () {
    test('seed terisi dan akun demo bisa login', () async {
      final err = await appState.signIn('demo@reclub.id', 'reclub123');
      expect(err, isNull);
      expect(appState.me!.name, 'User');
      expect(appState.meets, isNotEmpty);
      expect(appState.members.length, 16);
      expect(appState.threads, isNotEmpty);
    });

    test('password salah ditolak', () async {
      expect(await appState.signIn('demo@reclub.id', 'salah'), isNotNull);
      expect(appState.signedIn, isFalse);
    });

    test('sign up membuat user baru dan menolak email ganda', () async {
      final err = await appState.signUp(
        name: 'Budi Santoso',
        email: 'budi@reclub.id',
        password: 'rahasia123',
        level: 'Beginner',
        userCity: 'Jakarta',
        userSport: 'Pickleball',
      );
      expect(err, isNull);
      expect(appState.me!.email, 'budi@reclub.id');

      await appState.signOut();
      final dup = await appState.signUp(
        name: 'Budi Lain',
        email: 'budi@reclub.id',
        password: 'rahasia123',
        level: 'Beginner',
        userCity: 'Jakarta',
        userSport: 'Pickleball',
      );
      expect(dup, isNotNull);
    });

    test('login Google membuat akun baru lalu memakai ulang akun yang sama', () async {
      final err = await appState.signInWithGoogle(name: 'Andi Pratama', email: 'andi.pratama@gmail.com');
      expect(err, isNull);
      expect(appState.me!.provider, 'google');
      expect(appState.me!.isGoogle, isTrue);
      final id = appState.me!.id;

      await appState.signOut();
      await appState.signInWithGoogle(name: 'Andi Pratama', email: 'ANDI.PRATAMA@gmail.com');
      expect(appState.me!.id, id, reason: 'email yang sama tidak boleh bikin user dobel');

      final rows = await AppDb.instance.db
          .query('users', where: 'LOWER(email) = ?', whereArgs: ['andi.pratama@gmail.com']);
      expect(rows.length, 1);
    });

    test('login Google memakai akun email yang sudah ada', () async {
      await appState.signInWithGoogle(name: 'User', email: 'demo@reclub.id');
      expect(appState.me!.id, 'u-demo');
    });

    test('mode tamu bisa dipakai lalu di-upgrade jadi akun beneran', () async {
      await appState.continueAsGuest();
      expect(appState.me!.isGuest, isTrue);
      final guestId = appState.me!.id;

      final meet = appState.meets.firstWhere((m) => !m.joined && !m.full);
      await appState.toggleJoinMeet(meet.id);

      final err = await appState.upgradeGuest(
        name: 'Sinta Dewi',
        email: 'sinta@reclub.id',
        password: 'rahasia123',
      );
      expect(err, isNull);
      expect(appState.me!.id, guestId, reason: 'akun tamu dipakai ulang, bukan bikin baru');
      expect(appState.me!.isGuest, isFalse);
      expect(appState.me!.provider, 'password');

      await appState.signOut();
      expect(await appState.signIn('sinta@reclub.id', 'rahasia123'), isNull);
      expect(appState.meets.firstWhere((m) => m.id == meet.id).joined, isTrue,
          reason: 'meet yang di-join saat jadi tamu harus ikut pindah');
    });

    test('gabung meet tersimpan lintas sesi', () async {
      await appState.signIn('demo@reclub.id', 'reclub123');
      final id = appState.meets.firstWhere((m) => !m.joined && !m.full).id;
      final before = appState.meetById(id)!.taken;

      expect(await appState.toggleJoinMeet(id), isTrue);
      expect(appState.meetById(id)!.taken, before + 1);

      // Sesi baru: sign out lalu sign in ulang, status join harus kembali.
      await appState.signOut();
      await appState.signIn('demo@reclub.id', 'reclub123');
      expect(appState.meetById(id)!.joined, isTrue);
      expect(appState.meetById(id)!.taken, before + 1);

      await appState.toggleJoinMeet(id);
      expect(appState.meetById(id)!.taken, before);
    });

    test('pesan baru tersimpan di thread yang benar', () async {
      await appState.signIn('demo@reclub.id', 'reclub123');
      final before = appState.messagesFor('t1').length;
      await appState.sendMessage('Halo semua', threadId: 't1');
      expect(appState.messagesFor('t1').length, before + 1);
      expect(appState.messagesFor('t1').last.text, 'Halo semua');
      expect(appState.messagesFor('t1').last.mine, isTrue);
    });

    test('buat meet menambah baris dan otomatis join', () async {
      await appState.signIn('demo@reclub.id', 'reclub123');
      final before = appState.meets.length;
      final m = await appState.createMeet(
        title: 'Sesi Pagi Sabtu',
        venue: 'GBK Arena',
        start: appState.today.add(const Duration(days: 2, hours: 7)),
        durationMin: 90,
        capacity: 8,
        tag: 'Social',
        level: 'Semua level',
        priceLabel: 'Rp50k',
      );
      expect(appState.meets.length, before + 1);
      expect(m.joined, isTrue);
      expect(appState.myMeets.map((x) => x.id), contains(m.id));
    });
  });

  group('fitur baru', () {
    test('chat ke akun sendiri ditolak, ke teman lain membuat thread', () async {
      await appState.signIn('demo@reclub.id', 'reclub123');
      final self = appState.friends.firstWhere(appState.isSelf);
      expect(await appState.openDirectThread(self), isNull);
      final other = appState.friends.firstWhere((p) => !appState.isSelf(p));
      final id = await appState.openDirectThread(other);
      expect(id, isNotNull);
      expect(appState.threads.any((t) => t.id == id && t.kind == 'dm'), isTrue);
    });

    test('olahraga favorit maksimal 3', () async {
      await appState.signIn('demo@reclub.id', 'reclub123');
      Future<String?> save(List<String> s) => appState.updateProfile(
            name: 'User',
            level: 'Advanced',
            userCity: 'Jakarta',
            userSports: s,
            bio: '',
            phone: '',
          );
      expect(await save(['Pickleball', 'Padel', 'Futsal', 'Basket']), isNotNull);
      expect(await save([]), isNotNull);
      expect(await save(['Pickleball', 'Padel', 'Futsal']), isNull);
      expect(appState.me!.sports, ['Pickleball', 'Padel', 'Futsal']);
    });

    test('pendaftaran tim VFFL Season 5 tersimpan', () async {
      await appState.signIn('demo@reclub.id', 'reclub123');
      expect(appState.registrationFor(5), isNull);
      final err = await appState.registerCompTeam(
        season: 5,
        teamName: 'Bandung Smashers',
        memberNames: ['User', 'Rina Ayu', 'Dimas Putra', 'Kyle Adhi'],
        method: 'QRIS',
      );
      expect(err, isNull);
      expect(appState.registrationFor(5)!.teamName, 'Bandung Smashers');
      // Pendaftaran kedua di musim yang sama ditolak.
      expect(
        await appState.registerCompTeam(
          season: 5,
          teamName: 'Tim Lain',
          memberNames: ['User', 'A', 'B', 'C'],
          method: 'QRIS',
        ),
        isNotNull,
      );
    });
  });

  group('perhitungan', () {
    test('klasemen ikut skor yang disimpan', () async {
      await appState.signIn('demo@reclub.id', 'reclub123');
      await appState.setScore('g5', 11, 4);
      final s = appState.standings;
      expect(s, isNotEmpty);
      expect(s.first.wins, greaterThan(0));
      expect(s.map((e) => e.player), contains('User'));
    });

    test('pool table diurutkan berdasarkan poin', () async {
      await appState.signIn('demo@reclub.id', 'reclub123');
      final poolA = appState.poolTable('A');
      expect(poolA.length, greaterThan(1));
      expect(poolA.first['pts'], greaterThanOrEqualTo(poolA.last['pts'] as int));
    });
  });

  group('UI', () {
    testWidgets('semua tab utama render tanpa error', (tester) async {
      await _boot(tester);
      for (final label in ['Klub', 'Meet', 'Compete', 'Chat', 'Discover']) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tab $label');
      }
    });

    testWidgets('layar login tampil saat belum masuk', (tester) async {
      await tester.runAsync(() async {
        await appState.boot();
        await appState.completeOnboarding();
        await appState.signOut();
      });

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ReclubApp());
      await tester.pumpAndSettle();
      expect(find.text('Masuk'), findsWidgets);
    });
  });
}