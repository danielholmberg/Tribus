import 'package:cached_network_image/cached_network_image.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tribes/models/Post.dart';
import 'package:tribes/models/User.dart';
import 'package:tribes/services/database.dart';
import 'package:tribes/shared/widgets/CustomScrollBehavior.dart';
import 'package:tribes/shared/constants.dart' as Constants;
import 'package:tribes/shared/widgets/Loading.dart';

class PostRoom extends StatefulWidget {
  final Color tribeColor;
  final Post post;
  PostRoom(this.post, this.tribeColor);

  @override
  _PostRoomState createState() => _PostRoomState();
}

class _PostRoomState extends State<PostRoom> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  bool edited = false;
  FocusNode focusNode = FocusNode();

  String title;
  String content;
  String originalTitle;
  String originalContent;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    originalTitle = widget.post.title;
    originalContent = widget.post.content;
    title = originalTitle;
    content = originalContent;

    Future.delayed(Duration(milliseconds: 650)).then((val) {
      FocusScope.of(context).requestFocus(focusNode);
    });
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final UserData currentUser = Provider.of<UserData>(context);
    print('Building PostRoom()...');
    print('Current user ${currentUser.toString()}');

    _showDiscardDialog() {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Constants.dialogCornerRadius))),
          backgroundColor: Constants
              .profileSettingsBackgroundColor,
          title: Text(
              'Are your sure you want to discard changes?'),
          actions: <Widget>[
            FlatButton(
              child: Text('No', 
                style: TextStyle(color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Yes',
                style: TextStyle(color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Dialog: "Are you sure...?"
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }

    return WillPopScope(
      onWillPop: () => edited ? _showDiscardDialog() : Future(() => true),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
          ),
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text('Editing', 
                style: TextStyle(
                  fontFamily: 'TribesRounded',
                  fontWeight: FontWeight.bold,
                  color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor
                ),
              ),
              SizedBox(width: Constants.defaultPadding),
              Visibility(
                visible: edited,
                child: Text('| edited', 
                  style: TextStyle(
                    fontFamily: 'TribesRounded',
                    fontStyle: FontStyle.normal,
                    fontSize: 12,
                    color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: DynamicTheme.of(context).data.backgroundColor,
          elevation: 0.0,
          leading: IconButton(icon: Icon(Icons.arrow_back), 
            color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
            onPressed: () {
              edited ? _showDiscardDialog() : Navigator.of(context).pop();
            },
          ),
          actions: <Widget>[
            IconButton(
              splashColor: Colors.transparent,
              color: DynamicTheme.of(context).data.backgroundColor,
              icon: Icon(Icons.delete, 
                color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Constants.dialogCornerRadius))),
                    backgroundColor: Constants
                        .profileSettingsBackgroundColor,
                    title: Text(
                        'Are your sure you want to delete this post?'),
                    actions: <Widget>[
                      FlatButton(
                        child: Text('No', 
                          style: TextStyle(color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text('Yes',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () async {
                          await DatabaseService().deletePost(widget.post);
                          Navigator.of(context).pop(); // Dialog: "Are you sure...?"
                          Navigator.of(context).pop(); // PostTile
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ]
        ),
        body: Container(
          color: DynamicTheme.of(context).data.backgroundColor,
          child: loading ? Loading()
          : Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ScrollConfiguration(
                behavior: CustomScrollBehavior(),
                child: ListView(
                  padding: EdgeInsets.only(bottom: 68.0),
                  shrinkWrap: true,
                  children: <Widget>[
                    Container(
                      alignment: Alignment.topCenter,
                      padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TextFormField(
                              focusNode: focusNode,
                              initialValue: title ?? widget.post.title,
                              textCapitalization: TextCapitalization.sentences,
                              style: DynamicTheme.of(context).data.textTheme.title,
                              cursorColor: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                              decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(0)),
                              validator: (val) => val.isEmpty 
                                ? 'Enter a title' 
                                : null,
                              onChanged: (val) {
                                setState(() {
                                  title = val;
                                  edited = originalTitle != val || originalContent != content;
                                });
                              },
                            ),
                            TextFormField(
                              initialValue: content ?? widget.post.content,
                              textCapitalization: TextCapitalization.sentences,
                              style: DynamicTheme.of(context).data.textTheme.body1,
                              cursorColor: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(0)),
                              validator: (val) => val.isEmpty 
                                ? 'Enter some content' 
                                : null,
                              onChanged: (val) {
                                setState((){
                                  content = val;
                                  edited = originalContent != val || originalTitle != title;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                    widget.post.fileURL.isEmpty 
                    ? SizedBox.shrink() 
                    : CachedNetworkImage(
                      imageUrl: widget.post.fileURL,
                      imageBuilder: (context, imageProvider) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          child: Image(
                            image: imageProvider, 
                            fit: BoxFit.scaleDown,
                            frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
                              return child;
                            },
                          ),
                        ),
                      ),
                      placeholder: (context, url) => Loading(),
                      errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: edited ? 1.0 : 0.0,
                  child: ButtonTheme(
                    height: 60.0,
                    minWidth: MediaQuery.of(context).size.width,
                    child: RaisedButton.icon(
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
                      ),
                      color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                      icon: Icon(Icons.done, color: Constants.buttonIconColor, size: Constants.defaultIconSize),
                      label: Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'TribesRounded')),
                      textColor: Colors.white,
                      onPressed: edited ? () async {
                        if(_formKey.currentState.validate()) {
                          setState(() { 
                            loading = true;
                          });

                          await DatabaseService().updatePostData(
                            widget.post.id, 
                            title ?? widget.post.title, 
                            content ?? widget.post.content
                          ).then((val) {
                            _scaffoldKey.currentState.showSnackBar(
                              SnackBar(
                                content: Text('Post saved'),
                                duration: Duration(milliseconds: 500),
                              )
                            );

                            setState(() {
                              loading = false;
                              edited = false;
                              originalTitle = title;
                              originalContent = content;
                            });
                          });
                        }
                      } : null,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
