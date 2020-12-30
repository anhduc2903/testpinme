import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import 'utils/screen_utils.dart';
import 'providers/controllers.dart';
import 'providers/images.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (ctx) => Controllers(),
            ),
            ChangeNotifierProvider(
              create: (ctx) => Images(),
            ),
          ],
          child: VideoScreen(),
        ),
      ),
    );
  }
}

class VideoScreen extends StatefulWidget {
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  Future<void> future;
  String dir;
  List<VideoPlayerController> controllers = [null, null];
  List<Timer> timers = List();
  Timer periodicImages;
  List<String> videos = videoNames1;
  List<String> images = imageNames1;
  int videoIndex = 0;
  int imageIndex = 0;
  int controllerIndex = 0;
  int previousControllerIndex = 1;
  List<bool> changeLock = [false, false];
  bool flagVideo = false;
  bool flagImage = false;
  bool isLockImage = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        future = initAdvertises();
      });
    });
  }

  @override
  void dispose() async {
    timers.forEach((timer) {
      timer?.cancel();
    });
    periodicImages?.cancel();
    await controllers[0]?.dispose();
    await controllers[1]?.dispose();
    super.dispose();
  }

  Future<void> writeLog(String data) async {
    final File file = File('$dir/log.txt');
    await file.writeAsString(data, mode: FileMode.writeOnlyAppend);
  }

  Future<void> initAdvertises() async {
    await Screen.keepOn(true);
    dir = (await getExternalStorageDirectory()).path;
    await precacheImage(FileImage(File('$dir/${images[imageIndex]}')), context);
    await precacheImage(
        FileImage(File('$dir/${images[imageIndex + 1]}')), context);
    context.read<Images>().images = '$dir/${images[imageIndex]}';
    controllers[0] =
        VideoPlayerController.file(File('$dir/${videos[videoIndex]}'));
    await controllers[0].initialize();
    await controllers[0].play();
    attachListener(controllers[0]);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // initCalendars();
      // changeImages();
    });
  }

  void initCalendars() {
    for (int i = 1; i < 8000; i++) {
      timers.add(
        Timer(
          Duration(
            milliseconds: i * 60000 - 200,
          ),
          () async {
            controllers[controllerIndex]?.removeListener(changeController);

            if (flagVideo == false && flagImage == false) {
              flagVideo = true;
              await writeLog('${DateTime.now()}  Change\n');

              videos = videoNames2;
              previousControllerIndex = controllerIndex;
              controllerIndex = controllerIndex == 0 ? 1 : 0;
              await controllers[previousControllerIndex]?.pause();
              await writeLog('${DateTime.now()}  Pause\n');
              await disposeController();
              videoIndex = 0;
              controllers[controllerIndex] = VideoPlayerController.file(
                  File('$dir/${videos[videoIndex]}'));
              await controllers[controllerIndex]?.initialize();
              await writeLog('${DateTime.now()}  InitFirst\n');
              await controllers[controllerIndex]?.play();
              attachListener(controllers[controllerIndex]);
              context.read<Controllers>().changeIndex(controllerIndex);
              flagVideo = false;
            } else {
              Timer.periodic(Duration(milliseconds: 500), (f) async {
                if (flagVideo == false && flagImage == false) {
                  flagVideo = true;
                  f.cancel();
                  await writeLog('${DateTime.now()}  Change2\n');

                  videos = videoNames2;
                  previousControllerIndex = controllerIndex;
                  controllerIndex = controllerIndex == 0 ? 1 : 0;
                  await controllers[previousControllerIndex]?.pause();
                  await writeLog('${DateTime.now()}  Pause2\n');
                  await disposeController();
                  videoIndex = 0;
                  controllers[controllerIndex] = VideoPlayerController.file(
                      File('$dir/${videos[videoIndex]}'));
                  await controllers[controllerIndex]?.initialize();
                  await writeLog('${DateTime.now()}  InitFirst2\n');
                  await controllers[controllerIndex]?.play();
                  attachListener(controllers[controllerIndex]);
                  context.read<Controllers>().changeIndex(controllerIndex);
                  flagVideo = false;
                }
              });
            }
          },
        ),
      );
    }
  }

  Future<void> changeImages() async {
    await Future.delayed(Duration(seconds: 5));
    if (isLockImage == true) return;
    await writeLog('${DateTime.now()}  StartLoopImage\n');
    imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
    await writeLog('${DateTime.now()}  LoopImage\n');
    context.read<Images>().changeImages('$dir/${images[imageIndex]}');
    changeImages();
  }

  void attachListener(VideoPlayerController controller) {
    controller.addListener(changeController);
  }

  Future<void> changeController() async {
    int pos = controllers[controllerIndex].value.position.inMilliseconds;
    int dur = controllers[controllerIndex].value.duration.inMilliseconds;

    if (pos == dur) {
      changeVideo();
    }
  }

  Future<void> changeVideo() async {
    controllers[controllerIndex]?.removeListener(changeController);

    if (flagImage == false) {
      flagVideo = true;
      await writeLog('${DateTime.now()}  NextVideo1\n');
      previousControllerIndex = controllerIndex;
      controllerIndex = controllerIndex == 0 ? 1 : 0;
      await disposeController();
      videoIndex = videoIndex < videos.length - 1 ? videoIndex + 1 : 0;
      controllers[controllerIndex] =
          VideoPlayerController.file(File('$dir/${videos[videoIndex]}'));
      await controllers[controllerIndex]?.initialize();
      await writeLog('${DateTime.now()}  NextVideo2\n');
      await controllers[controllerIndex]?.play();
      attachListener(controllers[controllerIndex]);
      context.read<Controllers>().changeIndex(controllerIndex);
      flagVideo = false;
    } else {
      Timer.periodic(Duration(milliseconds: 500), (e) async {
        if (flagImage == false) {
          flagVideo = true;
          e.cancel();
          await writeLog('${DateTime.now()}  NextVideo1b\n');
          previousControllerIndex = controllerIndex;
          controllerIndex = controllerIndex == 0 ? 1 : 0;
          await disposeController();
          videoIndex = videoIndex < videos.length - 1 ? videoIndex + 1 : 0;
          controllers[controllerIndex] =
              VideoPlayerController.file(File('$dir/${videos[videoIndex]}'));
          await controllers[controllerIndex]?.initialize();
          await writeLog('${DateTime.now()}  NextVideo2b\n');
          await controllers[controllerIndex]?.play();
          attachListener(controllers[controllerIndex]);
          context.read<Controllers>().changeIndex(controllerIndex);
          flagVideo = false;
        }
      });
    }
  }

  Future<void> disposeController() async {
    await controllers[controllerIndex]?.dispose();
    await writeLog('${DateTime.now()}  Dispose Controller\n');
  }

  Widget buildAdvertisePortrait(
      BuildContext context, double width, double height) {
    return Column(
      children: [
        Container(
          color: Colors.black,
          width: width,
          height: width * 9 / 16,
          child: VideoPlayer(
            controllers[context.watch<Controllers>().controllerIndex],
          ),
        ),
        Container(
          color: Colors.black,
          width: width,
          height: height - width * 9 / 16,
          child: Image.file(File(context.watch<Images>().images)),
        )
      ],
    );
  }

  Widget buildAdvertiseLandscape(
      BuildContext context, double width, double height) {
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return isPortrait
              ? buildAdvertisePortrait(context, width, height)
              : buildAdvertiseLandscape(context, width, height);
        } else {
          return Container(
            color: color,
          );
        }
      },
    );
  }
}
