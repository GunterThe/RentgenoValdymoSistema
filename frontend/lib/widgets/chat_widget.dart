import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../services/api.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';

class ChatWidget extends StatefulWidget {
  final String? initialOtherUserId;
  const ChatWidget({super.key, this.initialOtherUserId});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatMessage {
  final int id;
  final String siuntejoId;
  final String siuntejoVardas;
  final String tekstas;
  final DateTime siustoLaikas;
  final String gavetojoId;

  const _ChatMessage({
    required this.id,
    required this.siuntejoId,
    required this.siuntejoVardas,
    required this.tekstas,
    required this.siustoLaikas,
    required this.gavetojoId,
  });

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawTime = json['siustoLaikas'] ?? json['SiustoLaikas'] ?? '';
    return _ChatMessage(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      siuntejoId: (json['siuntejoId'] ?? json['SiuntejoId'] ?? '').toString(),
      siuntejoVardas:
          (json['siuntejoVardas'] ?? json['SiuntejoVardas'] ?? 'Nežinomas')
              .toString(),
      tekstas: (json['tekstas'] ?? json['Tekstas'] ?? '').toString(),
      siustoLaikas: rawTime.toString().isEmpty
          ? DateTime.now()
          : DateTime.tryParse(rawTime.toString()) ?? DateTime.now(),
      gavetojoId: (json['gavetojoId'] ?? json['GavetojoId'] ?? '').toString(),
    );
  }
}

class _UserItem {
  final String id;
  final String display;
  _UserItem(this.id, this.display);
}

class _ChatWidgetState extends State<ChatWidget> with SingleTickerProviderStateMixin {
  HubConnection? _connection;
  final Set<String> _onlineUsers = {};
  final Set<String> _typingUsers = {};
  final Map<String, Timer> _remoteTypingTimers = {};
  final List<_ChatMessage> _messages = [];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _connected = false;
  bool _connecting = false;
  String? _error;
  bool _sending = false;
  Timer? _localTypingTimer;
  late final AnimationController _typingAnimController;
  late final Animation<double> _dot1Anim;
  late final Animation<double> _dot2Anim;
  late final Animation<double> _dot3Anim;

  List<_UserItem> _users = [];
  String? _selectedUserId;

