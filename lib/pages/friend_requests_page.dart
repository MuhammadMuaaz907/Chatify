import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../providers/authentication_provider.dart';
import '../providers/friend_requests_provider.dart';
import '../models/chat_user.dart';
import '../widgets/top_bar.dart';

class FriendRequestsPage extends StatefulWidget {
  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  late AuthenticationProvider _auth;
  late FriendRequestsProvider _requestsProvider;
  late double _deviceHeight;
  late double _deviceWidth;

  @override
  void initState() {
    super.initState();
    _auth = Provider.of<AuthenticationProvider>(context, listen: false);
    _requestsProvider = FriendRequestsProvider(_auth);
  }

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FriendRequestsProvider>.value(
          value: _requestsProvider,
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TopBar(
                  'Friend Requests',
                  primaryAction: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _requestsProvider.getPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading requests: ${snapshot.error}",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No requests found.",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }
        List<Map<String, dynamic>> requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> request = requests[index];
            String senderId = request["senderId"];
            return FutureBuilder<ChatUser>(
              future: _requestsProvider.getUser(senderId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard();
                }
                if (userSnapshot.hasError || !userSnapshot.hasData) {
                  return _buildErrorCard("Unknown User");
                }
                ChatUser user = userSnapshot.data!;
                return _buildRequestCard(user, request["id"]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: const ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        title: Text("Loading...", style: TextStyle(color: Colors.black54)),
      ),
    );
  }

  Widget _buildErrorCard(String errorText) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.error, color: Colors.white),
        ),
        title: Text(errorText, style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildRequestCard(ChatUser user, String requestId) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Text(
            user.name.isNotEmpty ? user.name[0] : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name.isNotEmpty ? user.name : 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          "Sent on: ${user.lastActive.toLocal().toString().split(' ')[0]}",
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                await _requestsProvider.acceptRequest(requestId);
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () async {
                await _requestsProvider.rejectRequest(requestId);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
