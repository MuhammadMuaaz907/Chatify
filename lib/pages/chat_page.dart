import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/custom_list_view_tiles.dart';
import '../widgets/custom_form_feilds.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import '../providers/authentication_provider.dart';
import '../providers/chat_page_provider.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;

  ChatPage({required this.chat});

  @override
  State<StatefulWidget> createState() {
    return _ChatPageState();
  }
}

class _ChatPageState extends State<ChatPage> {
  late double _deviceHeight;
  late double _deviceWidth;

  late AuthenticationProvider _auth;
  late ChatPageProvider _pageProvider;

  late GlobalKey<FormState> _messageFormState;
  late ScrollController _messagesListViewController;

  @override
  void initState() {
    super.initState();
    _messageFormState = GlobalKey<FormState>();
    _messagesListViewController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    _auth = Provider.of<AuthenticationProvider>(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatPageProvider>(
          create: (_) => ChatPageProvider(widget.chat.uid, _auth, _messagesListViewController),
        ),
      ],
      child: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Builder(
      builder: (BuildContext _context) {
        _pageProvider = _context.watch<ChatPageProvider>();
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chat.title(), style: TextStyle(color: Colors.white)),
                if (widget.chat.group)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      widget.chat.members
                          .where((member) => member.uid != _auth.user?.uid) // Exclude current user
                          .map((member) => member.name)
                          .join(", "),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            backgroundColor: Colors.teal,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => _pageProvider.goBack(),
            ),
            actions: [
              if (!widget.chat.group)
                IconButton(
                  icon: Icon(Icons.person_remove, color: Colors.white),
                  onPressed: () async {
                    if (_auth.user?.uid == null) return;
                    String friendId = widget.chat.members
                        .firstWhere((member) => member.uid != _auth.user!.uid)
                        .uid;
                    bool success = await _pageProvider.unfriendUser(friendId);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Unfriended successfully!")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to unfriend. Please check your connection or try again.")),
                      );
                    }
                  },
                ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: () => _pageProvider.deleteChat(),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _messagesListView()),
              _sendMessageForm(),
            ],
          ),
        );
      },
    );
  }

  Widget _messagesListView() {
    if (_pageProvider.messages != null) {
      if (_pageProvider.messages!.isNotEmpty) {
        return ListView.builder(
          controller: _messagesListViewController,
          itemCount: _pageProvider.messages!.length,
          itemBuilder: (BuildContext _context, int _index) {
            ChatMessage _message = _pageProvider.messages![_index];
            bool _isOwnMessage = _message.senderID == _auth.user?.uid;
            String senderName = widget.chat.members
                .firstWhere(
                  (member) => member.uid == _message.senderID,
                  orElse: () => ChatUser(
                    uid: _message.senderID,
                    name: "Unknown",
                    email: "",
                    imageURL: "",
                    lastActive: DateTime.now(),
                  ),
                )
                .name;
            return Container(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Align(
                alignment: _isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: _isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!_isOwnMessage)
                      Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isOwnMessage ? Colors.teal[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _message.content,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        return Center(
          child: Text("Be the first to say Hi!", style: TextStyle(color: Colors.black54)),
        );
      }
    } else {
      return Center(child: CircularProgressIndicator(color: Colors.teal));
    }
  }

  Widget _sendMessageForm() {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Form(
        key: _messageFormState,
        child: Row(
          children: [
            Expanded(
              child: CustomTextFormFeild(
                onSaved: (_value) => _pageProvider.message = _value,
                regEx: r"^(?!\s*$).+",
                hintText: "Type a message...",
                obscureText: false,
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Colors.teal),
              onPressed: () {
                if (_messageFormState.currentState!.validate()) {
                  _messageFormState.currentState!.save();
                  _pageProvider.sendTextMessage();
                  _messageFormState.currentState!.reset();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.camera_enhance, color: Colors.teal),
              onPressed: () => _pageProvider.sendImageMessage(),
            ),
          ],
        ),
      ),
    );
  }
}