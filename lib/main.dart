import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

import './utils/screen_utils.dart';
import './providers/controllers.dart';
import './providers/images.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return MaterialApp(
      home: Scaffold(
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
  List<VideoPlayerController> controllers = [null, null];
  List<Timer> timers = List();
  Timer periodicImages;
  List<String> videos = videoNames1;
  List<String> images = imageNames1;
  int videoIndex = 0;
  int imageIndex = 0;
  int controllerIndex = 0;
  int previousControllerIndex = 1;
  bool changeLock = false;
  bool lastFive = false;
  bool flagVideo = false;
  bool flagImage = false;

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

  Future<void> initAdvertises() async {
    await precacheImage(AssetImage('assets/${images[imageIndex]}'), context);
    context.read<Images>().images = 'assets/${images[imageIndex]}';
    controllers[0] =
        VideoPlayerController.asset('assets/${videos[videoIndex]}');
    await controllers[0].initialize();
    await controllers[0].play();
    attachListener(controllers[0]);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initCalendars();
      loopImages();
    });
  }

  Future<void> loopImages() async {
    if (flagVideo == false) {
      flagImage = true;
      imageCache.clear();
      imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
      await precacheImage(AssetImage('assets/${images[imageIndex]}'), context);
      flagImage = false;
    } else {
      Timer.periodic(Duration(milliseconds: 500), (timer) async {
        if (flagVideo == false) {
          flagImage = true;
          timer.cancel();
          imageCache.clear();
          imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
          await precacheImage(
              AssetImage('assets/${images[imageIndex]}'), context);
          flagImage = false;
        }
      });
    }

    periodicImages = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (flagVideo == false) {
        flagImage = true;
        print('${DateTime.now()} X');
        context.read<Images>().changeImages('assets/${images[imageIndex]}');
        imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          imageCache.clear();
          await precacheImage(
              AssetImage('assets/${images[imageIndex]}'), context);
          flagImage = false;
        });
      } else {
        Timer.periodic(Duration(milliseconds: 500), (timer) {
          if (flagVideo == false) {
            flagImage = true;
            print('${DateTime.now()} Y');
            timer.cancel();
            context.read<Images>().changeImages('assets/${images[imageIndex]}');
            imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
              imageCache.clear();
              await precacheImage(
                  AssetImage('assets/${images[imageIndex]}'), context);
              flagImage = false;
            });
          }
        });
      }
    });
  }

  void initCalendars() {
    for (int i = 1; i < 10000; i++) {
      timers.add(
        Timer(
          Duration(
            milliseconds: i * 60000 - 5200,
          ),
          () async {
            lastFive = true;
            periodicImages?.cancel();
          },
        ),
      );

      timers.add(
        Timer(
          Duration(
            milliseconds: i * 60000 - 2700,
          ),
          () async {
            imageCache.clear();
            images = imageNames2;
            imageIndex = 0;
            await precacheImage(
                AssetImage('assets/${images[imageIndex]}'), context);
          },
        ),
      );

      timers.add(
        Timer(
          Duration(
            milliseconds: i * 60000 - 200,
          ),
          () async {
            context.read<Images>().changeImages('assets/${images[imageIndex]}');

            videos = videoNames2;
            previousControllerIndex = controllerIndex;
            controllerIndex = controllerIndex == 0 ? 1 : 0;
            videoIndex = 0;
            controllers[controllerIndex] =
                VideoPlayerController.asset('assets/${videos[videoIndex]}');
            await controllers[previousControllerIndex]?.pause();
            lastFive = false;
            await controllers[controllerIndex]?.initialize();
            await controllers[controllerIndex]?.play();
            attachListener(controllers[controllerIndex]);
            context.read<Controllers>().changeIndex(controllerIndex);
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
              await controllers[previousControllerIndex]?.dispose();
              changeLock = false;
              await loopImages();
            });
          },
        ),
      );
    }
  }

  void attachListener(VideoPlayerController controller) {
    controller.addListener(() async {
      int dur = controller.value.duration.inMilliseconds;
      int pos = controller.value.position.inMilliseconds;
      if (pos == dur && lastFive == false) {
        await nextVideo();
      }
    });
  }

  Future<void> nextVideo() async {
    if (changeLock == true) return;
    changeLock = true;

    previousControllerIndex = controllerIndex;
    controllerIndex = controllerIndex == 0 ? 1 : 0;
    videoIndex = videoIndex < videos.length - 1 ? videoIndex + 1 : 0;
    controllers[controllerIndex] =
        VideoPlayerController.asset('assets/${videos[videoIndex]}');

    if (flagImage == false) {
      flagVideo = true;
      print('${DateTime.now()} Z');
      await controllers[controllerIndex]?.initialize();
      await controllers[controllerIndex]?.play();
      attachListener(controllers[controllerIndex]);
      context.read<Controllers>().changeIndex(controllerIndex);
      disposePreviousController();
    } else {
      Timer.periodic(Duration(milliseconds: 500), (timer) async {
        if (flagImage == false) {
          flagVideo = true;
          print('${DateTime.now()} T');
          timer.cancel();
          await controllers[controllerIndex]?.initialize();
          await controllers[controllerIndex]?.play();
          attachListener(controllers[controllerIndex]);
          context.read<Controllers>().changeIndex(controllerIndex);
          disposePreviousController();
        }
      });
    }
  }

  void disposePreviousController() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await controllers[previousControllerIndex]?.dispose();
      changeLock = false;
      flagVideo = false;
    });
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
          child: Image.asset(context.watch<Images>().images),
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
