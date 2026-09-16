import 'package:flutter/material.dart';

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '??';
  if (parts.length == 1) {
    final w = parts.first;
    return (w.length == 1 ? w : w.substring(0, 2)).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.level,
    required this.city,
    required this.sport,
    this.bio = '',
    this.phone = '',
    this.provider = 'password',
  });
  final String id;
  String name;
  final String email;
  String level;
  String city;
  String sport;
  String bio;
  String phone;

  /// How the account was created: `password`, `google`, or `guest`.
  final String provider;

  bool get isGuest => provider == 'guest';
  bool get isGoogle => provider == 'google';

  String get initials => _initialsOf(name);
  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory User.fromMap(Map<String, Object?> m) => User(
        id: m['id'] as String,
        name: m['name'] as String,
        email: m['email'] as String,
        level: m['level'] as String,
        city: m['city'] as String,
        sport: m['sport'] as String,
        bio: (m['bio'] as String?) ?? '',
        phone: (m['phone'] as String?) ?? '',
        provider: (m['provider'] as String?) ?? 'password',
      );
}

class Player {
  Player({required this.id, required this.name, required this.level, this.team});
  final String id;
  final String name;
  final String level; // Beginner / Intermediate / Advanced
  final String? team; // Red / Blue / Yellow / Green

  String get initials => _initialsOf(name);

  factory Player.fromMap(Map<String, Object?> m) => Player(
        id: m['id'] as String,
        name: m['name'] as String,
        level: m['level'] as String,
        team: m['team'] as String?,
      );
}

class ClubPost {
  ClubPost({
    required this.id,
    required this.author,
    required this.kind,
    required this.createdAt,
    required this.body,
    this.likes = 0,
    this.liked = false,
    this.comments = 0,
  });
  final String id;
  final String author;
  final String kind; // Announcement / Post
  final DateTime createdAt;
  final String body;
  int likes;
  bool liked;
  int comments;

  String get age => relativeAge(createdAt);

  factory ClubPost.fromMap(Map<String, Object?> m) => ClubPost(
        id: m['id'] as String,
        author: m['author'] as String,
        kind: m['kind'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        body: m['body'] as String,
        likes: m['likes'] as int,
        comments: (m['comments'] as int?) ?? 0,
      );
}

String relativeAge(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
  return '${(diff.inDays / 365).floor()} tahun lalu';
}

class Meet {
  Meet({
    required this.id,
    required this.clubName,
    required this.title,
    required this.venue,
    required this.start,
    required this.durationMin,
    required this.capacity,
    required this.taken,
    required this.tag,
    required this.distanceKm,
    required this.priceLabel,
    required this.level,
    this.host = 'User',
    this.invited = false,
    this.hasGift = false,
    this.joined = false,
  });
  final String id;
  final String clubName;
  final String title;
  final String venue;
  final DateTime start;
  final int durationMin;
  final int capacity;
  int taken;
  final String tag; // Social / Training / Comp
  final double distanceKm;
  final String priceLabel;
  final String level;
  final String host;
  final bool invited;
  final bool hasGift;
  bool joined;

  bool get full => taken >= capacity;
  int get spotsLeft => (capacity - taken).clamp(0, capacity);
  DateTime get end => start.add(Duration(minutes: durationMin));

  factory Meet.fromMap(Map<String, Object?> m) => Meet(
        id: m['id'] as String,
        clubName: m['club_name'] as String,
        title: m['title'] as String,
        venue: m['venue'] as String,
        start: DateTime.parse(m['start'] as String),
        durationMin: m['duration_min'] as int,
        capacity: m['capacity'] as int,
        taken: m['taken'] as int,
        tag: m['tag'] as String,
        distanceKm: (m['distance_km'] as num).toDouble(),
        priceLabel: m['price_label'] as String,
        level: (m['level'] as String?) ?? 'Semua level',
        host: (m['host'] as String?) ?? 'User',
        invited: (m['invited'] as int) == 1,
        hasGift: (m['has_gift'] as int) == 1,
      );
}

class Activity {
  Activity({
    required this.id,
    required this.title,
    required this.day,
    required this.time,
    required this.capacity,
    required this.going,
    this.attending = false,
  });
  final String id;
  final String title;
  final String day;
  final String time;
  final int capacity;
  int going;
  bool attending;

  factory Activity.fromMap(Map<String, Object?> m) => Activity(
        id: m['id'] as String,
        title: m['title'] as String,
        day: m['day'] as String,
        time: m['time'] as String,
        capacity: m['capacity'] as int,
        going: m['going'] as int,
      );
}

class GameMatch {
  GameMatch({
    required this.id,
    required this.round,
    required this.court,
    required this.sideA,
    required this.sideB,
    this.scoreA,
    this.scoreB,
  });
  final String id;
  final int round;
  final String court;
  final List<String> sideA;
  final List<String> sideB;
  int? scoreA;
  int? scoreB;

