import 'package:InstiApp/src/api/response/explore_response.dart';
import 'package:InstiApp/src/bloc_provider.dart';
import 'package:InstiApp/src/blocs/explore_bloc.dart';
import 'package:InstiApp/src/drawer.dart';
import 'package:InstiApp/src/utils/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class ExplorePage extends StatefulWidget {
  final String title = "Explore";

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  ScrollController _hideButtonController;
  double isFabVisible = 0;

  bool searchMode = false;
  IconData actionIcon = OMIcons.search;

  @override
  void initState() {
    super.initState();
    _hideButtonController = ScrollController();
    _hideButtonController.addListener(() {
      if (_hideButtonController.position.userScrollDirection ==
              ScrollDirection.reverse &&
          isFabVisible == 1) {
        setState(() {
          isFabVisible = 0;
        });
      } else if (_hideButtonController.position.userScrollDirection ==
              ScrollDirection.forward &&
          isFabVisible == 0) {
        setState(() {
          isFabVisible = 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var bloc = BlocProvider.of(context).bloc;
    var exploreBloc = bloc.exploreBloc;
    exploreBloc.refresh();

    var footerButtons = searchMode
        ? [
            Expanded(
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(OMIcons.search),
                  hintText: "Search...",
                ),
                onChanged: (query) async {
                  if (query.length > 4) {
                    exploreBloc.query = query;
                    exploreBloc.refresh();
                  }
                },
                onSubmitted: (query) async {
                  exploreBloc.query = query;
                  await exploreBloc.refresh();
                },
              ),
            ),
          ]
        : null;

    return Scaffold(
      resizeToAvoidBottomPadding: true,
      key: _scaffoldKey,
      drawer: BottomDrawer(),
      bottomNavigationBar: Transform.translate(
        offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            searchMode
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: Divider.createBorderSide(context, width: 1.0),
                      ),
                    ),
                    child: SafeArea(
                      child: ButtonTheme.bar(
                        child: SafeArea(
                          top: false,
                          child: Row(children: footerButtons),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 0,
                    height: 0,
                  ),
            BottomAppBar(
              child: new Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    tooltip: "Show bottom sheet",
                    icon: Icon(
                      OMIcons.menu,
                      semanticLabel: "Show bottom sheet",
                    ),
                    onPressed: () {
                      BottomDrawer.setPageIndex(bloc, 2);
                      _scaffoldKey.currentState.openDrawer();
                    },
                  ),
                  IconButton(
                    icon: Icon(actionIcon),
                    onPressed: () {
                      setState(() {
                        if (searchMode) {
                          actionIcon = OMIcons.search;
                          exploreBloc.query = "";
                          exploreBloc.refresh();
                        } else {
                          actionIcon = OMIcons.close;
                        }
                        searchMode = !searchMode;
                      });
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<ExploreResponse>(
        stream: exploreBloc.explore,
        builder:
            (BuildContext context, AsyncSnapshot<ExploreResponse> snapshot) {
          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () {
              exploreBloc.refresh();
            },
            child: ListView(
              scrollDirection: Axis.vertical,
              controller: _hideButtonController,
              children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Text(
                        widget.title,
                        style: theme.textTheme.display2.copyWith(
                            color: Colors.black, fontFamily: "Bitter"),
                      ),
                    )
                  ] +
                  _buildContent(snapshot, theme, exploreBloc),
            ),
          );
        },
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: isFabVisible == 0
          ? null
          : FloatingActionButton(
              tooltip: "Go to the Top",
              onPressed: () {
                _hideButtonController
                    .animateTo(0.0,
                        curve: Curves.fastOutSlowIn,
                        duration: const Duration(milliseconds: 600))
                    .then((_) {
                  setState(() {
                    isFabVisible = 0.0;
                  });
                });
                setState(() {
                  isFabVisible = 0.0;
                });
              },
              child: Icon(OMIcons.keyboardArrowUp),
            ),
    );
  }

  List<Widget> _buildContent(AsyncSnapshot<ExploreResponse> snapshot,
      ThemeData theme, ExploreBloc exploreBloc) {
    if (snapshot.hasData) {
      var bodies = snapshot.data.bodies;
      var events = snapshot.data.events;
      var users = snapshot.data.users;
      if (bodies.isEmpty && events.isEmpty && users.isEmpty) {
        return [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
            child: Text.rich(TextSpan(
              style: theme.textTheme.title,
              children: [
              TextSpan(text: "Nothing found for the query "),
              TextSpan(
                  text: "\"${exploreBloc.query}\"",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "."),
            ])),
          )
        ];
      }
      return (bodies
                  ?.map((b) => _buildListTile(
                      b.bodyName,
                      b.bodyShortDescription,
                      b.bodyImageURL,
                      OMIcons.peopleOutline,
                      "/body/${b.bodyID}",
                      theme))
                  ?.toList() ??
              []) +
          (events
                  ?.map((e) => _buildListTile(
                      e.eventName,
                      e.getSubTitle(),
                      e.eventImageURL ?? e.eventBodies[0]?.bodyImageURL,
                      OMIcons.event,
                      "/event/${e.eventID}",
                      theme))
                  ?.toList() ??
              []) +
          (users
                  ?.map((u) => _buildListTile(
                      u.userName,
                      u.userLDAPId,
                      u.userProfilePictureUrl,
                      OMIcons.personOutline,
                      "/user/${u.userID}",
                      theme))
                  ?.toList() ??
              []);
    } else {
      return [
        Center(
          child: CircularProgressIndicator(),
        )
      ];
    }
  }

  Widget _buildListTile(String title, String subtitle, String url,
      IconData fallbackIcon, String routeOnClick, ThemeData theme) {
    return ListTile(
      leading: NullableCircleAvatar(url, fallbackIcon),
      title: Text(
        title,
        style: theme.textTheme.title,
      ),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.of(context).pushNamed(routeOnClick);
      },
    );
  }
}