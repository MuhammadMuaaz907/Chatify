import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../providers/authentication_provider.dart';
import '../providers/users_page_provider.dart';
import '../widgets/top_bar.dart';
import '../widgets/custom_form_feilds.dart';
import '../widgets/custom_list_view_tiles.dart';
import '../widgets/rounded_button.dart';
import '../models/chat_user.dart';

class UsersPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _UsersPageState();
  }
}

class _UsersPageState extends State<UsersPage> {
  late double _deviceHeight;
  late double _deviceWidth;

  late AuthenticationProvider _auth;
  late UsersPageProvider _pageProvider;

  final TextEditingController _searchFieldTextEditingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // _auth initialize nahi kiya yahan, build mein hoga
  }

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    _auth = Provider.of<AuthenticationProvider>(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UsersPageProvider>(
          create: (_) => UsersPageProvider(_auth),
        ),
      ],
      child: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Builder(
      builder: (BuildContext _context) {
        _pageProvider = _context.watch<UsersPageProvider>();
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
                    'Users',
                    primaryAction: IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _auth.logout(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: CustomTextField(
                      onEditingComplete: (_value) {
                        _pageProvider.getUsers(name: _value);
                        FocusScope.of(context).unfocus();
                      },
                      hintText: "Search Users...",
                      obscureText: false,
                      controller: _searchFieldTextEditingController,
                      icon: Icons.search,
                      fillColor: Colors.white.withOpacity(0.1),
                      borderRadius: 15,
                    ),
                  ),
                  _usersList(),
                  _createChatButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _usersList() {
    List<ChatUser>? _users = _pageProvider.users;
    final currentUser = _auth.user;

    if (_users == null) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    List<ChatUser> filteredUsers =
        currentUser != null
            ? _users.where((user) => user.uid != currentUser.uid).toList()
            : [..._users];

    return Expanded(
      child: filteredUsers.isNotEmpty
          ? ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (BuildContext _context, int _index) {
                final user = filteredUsers[_index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.white.withOpacity(0.9),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text(
                        user.name[0],
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Last Active: ${user.lastDayActive()}",
                      style: TextStyle(color: Colors.black54),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<bool>(
                          future: _pageProvider.isFriend(user.uid),
                          builder: (context, friendSnapshot) {
                            if (friendSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.teal,
                                ),
                              );
                            }
                            bool isFriend = friendSnapshot.data ?? false;
                            return FutureBuilder<bool>(
                              future: _pageProvider.isRequestPending(user.uid),
                              builder: (context, pendingSnapshot) {
                                if (pendingSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.teal,
                                    ),
                                  );
                                }
                                bool isPending = pendingSnapshot.data ?? false;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isFriend && !isPending)
                                      IconButton(
                                        icon: Icon(
                                          Icons.person_add,
                                          color: Colors.teal,
                                        ),
                                        onPressed: () async {
                                          bool success = await _pageProvider
                                              .sendFriendRequest(user.uid);
                                          if (success) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Friend request sent!",
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Failed to send friend request.",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    if (isPending)
                                      IconButton(
                                        icon: Icon(
                                          Icons.cancel,
                                          color: Colors.orange,
                                        ),
                                        onPressed: () async {
                                          bool success = await _pageProvider
                                              .cancelFriendRequest(user.uid);
                                          if (success) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Friend request canceled!",
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Failed to cancel friend request.",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    if (isFriend)
                                      IconButton(
                                        icon: Icon(
                                          Icons.message,
                                          color: Colors.teal,
                                        ),
                                        onPressed: () {
                                          _pageProvider.startChatWithFriend(user);
                                        },
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        if (_pageProvider.selectedUsers.contains(user))
                          Icon(Icons.check_circle, color: Colors.teal),
                      ],
                    ),
                    onTap: () => _pageProvider.updateSelectedUsers(user),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                "No Users Found.",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
    );
  }

  Future<String?> _showGroupNameDialog() async {
    TextEditingController _groupNameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Group Name"),
          content: TextField(
            controller: _groupNameController,
            decoration: InputDecoration(hintText: "Group Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_groupNameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, _groupNameController.text.trim());
                }
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Widget _createChatButton() {
    return Visibility(
      visible: _pageProvider.selectedUsers.isNotEmpty,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: RoundedButton(
          name: _pageProvider.selectedUsers.isNotEmpty &&
                  _pageProvider.selectedUsers.length == 1
              ? "Chat With ${_pageProvider.selectedUsers.first.name ?? 'Unknown'}"
              : "Create Group Chat",
          height: _deviceHeight * 0.08,
          width: _deviceWidth * 0.80,
          buttonColor: Colors.teal,
          textColor: Colors.white,
          onPressed: () async {
            if (await _pageProvider.canCreateChat()) {
              if (_pageProvider.selectedUsers.length > 1) {
                String? groupName = await _showGroupNameDialog();
                if (groupName != null) {
                  print("Creating group chat with name: $groupName");
                  _pageProvider.createChat(groupName: groupName);
                }
              } else {
                _pageProvider.createChat();
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Can only chat with friends!")),
              );
            }
          },
        ),
      ),
    );
  }
}