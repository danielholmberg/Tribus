import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tribes/models/Post.dart';
import 'package:tribes/models/User.dart';
import 'package:tribes/screens/base/tribes/screens/EditPost.dart';
import 'package:tribes/screens/base/tribes/screens/PostRoom.dart';
import 'package:tribes/screens/base/tribes/widgets/ImageCarousel.dart';
import 'package:tribes/services/database.dart';
import 'package:tribes/shared/widgets/UserAvatar.dart';

class PostTileCompact extends StatefulWidget {
  final Post post;
  final UserData user;
  final bool viewOnly;
  PostTileCompact({@required this.post, @required this.user, this.viewOnly = false});

  @override
  _PostTileCompactState createState() => _PostTileCompactState();
}

class _PostTileCompactState extends State<PostTileCompact> with TickerProviderStateMixin {

  double cornerRadius = 10.0;

  @override
  Widget build(BuildContext context) {
    final UserData currentUser = Provider.of<UserData>(context);
    print('Building Profile()...');
    print('Current user ${currentUser.uid}');

    bool currentUserIsAuthor = currentUser.uid == widget.post.author;
    bool showUserAvatar = widget.user.uid != widget.post.author;

    _postHeader() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AnimatedSize(
            vsync: this,
            alignment: Alignment.centerLeft,
            duration: Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            child: Container(
              margin: const EdgeInsets.only(top: 4.0, left: 4.0),
              child: StreamBuilder<UserData>(
                stream: DatabaseService().userData(widget.post.author),
                builder: (context, snapshot) {
                  if(snapshot.hasError) {
                    print('Error retrieving author data: ${snapshot.error.toString()}');
                  } 
                  
                  return UserAvatar(
                    currentUserID: currentUser.uid, 
                    user: snapshot.data, 
                    color: DynamicTheme.of(context).data.primaryColor,
                    disable: widget.viewOnly,
                    radius: 6,
                    nameFontSize: 6,
                    strokeWidth: 1.0,
                    strokeColor: Colors.white,
                    padding: const EdgeInsets.all(2.0),
                    withDecoration: true,
                    textPadding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                    textColor: Colors.white,
                  );
                }
              ),
            ),
          ),
        ],
      );
    }

    _postImagesCompactContent() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ImageCarousel(
              images: widget.post.images, 
              color: DynamicTheme.of(context).data.primaryColor,
              indicatorPosition: IndicatorPosition.topRight,
              small: true,
            ),
            Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: Visibility(
                visible: showUserAvatar, 
                child: _postHeader(),
              ),
            ),          
          ],
        ),
      );
    }

    _buildCompactCard() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ]
        ),
        child: _postImagesCompactContent(),
      );
    }

    return GestureDetector(
      onTap: () {
        if(!widget.viewOnly) {
          showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StreamProvider<UserData>.value(
            value: DatabaseService().currentUser(currentUser.uid),
            child: PostRoom(
              post: widget.post,
            ),
          ),
        );
        }
      },
      child: _buildCompactCard(),
    );
  }
}