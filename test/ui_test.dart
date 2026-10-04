import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclub/data/app_state.dart';
import 'package:reclub/data/db.dart';
import 'package:reclub/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Renders every page and every in-page tab, failing on any layout overflow.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDb.instance.fileName = 'reclub_ui_test.db';
  });

  setUp(() async {
    await AppDb.instance.reset();
    appState.me = null;
    appState.stage = BootStage.loading;
    appState.authDelayOverride = Duration.zero; // lewati animasi loading 3-5 detik
    appState.shellIndex = 0;
    appState.competeSeason = 4;
  });

  Future<void> boot(WidgetTester tester) async {
    await tester.runAsync(() async {
      await appState.signIn('demo@reclub.id', 'reclub123');
    });
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ReclubApp());
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'setelah menekan "$label"');
  }

  final pages = <String, List<String>>{
    'Discover': ['KLUB', 'KOMPETISI', 'VENUE', 'TEMAN', 'MEET'],
    'Klub': ['AKTIVITAS', 'ANGGOTA', 'TENTANG', 'BERANDA'],
    'Meet': ['PESERTA', 'MATCH', 'DETAIL'],
    'Compete': ['DETAIL', 'PESERTA', 'MATCH', 'HASIL'],
    'Chat': [],
  };

  pages.forEach((page, tabs) {
    testWidgets('halaman $page dan seluruh tabnya render tanpa overflow', (tester) async {
      await boot(tester);
      await tapText(tester, page);
      for (final t in tabs) {
        await tapText(tester, t);
      }
    });
  });

  testWidgets('sub-tab Meet: klasemen, semua match, match saya', (tester) async {
    await boot(tester);
    await tapText(tester, 'Meet');
    await tapText(tester, 'MATCH');
    for (final t in ['Semua match', 'Match saya', 'Klasemen']) {
      await tapText(tester, t);
    }
  });

  testWidgets('sub-tab Compete: juara, pool, playoff, statistik', (tester) async {
    await boot(tester);
    await tapText(tester, 'Compete');
    await tapText(tester, 'HASIL');
    for (final t in ['Juara', 'Playoff', 'Statistik', 'Pool']) {
      await tapText(tester, t);
    }
  });

  testWidgets('filter inbox chat', (tester) async {
    await boot(tester);
    await tapText(tester, 'Chat');
    for (final t in ['Klub', 'Meet', 'Pribadi', 'Semua']) {
      await tester.tap(find.text(t).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'filter $t');
    }
  });
}