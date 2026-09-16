// Regenerates every launcher icon and launch image from lib/widgets/logo.dart.
//
//   flutter test tool/gen_icons.dart
//
// It is a test file only because that is the cheapest way to get a real
// rasterizer; it asserts nothing and writes straight into ios/ and android/.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reclub/widgets/logo.dart';

typedef Draw = void Function(Canvas c);

Future<Uint8List> raster(int px, Draw draw) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.scale(px / ReclubBrand.grid);
  draw(c);
  final img = await rec.endRecording().toImage(px, px);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data!.buffer.asUint8List();
}

Future<void> write(String path, int px, Draw draw) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsBytes(await raster(px, draw));
  stdout.writeln('  ${f.path}  ${px}px');
}

/// Full-bleed square icon (iOS masks the corners itself).
void iosIcon(Canvas c) => ReclubBrand.paintIcon(c, radiusFactor: 0);

/// Rounded tile for the legacy Android launcher.
void androidIcon(Canvas c) => ReclubBrand.paintIcon(c);

void androidRound(Canvas c) => ReclubBrand.paintIcon(c, radiusFactor: 0.5);

/// Adaptive-icon background: the tile without the glyph, full bleed.
void adaptiveBg(Canvas c) => ReclubBrand.paintTile(c, radiusFactor: 0);

/// Adaptive-icon foreground: glyph only, inside the 66% safe zone.
void adaptiveFg(Canvas c) {
  c.translate(ReclubBrand.grid / 2, ReclubBrand.grid / 2);
  c.scale(0.60);
  c.translate(-ReclubBrand.grid / 2, -ReclubBrand.grid / 2);
  ReclubBrand.paintGlyph(c);
}

void monochrome(Canvas c) {
  c.translate(ReclubBrand.grid / 2, ReclubBrand.grid / 2);
  c.scale(0.60);
  c.translate(-ReclubBrand.grid / 2, -ReclubBrand.grid / 2);
  ReclubBrand.paintGlyph(c, color: Colors.black, accent: Colors.black);
}

/// Launch image: rounded tile with a little breathing room around it.
void launchLogo(Canvas c) {
  c.translate(ReclubBrand.grid / 2, ReclubBrand.grid / 2);
  c.scale(0.84);
  c.translate(-ReclubBrand.grid / 2, -ReclubBrand.grid / 2);
  ReclubBrand.paintIcon(c);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate app icons + launch images', () async {
    const iosDir = 'ios/Runner/Assets.xcassets';
    const res = 'android/app/src/main/res';

    stdout.writeln('iOS app icon');
    const iosSizes = <String, int>{
      'Icon-App-20x20@1x': 20, 'Icon-App-20x20@2x': 40, 'Icon-App-20x20@3x': 60,
      'Icon-App-29x29@1x': 29, 'Icon-App-29x29@2x': 58, 'Icon-App-29x29@3x': 87,
      'Icon-App-40x40@1x': 40, 'Icon-App-40x40@2x': 80, 'Icon-App-40x40@3x': 120,
      'Icon-App-60x60@2x': 120, 'Icon-App-60x60@3x': 180,
      'Icon-App-76x76@1x': 76, 'Icon-App-76x76@2x': 152,
      'Icon-App-83.5x83.5@2x': 167,
      'Icon-App-1024x1024@1x': 1024,
    };
    for (final e in iosSizes.entries) {
      await write('$iosDir/AppIcon.appiconset/${e.key}.png', e.value, iosIcon);
    }

    stdout.writeln('iOS launch image');
    await write('$iosDir/LaunchImage.imageset/LaunchImage.png', 96, launchLogo);
    await write('$iosDir/LaunchImage.imageset/LaunchImage@2x.png', 192, launchLogo);
    await write('$iosDir/LaunchImage.imageset/LaunchImage@3x.png', 288, launchLogo);

    stdout.writeln('Android launcher icons');
    const densities = <String, double>{
      'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4,
    };
    for (final d in densities.entries) {
      final dir = '$res/mipmap-${d.key}';
      await write('$dir/ic_launcher.png', (48 * d.value).round(), androidIcon);
      await write('$dir/ic_launcher_round.png', (48 * d.value).round(), androidRound);
      await write('$dir/ic_launcher_background.png', (108 * d.value).round(), adaptiveBg);
      await write('$dir/ic_launcher_foreground.png', (108 * d.value).round(), adaptiveFg);
      await write('$dir/ic_launcher_monochrome.png', (108 * d.value).round(), monochrome);
      await write('$dir/launch_logo.png', (96 * d.value).round(), launchLogo);
    }

    stdout.writeln('Preview');
    await write('.dart_tool/reclub_icon_preview.png', 512, androidIcon);
  });
}