  bool get played => scoreA != null && scoreB != null;
  String get labelA => sideA.join('/');
  String get labelB => sideB.join('/');

  factory GameMatch.fromMap(Map<String, Object?> m) => GameMatch(
        id: m['id'] as String,
        round: m['round'] as int,
        court: m['court'] as String,
        sideA: (m['side_a'] as String).split(','),
        sideB: (m['side_b'] as String).split(','),
        scoreA: m['score_a'] as int?,
        scoreB: m['score_b'] as int?,
      );
}

class CompTeam {
  CompTeam({required this.code, required this.name, required this.pool});
  final String code;
  final String name;
  final String pool;

  factory CompTeam.fromMap(Map<String, Object?> m) => CompTeam(
        code: m['code'] as String,
        name: m['name'] as String,
        pool: m['pool'] as String,
      );
}

class PoolMatch {
  PoolMatch({
    required this.id,
    required this.pool,
    required this.a,
    required this.b,
    required this.scoreA,
    required this.scoreB,
  });
  final String id;
  final String pool;
  final String a;
  final String b;
  int scoreA;
  int scoreB;

  factory PoolMatch.fromMap(Map<String, Object?> m) => PoolMatch(
        id: m['id'] as String,
        pool: m['pool'] as String,
        a: m['a'] as String,
        b: m['b'] as String,
        scoreA: m['score_a'] as int,
        scoreB: m['score_b'] as int,
      );
}

class BracketSlot {
  BracketSlot({
    required this.id,
    required this.stage,
    required this.time,
    required this.seedA,
    required this.teamA,
    required this.scoreA,
    required this.seedB,
    required this.teamB,
    required this.scoreB,
  });
  final String id;
  final String stage; // SEMI FINALS / FINALS / THIRD PLACE
  final String time;
  final int seedA;
  final String teamA;
  int scoreA;
  final int seedB;
  final String teamB;
  int scoreB;

  bool get aWins => scoreA >= scoreB;

  factory BracketSlot.fromMap(Map<String, Object?> m) => BracketSlot(
        id: m['id'] as String,
        stage: m['stage'] as String,
        time: m['time'] as String,
        seedA: m['seed_a'] as int,
        teamA: m['team_a'] as String,
        scoreA: m['score_a'] as int,
        seedB: m['seed_b'] as int,
        teamB: m['team_b'] as String,
        scoreB: m['score_b'] as int,
      );
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.threadId,
    required this.author,
    required this.text,
    required this.createdAt,
    this.mine = false,
    this.reactions = 0,
    this.reacted = false,
    this.meetCardId,
    this.system,
  });
  final String id;
  final String threadId;
  final String author;
  final String text;
  final DateTime createdAt;
  final bool mine;
  int reactions;
  bool reacted;
  final String? meetCardId;
  final String? system;

  String get time {
    final h = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final p = createdAt.hour < 12 ? 'AM' : 'PM';
    return '$h:${createdAt.minute.toString().padLeft(2, '0')} $p';
  }

  factory ChatMessage.fromMap(Map<String, Object?> m, String meId) => ChatMessage(
        id: m['id'] as String,
        threadId: m['thread_id'] as String,
        author: m['author'] as String,
        text: m['text'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        mine: (m['author_id'] as String?) == meId,
        reactions: (m['reactions'] as int?) ?? 0,
        meetCardId: m['meet_card_id'] as String?,
        system: m['system'] as String?,
      );
}

class ChatThread {
  ChatThread({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.kind,
    this.unread = 0,
  });
  final String id;
  final String name;
  final String subtitle;
  final String kind; // club / meet / dm
  int unread;

  factory ChatThread.fromMap(Map<String, Object?> m) => ChatThread(
        id: m['id'] as String,
        name: m['name'] as String,
        subtitle: m['subtitle'] as String,
        kind: m['kind'] as String,
        unread: (m['unread'] as int?) ?? 0,
      );
}

class Standing {
  Standing(this.player);
  final String player;
  int played = 0;
  int wins = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;
  int get diff => pointsFor - pointsAgainst;
}

class Venue {
  const Venue({
    required this.name,
    required this.area,
    required this.courts,
    required this.rating,
    required this.priceFrom,
    required this.distanceKm,
  });
  final String name;
  final String area;
  final int courts;
  final double rating;
  final String priceFrom;
  final double distanceKm;
}

class Club {
  const Club({
    required this.id,
    required this.name,
    required this.sport,
    required this.city,
    required this.members,
    required this.about,
  });
  final String id;
  final String name;
  final String sport;
  final String city;
  final int members;
  final String about;
}

@immutable
class Sport {
  const Sport(this.name, this.icon);
  final String name;
  final IconData icon;

  @override
  bool operator ==(Object other) => other is Sport && other.name == name;
  @override
  int get hashCode => name.hashCode;
}
