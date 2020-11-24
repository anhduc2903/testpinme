import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:path_provider/path_provider.dart';

import 'utils/screen_utils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String dir;
  Future<void> future;
  List<String> videos = videoNames1;
  List<String> images = imageNames1;
  int videoIndex = 1;
  int imageIndex = 0;
  BetterPlayer betterPlayer;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        future = initAdvertises();
      });
    });
  }

  Future<void> initAdvertises() async {
    dir = (await getExternalStorageDirectory()).path;
  }

  List<BetterPlayerDataSource> createDataSet() {
    List dataSourceList = List<BetterPlayerDataSource>();
    dataSourceList.add(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.FILE,
        '$dir/${videos[0]}',
      ),
    );
    dataSourceList.add(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.FILE,
        '$dir/${videos[1]}',
      ),
    );

    return dataSourceList;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder<void>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Container(
                height: MediaQuery.of(context).size.height * 9 / 16,
                width: MediaQuery.of(context).size.width,
                child: BetterPlayerPlaylist(
                  betterPlayerPlaylistConfiguration:
                      BetterPlayerPlaylistConfiguration(
                    nextVideoDelay: Duration.zero,
                    loopVideos: true,
                  ),
                  betterPlayerConfiguration: BetterPlayerConfiguration(
                    autoPlay: true,
                    controlsConfiguration: BetterPlayerControlsConfiguration(
                      showControls: false,
                      showControlsOnInitialize: false,
                    ),
                  ),
                  betterPlayerDataSourceList: createDataSet(),
                ),
              );
            } else {
              return Container(
                color: color,
              );
            }
          },
        ),
      ),
    );
  }
}
