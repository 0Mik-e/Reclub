import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'meet_page.dart';

/// Inbox + conversation. When [embedded] is true only the conversation for
/// [threadId] is rendered (used inside the Meet and Compete pages).
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.embedded = false, this.threadId});
  final bool embedded;
  final String? threadId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _open;
  String _q = '';
  int _filter = 0;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Conversation(threadId: widget.threadId ?? 't1', embedded: true);
    }
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final id = _open;
        if (id != null && appState.threads.any((t) => t.id == id)) {
          return Conversation(threadId: id, onBack: () => setState(() => _open = null));
        }
        return _inbox(context);
      },
    );
  }

  // ------------------------------------------------------------------ inbox
  Widget _inbox(BuildContext context) {
    final kinds = ['Semua', 'Klub', 'Meet', 'Pribadi'];
    final kindKey = ['', 'club', 'meet', 'dm'];
    var list = appState.threads.where((t) {
      final okKind = _filter == 0 || t.kind == kindKey[_filter];
      final okQ = _q.isEmpty ||
          t.name.toLowerCase().contains(_q.toLowerCase()) ||
          t.subtitle.toLowerCase().contains(_q.toLowerCase());
      return okKind && okQ;
    }).toList();
    list.sort((a, b) {
      final ma = appState.lastMessageOf(a.id);
      final mb = appState.lastMessageOf(b.id);
      if (ma == null || mb == null) return 0;
      return mb.createdAt.compareTo(ma.createdAt);
    });
    final unread = appState.threads.fold<int>(0, (s, t) => s + t.unread);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  const Text('Chat', style: T.display),
                  const SizedBox(width: 10),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.green, borderRadius: R.pill),
                      child: Text('$unread baru',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  const Spacer(),
                  CircleIconButton(
                    icon: Icons.edit_outlined,
                    onTap: () => _newChat(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: AppField(
                controller: _search,
                hint: 'Cari obrolan atau orang',
                icon: Icons.search_rounded,
                onChanged: (v) => setState(() => _q = v),
                suffix: _q.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () {
                          _search.clear();
                          setState(() => _q = '');
                        },
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: PillSwitch(
                items: kinds,
                index: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'Tidak ada obrolan',
                      subtitle: 'Coba ubah filter atau kata kunci pencarian.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _threadTile(context, list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _threadTile(BuildContext context, ChatThread t) {
    final last = appState.lastMessageOf(t.id);
    return GestureDetector(
      onTap: () {
        appState.openThread(t.id);
        setState(() => _open = t.id);
      },
      onLongPress: () => _threadMenu(context, t),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: R.lg, boxShadow: Shadows.card),
        child: Row(
          children: [
            Avatar(
              label: t.name,
              size: 48,
              square: t.kind != 'dm',
              badge: t.kind == 'dm'
                  ? Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.title),
                      ),
                      const SizedBox(width: 8),
                      Text(last == null ? '' : last.time, style: T.small.copyWith(fontSize: 10.5)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          last == null ? t.subtitle : '${last.mine ? 'Kamu' : last.author.split(' ').first}: ${last.text}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.small.copyWith(
                            color: t.unread > 0 ? AppColors.ink : AppColors.muted,
                            fontWeight: t.unread > 0 ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (t.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.green, borderRadius: R.pill),
                          child: Text('${t.unread}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _threadMenu(BuildContext context, ChatThread t) {
    showAppSheet(
      context,
      title: t.name,
      subtitle: t.subtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.mark_email_read_outlined, size: 20),
            title: const Text('Tandai sudah dibaca', style: T.bodyStrong),
            onTap: () {
              Navigator.pop(context);
              appState.openThread(t.id);
              toast(context, 'Ditandai sudah dibaca');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_off_outlined, size: 20),
            title: const Text('Bisukan notifikasi', style: T.bodyStrong),
            onTap: () {
              Navigator.pop(context);
              toast(context, '${t.name} dibisukan');
            },
          ),
        ],
      ),
    );
  }

  void _newChat(BuildContext context) {
    showAppSheet(
      context,
      title: 'Mulai obrolan',
      subtitle: 'Pilih anggota klub untuk dikirimi pesan',
      child: SizedBox(
        height: 340,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            for (final p in appState.members.where((p) => p.name != appState.me?.name))
              ListTile(
                leading: Avatar(label: p.name, size: 38),
                title: Text(p.name, style: T.title),
                subtitle: Text(p.level, style: T.small),
                onTap: () {
                  Navigator.pop(context);
                  final t = appState.threads.firstWhere(
                    (t) => t.name == p.name,
                    orElse: () => appState.threads.last,
                  );
                  appState.openThread(t.id);
                  setState(() => _open = t.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class Conversation extends StatefulWidget {
  const Conversation({super.key, required this.threadId, this.embedded = false, this.onBack});
  final String threadId;
  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      final can = _input.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await appState.sendMessage(text, threadId: widget.threadId);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final thread = appState.threads.firstWhere(
          (t) => t.id == widget.threadId,
          orElse: () => appState.threads.first,
        );
        final msgs = appState.messagesFor(thread.id);
        final body = Column(
          children: [
            Expanded(
              child: msgs.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Belum ada pesan',
                      subtitle: 'Sapa duluan — pesan tersimpan di database lokal.',
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      itemCount: msgs.length,
                      itemBuilder: (context, i) {
                        final m = msgs[i];
                        final prev = i == 0 ? null : msgs[i - 1];
                        final showDay = prev == null || !_sameDay(prev.createdAt, m.createdAt);
                        return Column(
                          children: [
                            if (showDay) _dayChip(m.createdAt),
                            _bubble(context, m, prev),
                          ],
                        );
                      },
                    ),
            ),
            _composer(context),
          ],
        );

        if (widget.embedded) return Container(color: AppColors.canvas, child: body);

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _bar(context, thread),
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dayChip(DateTime t) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
    final label = switch (diff) {
      0 => 'HARI INI',
      1 => 'KEMARIN',
      _ => '${t.day}/${t.month}/${t.year}',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: AppColors.chip, borderRadius: R.pill),
        child: Text(label, style: T.caps.copyWith(fontSize: 9.5)),
      ),
    );
  }

  Widget _bar(BuildContext context, ChatThread t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_rounded,
            size: 36,
            bg: Colors.white,
            border: false,
            onTap: widget.onBack ?? () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Avatar(label: t.name, size: 38, square: t.kind != 'dm'),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.title),
                const SizedBox(height: 2),
                Text(t.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
              ],
            ),
          ),
          CircleIconButton(
            icon: Icons.info_outline_rounded,
            size: 36,
            bg: Colors.white,
            border: false,
            onTap: () => toast(context, '${t.subtitle} · thread ${t.id}'),
          ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, ChatMessage m, ChatMessage? prev) {
    if (m.system != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: AppColors.lavender, borderRadius: R.pill),
          child: Text(m.text, textAlign: TextAlign.center, style: T.small.copyWith(color: AppColors.blue)),
        ),
      );
    }

    final grouped = prev != null && prev.author == m.author && prev.system == null;
    final mine = m.mine;
    return Padding(
      padding: EdgeInsets.only(top: grouped ? 3 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!mine)
            SizedBox(
              width: 34,
              child: grouped ? null : Avatar(label: m.author, size: 30),
            ),
          if (!mine) const SizedBox(width: 6),
          Flexible(
            child: GestureDetector(
              onDoubleTap: () => appState.react(m.id),
              onLongPress: () => _messageMenu(context, m),
              child: Column(
                crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!grouped && !mine)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 3),
                      child: Text(m.author, style: T.small.copyWith(fontSize: 10.5)),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                    decoration: BoxDecoration(
                      color: mine ? AppColors.ink : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(mine ? 16 : 5),
                        bottomRight: Radius.circular(mine ? 5 : 16),
                      ),
                      boxShadow: mine ? null : Shadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.text,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: mine ? Colors.white : AppColors.ink,
                          ),
                        ),
                        if (m.meetCardId != null) ...[
                          const SizedBox(height: 10),
                          _meetCard(context, m.meetCardId!, mine),
                        ],
                        const SizedBox(height: 4),
                        Text(m.time,
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: mine ? Colors.white38 : AppColors.faint)),
                      ],
                    ),
                  ),
                  if (m.reactions > 0)
                    Transform.translate(
                      offset: const Offset(0, -5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: m.reacted ? AppColors.yellowSoft : Colors.white,
                          borderRadius: R.pill,
                          boxShadow: Shadows.card,
                        ),
                        child: Text('🔥 ${m.reactions}', style: const TextStyle(fontSize: 10.5)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meetCard(BuildContext context, String meetId, bool mine) {
    final meet = appState.meetById(meetId);
    if (meet == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetPage(meetId: meet.id))),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: mine ? Colors.white.withValues(alpha: 0.10) : AppColors.canvas,
          borderRadius: R.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_tennis_rounded, size: 14, color: mine ? AppColors.yellow : AppColors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(meet.clubName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: T.caps.copyWith(fontSize: 9, color: mine ? Colors.white54 : AppColors.muted)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(meet.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13, height: 1.25, fontWeight: FontWeight.w800, color: mine ? Colors.white : AppColors.ink)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text('${meet.taken}/${meet.capacity} slot · ${meet.priceLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: T.small.copyWith(fontSize: 10.5, color: mine ? Colors.white60 : AppColors.muted)),
                ),
                Icon(Icons.chevron_right_rounded, size: 16, color: mine ? Colors.white60 : AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _messageMenu(BuildContext context, ChatMessage m) {
    showAppSheet(
      context,
      title: 'Pesan dari ${m.mine ? 'kamu' : m.author}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Text('🔥', style: TextStyle(fontSize: 19)),
            title: Text(m.reacted ? 'Batalkan reaksi' : 'Beri reaksi', style: T.bodyStrong),
            onTap: () {
              Navigator.pop(context);
              appState.react(m.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded, size: 20),
            title: const Text('Salin teks', style: T.bodyStrong),
            onTap: () {
              Navigator.pop(context);
              toast(context, 'Teks disalin', icon: Icons.copy_rounded);
            },
          ),
          if (m.mine)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.red),
              title: const Text('Hapus pesan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.red)),
              onTap: () {
                Navigator.pop(context);
                appState.deleteMessage(m.id);
                toast(context, 'Pesan dihapus');
              },
            ),
        ],
      ),
    );
  }

  Widget _composer(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom * 0.2),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final q in const ['👍', 'Ikut!', 'Otw 🚗', 'Gas 🔥', 'Sorry telat'])
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: GestureDetector(
                      onTap: () async {
                        await appState.sendMessage(q, threadId: widget.threadId);
                        if (!context.mounted) return;
                        WidgetsBinding.instance.addPostFrameCallback((_) => _toBottom());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.chip, borderRadius: R.pill),
                        child: Text(q, style: T.small.copyWith(color: AppColors.ink70)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 110),
                  decoration: BoxDecoration(color: AppColors.canvas, borderRadius: R.xl),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan…',
                      hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.faint),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              GestureDetector(
                onTap: _canSend ? _send : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _canSend ? AppColors.ink : AppColors.chip,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_upward_rounded,
                      size: 20, color: _canSend ? Colors.white : AppColors.faint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
