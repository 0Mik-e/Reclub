import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_state.dart';
import 'pages/auth_page.dart';
import 'pages/chat_page.dart';
import 'pages/club_page.dart';
import 'pages/compete_page.dart';
import 'pages/discover_page.dart';
import 'pages/meet_page.dart';
import 'pages/onboarding_page.dart';
import 'theme.dart';
import 'widgets/logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(systemLightOverlay);
  appState.boot();
  runApp(const ReclubApp());
}

class ReclubApp extends StatelessWidget {
  const ReclubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reclub',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final child = switch (appState.stage) {
            BootStage.loading => const _Splash(),
            BootStage.onboarding => const OnboardingPage(),
            BootStage.auth => const AuthPage(),
            BootStage.ready => const RootShell(),
          };
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: KeyedSubtree(key: ValueKey(appState.stage), child: child),
          );
        },
      ),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.25, 1, curve: Curves.easeOut));
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.72, end: 1).animate(pop),
              child: const ReclubMark(size: 104),
            ),
            const SizedBox(height: 22),
            FadeTransition(
              opacity: fade,
              child: const Text('reclub',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -1)),
            ),
            const SizedBox(height: 6),
            FadeTransition(
              opacity: fade,
              child: const Text('Main bareng, jadi lebih seru',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: fade,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.faint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _NavItem {
  const _NavItem(this.icon, this.active, this.label);
  final IconData icon;
  final IconData active;
  final String label;
}

const _navItems = [
  _NavItem(Icons.search_rounded, Icons.search_rounded, 'Discover'),
  _NavItem(Icons.groups_outlined, Icons.groups_rounded, 'Klub'),
  _NavItem(Icons.sports_tennis_outlined, Icons.sports_tennis_rounded, 'Meet'),
  _NavItem(Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'Compete'),
  _NavItem(Icons.forum_outlined, Icons.forum_rounded, 'Chat'),
];

class _RootShellState extends State<RootShell> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final unread = appState.threads.fold<int>(0, (a, t) => a + t.unread);
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: IndexedStack(
            index: appState.shellIndex,
            children: [
              const DiscoverPage(),
              const ClubPage(),
              MeetPage(meetId: appState.featuredMeet.id, showBack: false),
              const CompetePage(),
              const ChatPage(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.hairline)),
              boxShadow: [BoxShadow(color: Color(0x0A101828), blurRadius: 20, offset: Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    for (var i = 0; i < _navItems.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: _navItems[i],
                          selected: i == appState.shellIndex,
                          badge: i == 4 && unread > 0 ? unread : 0,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            appState.goToTab(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap, this.badge = 0});
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.faint;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(selected ? item.active : item.icon, size: 23, color: color),
              if (badge > 0)
                Positioned(
                  right: -6,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 15),
                    decoration: BoxDecoration(color: AppColors.red, borderRadius: R.pill),
                    alignment: Alignment.center,
                    child: Text('$badge',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}