import 'dart:io';

import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tribes/models/User.dart';
import 'package:tribes/screens/base/chats/ChatRoom.dart';
import 'package:tribes/services/database.dart';
import 'package:tribes/shared/widgets/CustomAwesomeIcon.dart';
import 'package:tribes/shared/widgets/CustomPageTransition.dart';
import 'package:tribes/shared/widgets/CustomScrollBehavior.dart';
import 'package:tribes/shared/widgets/Loading.dart';
import 'package:tribes/shared/constants.dart' as Constants;
import 'package:tribes/shared/widgets/UserAvatar.dart';

class NewChat extends StatefulWidget {
  final String currentUserID;
  NewChat({@required this.currentUserID});

  @override
  _NewChatState createState() => _NewChatState();
}

class _NewChatState extends State<NewChat> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<UserData> _friendsList = [];
  List<UserData> _searchResult = [];
  bool loading = false;
  String error = '';
  TextEditingController controller = new TextEditingController();
  Future friendsFuture;

  final EdgeInsets gridPadding = const EdgeInsets.fromLTRB(12.0, 82.0, 12.0, 12.0);

  @override
  void initState() {
    friendsFuture = DatabaseService().friendsList(widget.currentUserID);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    _onSearchTextChanged(String text) async {
      _searchResult.clear();
      if (text.isEmpty) {
        setState(() {});
        return;
      }

      _friendsList.forEach((friend) {
        if (friend.name.toLowerCase().contains(text.toLowerCase()) || 
        friend.username.toLowerCase().contains(text.toLowerCase())) {
          _searchResult.add(friend);
        }
      });

      setState(() {});
    }
    
    _friendTile(UserData friend) {
      return ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        leading: UserAvatar(
          currentUserID: widget.currentUserID, 
          user: friend, 
          radius: 20, 
          withName: true,
          color: DynamicTheme.of(context).data.primaryColor,
          textColor: DynamicTheme.of(context).data.primaryColor,
          textPadding: const EdgeInsets.only(left: 8.0),
        ),
        trailing: FloatingActionButton(
          heroTag: 'newChatButton-${friend.uid}',
          elevation: 4.0,
          mini: true,
          child: CustomAwesomeIcon(
            icon: FontAwesomeIcons.pen,
            size: Constants.smallIconSize,
          ),
          backgroundColor: DynamicTheme.of(context).data.primaryColor,
          onPressed: () async {
           String roomID = await DatabaseService().createNewPrivateChatRoom(widget.currentUserID, friend.uid);

            Navigator.push(context, 
              CustomPageTransition(
                type: CustomPageTransitionType.chatRoom, 
                duration: Constants.pageTransition600, 
                child: StreamProvider<UserData>.value(
                  value: DatabaseService().currentUser(widget.currentUserID), 
                  child: ChatRoom(roomID: roomID, members: [widget.currentUserID, friend.uid], reply: true),
                ),
              )
            );
          }
        ),
      );
    }
    
    return loading ? Loading() : Scaffold(
      key: _scaffoldKey,
      backgroundColor: DynamicTheme.of(context).data.backgroundColor,
      body: SafeArea(
        child: Container(
          color: DynamicTheme.of(context).data.backgroundColor,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: FutureBuilder<List<UserData>>(
                  future: friendsFuture,
                  builder: (context, snapshot) {

                    if(snapshot.hasData) {
                      _friendsList = snapshot.data;

                      return Container(
                        child: ScrollConfiguration(
                          behavior: CustomScrollBehavior(), 
                          child: _searchResult.length != 0 || controller.text.isNotEmpty
                          ? ListView.builder(
                            padding: gridPadding,
                            itemCount: _searchResult.length,
                            itemBuilder: (context, i) {
                              return _friendTile(_searchResult[i]); 
                            }
                          )
                          : ListView.builder(
                            padding: gridPadding,
                            itemCount: _friendsList.length,
                            itemBuilder: (context, i) {
                              return _friendTile(_friendsList[i]);
                            },
                          ),
                        ),
                      );
                    } else if(snapshot.hasError){
                      print('Error retrieving friends: ${snapshot.error.toString()}');
                      return Center(child: Text('Unable to retrieve friends'));
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  }
                )
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: EdgeInsets.all(12.0),
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: Colors.white, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                    ]
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Leading Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Platform.isIOS ? FontAwesomeIcons.chevronLeft : FontAwesomeIcons.arrowLeft,
                              color: DynamicTheme.of(context).data.primaryColor
                            ), 
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Icon(FontAwesomeIcons.search, color: Colors.black54, size: Constants.smallIconSize),
                        ],
                      ),

                      SizedBox(width: Constants.largePadding),

                      // Center Widget
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: false,
                          decoration: InputDecoration(
                            hintText: 'Find your friend', 
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontFamily: 'TribesRounded',
                              fontSize: 16,
                              color: Colors.black54.withOpacity(0.3),
                            ),
                          ),
                          onChanged: _onSearchTextChanged,
                        )
                      ),

                      // Trailing Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              FontAwesomeIcons.solidTimesCircle,
                              color: DynamicTheme.of(context).data.primaryColor,
                            ), 
                            onPressed: () {
                              controller.clear();
                              _onSearchTextChanged('');
                            },
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}