import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _Slide {
  const _Slide(this.badge, this.title, this.body, this.color, this.icon);
  final String badge;
  final String title;
  final String body;
  final Color color;
  final IconData icon;
}

const _slides = [
  _Slide('MEET UP', 'Cari lawan main\ndalam hitungan detik',
      'Lihat semua sesi pickleball & padel di sekitarmu, lengkap dengan sisa slot, harga, dan jarak.',
      AppColors.yellow, Icons.sports_tennis),
  _Slide('RUN A CLUB', 'Kelola klub tanpa\nspreadsheet',
      'Jadwal mingguan, absensi, pengumuman, dan anggota — semuanya dalam satu tempat.',
      AppColors.green, Icons.groups_rounded),
  _Slide('COMPETE', 'Skor, klasemen,\ndan bracket otomatis',
      'Masukkan skor sekali, standings americano dan bracket playoff langsung update.',
      AppColors.blue, Icons.emoji_events_rounded),
];

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      appState.completeOnboarding();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _slides[_index];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  const ReclubWordmark(size: 28),
                  const Spacer(),
                  TextButton(
                    onPressed: appState.completeOnboarding,
                    child: const Text('Lewati',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index ? s.color : AppColors.hairline,
                            borderRadius: R.pill,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: _index == _slides.length - 1 ? 'Mulai sekarang' : 'Lanjut',
                      kind: BtnKind.dark,
                      height: 52,
                      icon: _index == _slides.length - 1 ? Icons.arrow_forward_rounded : null,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _BlobPainter(slide.color),
                  child: Center(
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: Shadows.raised,
                      ),
                      child: Icon(slide.icon, size: 48, color: slide.color),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Tag(slide.badge, color: slide.color, bg: slide.color.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Text(slide.title, style: T.display),
          const SizedBox(height: 12),
          Text(slide.body, style: T.body.copyWith(fontSize: 15)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r * 0.92, Paint()..color = color.withValues(alpha: 0.10));
    canvas.drawCircle(c, r * 0.68, Paint()..color = color.withValues(alpha: 0.16));

    final dot = Paint()..color = color.withValues(alpha: 0.55);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi * 2 / 12 - math.pi / 2;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 0.83, 3.2, dot);
    }
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.45);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.55), -2.4, 1.6, false, arc);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.55), 0.9, 1.1, false, arc);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => old.color != color;
}