  List<Map<String, dynamic>> _conversations = [];
  bool _expanded = false;
  bool _inConversation = false;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.initialOtherUserId;
    _typingAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _dot1Anim = CurvedAnimation(parent: _typingAnimController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOut));
    _dot2Anim = CurvedAnimation(parent: _typingAnimController, curve: const Interval(0.15, 0.75, curve: Curves.easeInOut));
    _dot3Anim = CurvedAnimation(parent: _typingAnimController, curve: const Interval(0.3, 0.9, curve: Curves.easeInOut));
    _connect();
    _loadUsers();
  }

  String get _currentUserId => AuthService.instance.currentUserId ?? '';

  Future<void> _loadUsers() async {
    try {
      final list = await Api.fetchNaudotojaiForChat();
      final items = <_UserItem>[];
      for (final u in list) {
        final map = u as Map<String, dynamic>;
        final id = (map['id'] ?? map['id'] ?? '').toString();
        final vardas = (map['vardas'] ?? '').toString();
        final pavarde = (map['pavarde'] ?? '').toString();
        final disp = ('$vardas $pavarde').trim();
        if (id == _currentUserId) continue;
        items.add(_UserItem(id, disp.isEmpty ? id : disp));
      }
      if (!mounted) return;
      setState(() => _users = items);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _connect() async {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      final conn = HubConnectionBuilder()
          .withUrl(
            '${ApiConfig.baseUrl}/chathub',
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  await AuthService.instance.getValidAccessToken() ?? '',
            ),
          )
          .build();

      conn.on('ReceiveMessage', _onReceiveMessage);
      conn.on('ChatHistory', _onChatHistory);
      conn.on('Conversations', _onConversations);
      conn.on('OnlineUsers', _onOnlineUsers);
      conn.on('UserOnline', _onUserOnline);
      conn.on('UserOffline', _onUserOffline);
      conn.on('UserTyping', _onUserTyping);
      conn.on('UserStoppedTyping', _onUserStoppedTyping);
      conn.onclose(({Exception? error}) {
        if (!mounted) return;
        setState(() => _connected = false);
      });

      await conn.start();

      if (!mounted) return;
      _connection = conn;
      setState(() {
        _connected = true;
        _connecting = false;
      });

      await conn.invoke('GetConversations', args: [50]);
      if (_selectedUserId != null && _selectedUserId!.isNotEmpty) {
        await conn.invoke('GetHistory', args: [_selectedUserId!, 50]);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _connecting = false;
        _connected = false;
      });
    }
  }

  void _onOnlineUsers(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final list = args[0];
    if (list is! List) return;
    final ids = list.whereType<Object>().map((e) => e.toString()).toSet();
    if (!mounted) return;
    setState(() {
      _onlineUsers.clear();
      _onlineUsers.addAll(ids);
    });
  }

  void _onUserOnline(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final id = args[0]?.toString() ?? '';
    if (id.isEmpty) return;
    if (!mounted) return;
    setState(() => _onlineUsers.add(id));
  }

  void _onUserOffline(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final id = args[0]?.toString() ?? '';
    if (id.isEmpty) return;
    if (!mounted) return;
    setState(() => _onlineUsers.remove(id));
  }

  void _onUserTyping(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final id = args[0]?.toString() ?? '';
    if (id.isEmpty) return;
    // add and schedule removal
    if (!mounted) return;
    setState(() {
      _typingUsers.add(id);
    });
    _remoteTypingTimers[id]?.cancel();
    _remoteTypingTimers[id] = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _typingUsers.remove(id);
      });
      _remoteTypingTimers.remove(id);
      // stop animation if no one is typing
      if (_typingUsers.isEmpty) _stopTypingAnimation();
    });
    // ensure animation running
    _startTypingAnimationIfNeeded();
  }

  void _onUserStoppedTyping(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final id = args[0]?.toString() ?? '';
    if (id.isEmpty) return;
    if (!mounted) return;
    _remoteTypingTimers[id]?.cancel();
    _remoteTypingTimers.remove(id);
    setState(() => _typingUsers.remove(id));
    if (_typingUsers.isEmpty) _stopTypingAnimation();
  }

  void _onReceiveMessage(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final data = args[0];
    if (data is! Map) return;
    final msg = _ChatMessage.fromJson(Map<String, dynamic>.from(data));
    if (!mounted) return;
    // Only add message if it belongs to current conversation
    if (_selectedUserId == null) return;
    final other = _selectedUserId!;
    final me = _currentUserId;
    final belongs = (msg.siuntejoId == me && msg.gavetojoId == other) ||
        (msg.siuntejoId == other && msg.gavetojoId == me);
    if (!belongs) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  void _onChatHistory(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final list = args[0];
    if (list is! List) return;
    final msgs = list
        .whereType<Map>()
        .map((e) => _ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _messages.addAll(msgs);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _onConversations(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final list = args[0];
    if (list is! List) return;
    final convs = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (!mounted) return;
    setState(() {
      _conversations = convs;
    });
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || !_connected || _sending || _selectedUserId == null) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      // stop typing when sending
      _stopTyping();
      await _connection!.invoke('SendMessage', args: [_selectedUserId!, text]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida siunčiant žinutę: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _stopTyping() {
    _localTypingTimer?.cancel();
    _localTypingTimer = null;
    if (_connection != null && _connection!.state == HubConnectionState.Connected && _selectedUserId != null) {
      try {
        _connection!.invoke('StopTyping', args: [_selectedUserId!]);
      } catch (_) {}
    }
  }

  void _startTypingAnimationIfNeeded() {
    if (!_typingAnimController.isAnimating) {
      _typingAnimController.repeat();
    }
  }

  void _stopTypingAnimation() {
    if (_typingAnimController.isAnimating) {
      _typingAnimController.stop();
      _typingAnimController.reset();
    }
  }

  @override
  void dispose() {
    _connection?.stop();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  String _fmtTime(DateTime dt) {
    final l = dt.toLocal();
    final h = l.hour.toString().padLeft(2, '0');
    final m = l.minute.toString().padLeft(2, '0');
    final d = l.day.toString().padLeft(2, '0');
    final mo = l.month.toString().padLeft(2, '0');
    return '${l.year}-$mo-$d $h:$m';
  }

  Widget _buildMessageArea(ColorScheme cs) {
    return Column(
      children: [
        if (_connecting) LinearProgressIndicator(color: cs.primary),
        if (_error != null)
          MaterialBanner(
            content: Text('Nepavyko prisijungti: $_error'),
            actions: [
              TextButton(onPressed: _connect, child: const Text('Bandyti iš naujo')),
            ],
          ),
        if (_selectedUserId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayNameFor(_selectedUserId!),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _onlineUsers.contains(_selectedUserId) ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_typingUsers.contains(_selectedUserId)) Text('Rašo...'),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: _messages.isEmpty && !_connecting
              ? Center(
                  child: Text(
                    _connected
                        ? 'Dar nėra žinučių. Parašykite pirmą!'
                        : 'Nesujungta...',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildMessage(_messages[i]),
                ),
        ),
        if (_typingUsers.contains(_selectedUserId))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: _buildTypingBubble(),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: _connected && !_sending && _selectedUserId != null,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: (v) {
                    if (!_connected || _selectedUserId == null) return;
                    try {
                      _connection?.invoke('Typing', args: [_selectedUserId!]);
                    } catch (_) {}
                    _localTypingTimer?.cancel();
                    _localTypingTimer = Timer(const Duration(milliseconds: 1400), () {
                      _stopTyping();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _connected && !_sending && _selectedUserId != null ? _sendMessage : null,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    final cs = Theme.of(context).colorScheme;
    final isOwn = msg.siuntejoId == _currentUserId;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOwn ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isOwn)
              Text(
                msg.siuntejoVardas,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isOwn ? cs.onPrimary.withAlpha(200) : cs.primary,
                ),
              ),
            Text(
              msg.tekstas,
              style: TextStyle(
                color: isOwn ? cs.onPrimary : cs.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _fmtTime(msg.siustoLaikas),
              style: TextStyle(
                fontSize: 11,
                color:
                    isOwn ? cs.onPrimary.withAlpha(160) : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    // Collapsible chat panel anchored bottom-right within parent
    final collapsedSize = 64.0;
    final expandedWidth = isWide ? 760.0 : MediaQuery.sizeOf(context).width * 0.95;
    final expandedHeight = isWide ? 480.0 : 520.0;

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: _expanded ? expandedWidth : collapsedSize,
              height: _expanded ? expandedHeight : collapsedSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primaryContainer.withAlpha(31), cs.surface],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _expanded ? _buildExpandedPanel(cs, isWide) : _buildCollapsedButton(cs),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedButton(ColorScheme cs) {
    return InkWell(
      onTap: () => setState(() => _expanded = true),
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: cs.onSurface, size: 28),
            const SizedBox(height: 4),
            Text('Pokalbiai', style: TextStyle(color: cs.onSurface, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(ColorScheme cs, bool isWide) {
    return Column(
      children: [
        // header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              if (_inConversation)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _inConversation = false),
                ),
              Expanded(child: Text('Pokalbiai', style: const TextStyle(fontWeight: FontWeight.w700))),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Naujas pokalbis',
                onPressed: () async {
                  final pick = await showDialog<String?>(
                    context: context,
                    builder: (dctx) => SimpleDialog(
                      title: const Text('Pasirinkite vartotoją'),
                      children: _users.map((u) => SimpleDialogOption(
                            onPressed: () => Navigator.of(dctx).pop(u.id),
                            child: Text(u.display),
                          )).toList(),
                    ),
                  );
                  if (pick == null) return;
                  setState(() {
                    _selectedUserId = pick;
                    _messages.clear();
                    _inConversation = true;
                  });
                  if (_connection != null && _connection!.state == HubConnectionState.Connected) {
                    await _connection!.invoke('GetHistory', args: [pick, 50]);
                    await _connection!.invoke('GetConversations', args: [50]);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _expanded = false;
                  _inConversation = false;
                }),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _inConversation ? _buildMessageArea(cs) : _buildConversationList(),
        ),
      ],
    );
  }

  Widget _buildConversationList() {
    return Container(
      color: Colors.transparent,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (_, i) {
          final c = _conversations[i];
          final otherId = (c['otherId'] ?? c['otherid'] ?? '').toString();
          final name = (c['otherName'] ?? c['othername'] ?? '').toString();
          final lastText = (c['lastText'] ?? '').toString();
          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(child: Text(name.isEmpty ? '?': name[0].toUpperCase())),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _onlineUsers.contains(otherId) ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(name.isEmpty ? otherId : name),
            subtitle: Text(lastText, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () async {
              setState(() {
                _selectedUserId = otherId;
                _messages.clear();
                _inConversation = true;
              });
              if (_connection != null && _connection!.state == HubConnectionState.Connected) {
                await _connection!.invoke('GetHistory', args: [otherId, 50]);
              }
            },
          );
        },
      ),
    );
  }

  String _displayNameFor(String id) {
    final u = _users.firstWhere((e) => e.id == id, orElse: () => _UserItem(id, id));
    if (u.display.isNotEmpty && u.display != id) return u.display;
    for (final c in _conversations) {
      final other = (c['otherId'] ?? c['otherid'] ?? '').toString();
      final otherName = (c['otherName'] ?? c['othername'] ?? '').toString();
      if (other == id && otherName.isNotEmpty) return otherName;
    }
    return id;
  }

  Widget _buildTypingBubble() {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 80),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FadeTransition(opacity: _dot1Anim, child: _dot()),
                  FadeTransition(opacity: _dot2Anim, child: _dot()),
                  FadeTransition(opacity: _dot3Anim, child: _dot()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot() => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
      );
}
