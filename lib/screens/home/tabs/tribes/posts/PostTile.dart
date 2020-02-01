import 'package:cached_network_image/cached_network_image.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tribes/models/Post.dart';
import 'package:tribes/models/User.dart';
import 'package:tribes/services/auth.dart';
import 'package:tribes/services/database.dart';
import 'package:tribes/shared/constants.dart' as Constants;
import 'package:tribes/shared/widgets/CustomPageTransition.dart';
import 'package:tribes/shared/widgets/CustomScrollBehavior.dart';
import 'package:tribes/shared/widgets/Loading.dart';
import 'package:geocoder/geocoder.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final Color tribeColor;
  final int index;
  PostTile({this.post, this.tribeColor, this.index});

  @override
  _PostTileState createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool loading = false;
  FocusNode focusNode;

  String title;
  String content;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    _postDetails(String location) {
      return loading ? Loading() : StreamBuilder<User>(
        stream: AuthService().user,
        builder: (context, snapshot) {
          bool isAuthor = snapshot.data.uid == widget.post.author;
          bool isEditing = false;
          focusNode = FocusNode();

          return StatefulBuilder(
            builder: (context, setState) { 
              return Scaffold(
                appBar: isAuthor ? 
                AppBar(
                  iconTheme: IconThemeData(
                    color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                  ),
                  centerTitle: true,
                  title: isEditing ? 
                    Text('Editing', style: TextStyle(color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor)) : 
                    Text('Posted: ${DateTime.fromMillisecondsSinceEpoch(widget.post.created)}',
                      textAlign: TextAlign.center, 
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: Constants.timestampFontSize,
                      ),
                    ),
                  backgroundColor: DynamicTheme.of(context).data.backgroundColor,
                  elevation: 0.0,
                  leading: isEditing ? 
                    IconButton(icon: Icon(Icons.close), 
                      color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
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
                                  setState(() => isEditing = false);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ) : 
                    IconButton(icon: Icon(Icons.arrow_back), 
                      color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  actions: isEditing ? <Widget>[
                    IconButton(
                      color: DynamicTheme.of(context).data.backgroundColor,
                      icon: Icon(Icons.delete, 
                        color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
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
                                  await DatabaseService().deletePost(widget.post.id);
                                  Navigator.of(context).pop(); // Dialog: "Are you sure...?"
                                  Navigator.of(context).pop(); // PostTile
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ] : <Widget> [
                    IconButton(
                      color: DynamicTheme.of(context).data.backgroundColor,
                      icon: Icon(Icons.edit, 
                        color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor
                      ),
                      onPressed: () {
                        FocusScope.of(context).requestFocus(focusNode);
                        setState(() {
                          isEditing = true;
                        });
                      },
                    ),
                  ],
                )
                : AppBar(
                  elevation: 0.0,
                  iconTheme: IconThemeData(
                    color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                  ),
                  backgroundColor: DynamicTheme.of(context).data.backgroundColor,
                  centerTitle: true,
                  title: Text('Posted: ${DateTime.fromMillisecondsSinceEpoch(widget.post.created)}',
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: Constants.timestampFontSize,
                    ),
                  ),
                  actions: <Widget>[
                    IconButton(
                      color: DynamicTheme.of(context).data.backgroundColor,
                      icon: Icon(Icons.favorite_border, 
                        color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor
                      ),
                      onPressed: () async {
                        Fluttertoast.showToast(
                          msg: 'Coming soon!',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      },
                    ),                  ]
                ),
                body: ScrollConfiguration(
                  behavior: CustomScrollBehavior(),
                  child: ListView(
                    children: <Widget>[
                      widget.post.fileURL.isEmpty 
                      ? SizedBox.shrink() 
                      : Hero(
                        tag: 'postImage-${widget.post.id}',
                        child: Container(
                          color: DynamicTheme.of(context).data.backgroundColor,
                          child: CachedNetworkImage(
                            imageUrl: widget.post.fileURL,
                            imageBuilder: (context, imageProvider) => Container(
                              height: MediaQuery.of(context).size.height * 0.6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.fitHeight,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                          ),
                        ),
                      ),
                      Container(
                        color: DynamicTheme.of(context).data.backgroundColor,
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.account_circle, 
                                      color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                                      size: Constants.mediumIconSize,
                                    ),
                                    SizedBox(width: Constants.defaultPadding),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        StreamBuilder<UserData>(
                                          stream: DatabaseService().userData(widget.post.author),
                                          builder: (context, snapshot) {
                                            return Text(snapshot.hasData ? snapshot.data.name : '',
                                              style: TextStyle(
                                                color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                                                fontFamily: 'TribesRounded',
                                                fontWeight: FontWeight.bold
                                              ),
                                            );
                                          }
                                        ),
                                        location.isEmpty
                                        ? SizedBox.shrink() 
                                        : Text(location,
                                          style: TextStyle(
                                            color: Colors.blueGrey,
                                            fontFamily: 'TribesRounded',
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal
                                          ),
                                        ),
                                       ],
                                    )
                                  ],
                                ),
                                Text('#${widget.index+1}', 
                                  style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: Constants.timestampFontSize,
                                  )
                                ),
                              ],
                            ),
                            Expanded(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Hero(
                                      tag: 'postTitle-${widget.post.id}',
                                      child: TextFormField(
                                        focusNode: focusNode,
                                        initialValue: widget.post.title,
                                        readOnly: !isEditing,
                                        style: DynamicTheme.of(context).data.textTheme.title,
                                        cursorColor: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                                        decoration: InputDecoration(border: InputBorder.none),
                                        validator: (val) => val.isEmpty 
                                          ? 'Enter a title' 
                                          : null,
                                        onChanged: (val) {
                                          setState(() => title = val);
                                        },
                                      ),
                                    ),
                                    Hero(
                                      tag: 'postContent-${widget.post.id}',
                                      child: TextFormField(
                                        initialValue: widget.post.content,
                                        readOnly: !isEditing,
                                        style: DynamicTheme.of(context).data.textTheme.body1,
                                        cursorColor: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                        decoration: InputDecoration(border: InputBorder.none),
                                        validator: (val) => val.isEmpty 
                                          ? 'Enter some content' 
                                          : null,
                                        onChanged: (val) {
                                          setState(() => content = val);
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: isEditing ? Container(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  color: DynamicTheme.of(context).data.backgroundColor,
                  child: ButtonTheme(
                    height: 40.0,
                    minWidth: MediaQuery.of(context).size.width,
                    child: RaisedButton.icon(
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8.0),
                      ),
                      color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                      icon: Icon(Icons.done,
                        color: Constants.buttonIconColor),
                      label: Text('Save'),
                      textColor: Colors.white,
                      onPressed: () async {
                        if(_formKey.currentState.validate()) {
                          setState(() { 
                            loading = true;
                            isEditing = false; 
                          });
                          await DatabaseService().updatePostData(
                            widget.post.id, 
                            title ?? widget.post.title, 
                            content ?? widget.post.content
                          );

                          _scaffoldKey.currentState.showSnackBar(
                            SnackBar(
                              content: Text('Post saved'),
                              duration: Duration(milliseconds: 500),
                            )
                          );

                          setState(() => loading = false);  
                        }
                      },
                    ),
                  ),
                ) : SizedBox.shrink(),
              );
            }
          );
        }
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: DynamicTheme.of(context).data.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: widget.tribeColor.withOpacity(0.1) ?? DynamicTheme.of(context).data.accentColor,
            blurRadius: 5,
            offset: Offset(0, 0),
          ),
        ]
      ),
      margin: EdgeInsets.fromLTRB(0.0, Constants.largePadding, 0.0, 0.0),
      child: InkWell(
        splashColor: Constants.tribesColor.withAlpha(30),
        onTap: () async {
          var location = '';
          if((widget.post.lat != 0 && widget.post.lng != 0)) {
            var coordinates = new Coordinates(widget.post.lat, widget.post.lng);
            var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
            var first = addresses.first;
            location = '${first.addressLine}';
            print('lat ${widget.post.lat}, lng ${widget.post.lng}');
            print('location: $location');
          }
          
          Navigator.push(context, CustomPageTransition(
            type: CustomPageTransitionType.postDetails, 
            duration: Constants.pageTransition600, 
            child: _postDetails(location)
          ));
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: widget.post.fileURL.isEmpty 
                ? SizedBox.shrink() 
                : Hero(
                    tag: 'postImage-${widget.post.id}',
                    child: CachedNetworkImage(
                    imageUrl: widget.post.fileURL,
                    imageBuilder: (context, imageProvider) => Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.account_circle, 
                              color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                              size: Constants.mediumIconSize,
                            ),
                            SizedBox(width: Constants.defaultPadding),
                            StreamBuilder<UserData>(
                              stream: DatabaseService().userData(widget.post.author),
                              builder: (context, snapshot) {
                                return Text(snapshot.hasData ? snapshot.data.name : '',
                                  style: TextStyle(
                                    color: widget.tribeColor ?? DynamicTheme.of(context).data.primaryColor,
                                    fontFamily: 'TribesRounded',
                                    fontWeight: FontWeight.bold
                                  ),
                                );
                              }
                            )
                          ],
                        ),
                        Text('#${widget.index+1}', 
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: Constants.timestampFontSize,
                          )
                        ),
                      ],
                    ),
                    Hero(
                      tag: 'postTitle-${widget.post.id}',
                      child: Text(widget.post.title,
                          style: DynamicTheme.of(context).data.textTheme.title),
                    ),
                    SizedBox(height: Constants.smallSpacing),
                    Hero(
                      tag: 'postContent-${widget.post.id}',
                      child: Text(widget.post.content,
                          style: DynamicTheme.of(context).data.textTheme.body2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
