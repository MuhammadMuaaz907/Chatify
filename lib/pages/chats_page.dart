import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../providers/authentication_provider.dart';
import '../providers/chats_page_provider.dart';
import '../services/navigation_service.dart';
import '../pages/chat_page.dart';
import '../widgets/top_bar.dart';
import '../widgets/custom_list_view_tiles.dart';
import '../models/chat.dart';
import '../models/chat_user.dart';
import '../models/chat_message.dart';

class ChatsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ChatsPageState();
  }
}

class _ChatsPageState extends State<ChatsPage> {
  late double _deviceHeight;
  late double _deviceWidth;

  late AuthenticationProvider _auth;
  late NavigationService _navigation;
  late ChatsPageProvider _pageProvider;

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    _auth = Provider.of<AuthenticationProvider>(context);
    _navigation = GetIt.instance.get<NavigationService>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatsPageProvider>(
          create: (_) => ChatsPageProvider(_auth),
        ),
      ],
      child: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Builder(
      builder: (BuildContext _context) {
        _pageProvider = _context.watch<ChatsPageProvider>();
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TopBar(
                    'Chats',
                    primaryAction: IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _auth.logout(),
                    ),
                  ),
                  Expanded(child: _chatsList()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chatsList() {
    List<Chat>? _chats = _pageProvider.chats;
    print("Chats list: ${_chats?.map((chat) => chat.title()).toList()}"); // Debug print
    return _chats != null
        ? _chats.isNotEmpty
            ? ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (BuildContext _context, int _index) {
                return _chatTile(_chats[_index]);
              },
            )
            : Center(
              child: Text(
                "No chats found",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            )
        : Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _chatTile(Chat _chat) {
    List<ChatUser> _recepients = _chat.recepients();
    bool _isActive = _recepients.any((_d) => _d.wasRecentlyActive());
    String _subtitleText =
        _chat.messages.isNotEmpty
            ? _chat.messages.first.type != MessageType.TEXT
                ? "Media Attachment"
                : _chat.messages.first.content
            : "No messages yet";
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Text(_chat.title()[0], style: TextStyle(color: Colors.white)),
        ),
        title: Text(
          _chat.title(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_subtitleText, style: TextStyle(color: Colors.black54)),
        trailing:
            _isActive
                ? Icon(Icons.circle, size: 12, color: Colors.green)
                : null,
        onTap: () => _navigation.navigateToPage(ChatPage(chat: _chat)),
      ),
    );
  }
}