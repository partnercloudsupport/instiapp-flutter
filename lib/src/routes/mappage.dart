import 'dart:async';

import 'package:InstiApp/src/bloc_provider.dart';
import 'package:InstiApp/src/drawer.dart';
import 'package:InstiApp/src/utils/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final flutterWebviewPlugin = FlutterWebviewPlugin();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  final String hostUrl = "https://insti.app";
  final String mapUrl = "https://insti.app/map/?sandbox=true";

  StreamSubscription<String> onUrlChangedSub;
  StreamSubscription<WebViewStateChanged> onStateChangedSub;

  // Storing for dispose
  ThemeData theme;

  @override
  void initState() {
    super.initState();
    onUrlChangedSub = flutterWebviewPlugin.onUrlChanged.listen((String url) {
      print("Changed URL: $url");
      if (!url.contains(hostUrl)) {
        flutterWebviewPlugin.reloadUrl(mapUrl);
        flutterWebviewPlugin.hide();
      }
    });

    onStateChangedSub =
        flutterWebviewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      print(state.type);
      if (state.type == WebViewState.finishLoad) {
        if (state.url.startsWith(hostUrl)) {
          print("onStateChanged: Showing Web View");
          flutterWebviewPlugin.show();
        }
      }
    });

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    onStateChangedSub?.cancel();
    onUrlChangedSub?.cancel();
    flutterWebviewPlugin.dispose();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      systemNavigationBarColor: theme?.primaryColor ?? null,
      systemNavigationBarIconBrightness: theme?.primaryColor != null
          ? Brightness.values[1 -
              ThemeData.estimateBrightnessForColor(theme.primaryColor).index]
          : null,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          Brightness.values[1 - (theme?.brightness?.index ?? 0)],
    ));

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    var bloc = BlocProvider.of(context).bloc;

    print("This is the URL: $mapUrl");
    return SafeArea(
      child: WebviewScaffold(
        url: mapUrl,
        withJavascript: true,
        withLocalStorage: true,
        headers: {
          "Cookie": bloc.getSessionIdHeader(),
        },
        primary: true,
        bottomNavigationBar: MyBottomAppBar(
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                tooltip: "Back",
                icon: Icon(
                  OMIcons.arrowBack,
                  semanticLabel: "Go Back",
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              IconButton(
                tooltip: "Refresh",
                icon: Icon(
                  OMIcons.refresh,
                  semanticLabel: "Refresh",
                ),
                onPressed: () {
                  flutterWebviewPlugin.reload();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
