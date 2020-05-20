import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tribes/models/Tribe.dart';
import 'package:tribes/models/User.dart';
import 'package:tribes/screens/base/tribes/screens/JoinTribe.dart';
import 'package:tribes/screens/base/tribes/screens/NewTribe.dart';
import 'package:tribes/screens/base/tribes/screens/TribeRoom.dart';
import 'package:tribes/screens/base/tribes/widgets/TribeTile.dart';
import 'package:tribes/services/database.dart';
import 'package:tribes/shared/constants.dart' as Constants;
import 'package:tribes/shared/widgets/CustomAwesomeIcon.dart';
import 'package:tribes/shared/widgets/CustomPageTransition.dart';
import 'package:tribes/shared/widgets/CustomScrollBehavior.dart';
import 'package:tribes/shared/widgets/Loading.dart';

class Tribes extends StatefulWidget {
  static const routeName = '/home/tribes';

  @override
  _TribesState createState() => _TribesState();
}

class _TribesState extends State<Tribes> with AutomaticKeepAliveClientMixin {
  final PageController tribeController = PageController(
    viewportFraction: 0.8,
  );

  var debugList = [Colors.blue, Colors.red];

  // Keep track of current page to avoid unnecessary renders
  int currentPage = 0;

  @override
  void initState() {
    tribeController.addListener(() {
      int next = tribeController.page.round();

      if (currentPage != next) {
        setState(() {
          currentPage = next;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    tribeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final UserData currentUser = Provider.of<UserData>(context);
    print('Building Tribes()...');

    _showNewTribePage() {
      Navigator.push(context, CustomPageTransition(
        type: CustomPageTransitionType.newTribe,
        child: StreamProvider<UserData>.value(
          value: DatabaseService().currentUser(currentUser.uid), 
          child: NewTribe()
        ),
      ));
    }

    _showJoinTribePage() {
      Navigator.push(context, CustomPageTransition(
        type: CustomPageTransitionType.joinTribe,
        child: StreamProvider<UserData>.value(
          value: DatabaseService().currentUser(currentUser.uid), 
          child: JoinTribe(),
        ),
      ));
    }

    _buildAppBar() {
      return Container(
        padding: const EdgeInsets.all(4.0),
        color: DynamicTheme.of(context).data.primaryColor,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget> [
            Text(
              'Tribes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'OleoScriptSwashCaps',
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget> [

                  // Join Tribe Icon Widget
                  IconButton(
                    icon: CustomAwesomeIcon(icon: FontAwesomeIcons.search),
                    iconSize: Constants.defaultIconSize,
                    splashColor: Colors.transparent,
                    onPressed: () => _showJoinTribePage(),
                  ),

                ],
              ),
            ),
          ],
        ),
      );
    }

    _buildEmptyListWidget() {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () => _showNewTribePage(),
              child: Text(
                'Create',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 24.0,
                  fontFamily: 'TribesRounded',
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            Text(
              ' or ',
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 24.0,
                fontFamily: 'TribesRounded',
                fontWeight: FontWeight.normal
              ),
            ),
            GestureDetector(
              onTap: () => _showJoinTribePage(),
              child: Text(
                'Join',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 24.0,
                  fontFamily: 'TribesRounded',
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            Text(
              ' a Tribe',
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 24.0,
                fontFamily: 'TribesRounded',
                fontWeight: FontWeight.normal
              ),
            ),
          ],
        ),
      );
    }

    _buildTribesList() {
      return StreamBuilder<List<Tribe>>(
        initialData: [],
        stream: DatabaseService().joinedTribes(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Tribe> joinedTribesList = snapshot.data;

            return ScrollConfiguration(
              behavior: CustomScrollBehavior(),
              child: joinedTribesList.isEmpty ? _buildEmptyListWidget() : Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: PageView.builder(
                  reverse: false,
                  scrollDirection: Axis.horizontal,
                  controller: tribeController,
                  itemCount: joinedTribesList.length,
                  itemBuilder: (context, index) {
                    Tribe currentTribe = joinedTribesList[index];
                    double padding = MediaQuery.of(context).size.height * 0.08;
                    double verticalMargin = index == currentPage ? 0.0 : MediaQuery.of(context).size.height * 0.04;

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.easeOutQuint,
                      padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + padding, top: padding),
                      margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: verticalMargin),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, CustomPageTransition(
                            type: CustomPageTransitionType.tribeRoom,
                            child: StreamProvider<UserData>.value(
                              value: DatabaseService().currentUser(currentUser.uid), 
                              child: TribeRoom(tribeID: currentTribe.id),
                            ),
                          ));
                        },
                        child: TribeTile(tribe: currentTribe),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            return Loading();
          }
        } 
      );
    }

    return currentUser == null ? Loading()
    : Container(
      color: DynamicTheme.of(context).data.primaryColor,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: DynamicTheme.of(context).data.primaryColor,
          body: Column(
            children: <Widget>[
              _buildAppBar(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: DynamicTheme.of(context).data.backgroundColor,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 5,
                        offset: Offset(0, 0),
                      ),
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    child: _buildTribesList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
