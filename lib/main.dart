import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

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
  bool changeLock = false;
  bool lastFive = false;
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
    dir = (await getExternalStorageDirectory()).path;
    await precacheImage(FileImage(File('$dir/${images[imageIndex]}')), context);
    context.read<Images>().images = '$dir/${images[imageIndex]}';
    controllers[0] =
        VideoPlayerController.file(File('$dir/${videos[videoIndex]}'));
    await controllers[0].initialize();
    await controllers[0].play();
    attachListener(controllers[0]);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initCalendars();
      changeImages();
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
            // isLockImage = true;
          },
        ),
      );

      // timers.add(
      //   Timer(
      //     Duration(
      //       milliseconds: i * 60000 - 2700,
      //     ),
      //     () async {
      //       if (flagVideo == false && flagImage == false) {
      //         flagImage = true;
      //         await writeLog('${DateTime.now()}  Before 2.5s\n');
      //         imageCache.clear();
      //         images = imageNames2;
      //         imageIndex = 0;
      //         await precacheImage(
      //             FileImage(File('$dir/${images[imageIndex]}')), context);
      //         flagImage = false;
      //       } else {
      //         Timer.periodic(Duration(milliseconds: 500), (t) async {
      //           if (flagVideo == false && flagImage == false) {
      //             flagImage = true;
      //             t.cancel();
      //             await writeLog('${DateTime.now()}  Before 2.5s2\n');
      //             imageCache.clear();
      //             images = imageNames2;
      //             imageIndex = 0;
      //             await precacheImage(
      //                 FileImage(File('$dir/${images[imageIndex]}')), context);
      //             flagImage = false;
      //           }
      //         });
      //       }
      //     },
      //   ),
      // );

      timers.add(
        Timer(
          Duration(
            milliseconds: i * 60000 - 200,
          ),
          () async {
            if (flagVideo == false && flagImage == false) {
              flagVideo = true;
              await writeLog('${DateTime.now()}  Change\n');
              // context.read<Images>().changeImages('$dir/${images[imageIndex]}');

              videos = videoNames2;
              previousControllerIndex = controllerIndex;
              controllerIndex = controllerIndex == 0 ? 1 : 0;
              videoIndex = 0;
              controllers[controllerIndex] = VideoPlayerController.file(
                  File('$dir/${videos[videoIndex]}'));
              await controllers[controllerIndex]?.initialize();
              await writeLog('${DateTime.now()}  InitFirst\n');
              await controllers[controllerIndex]?.play();
              attachListener(controllers[controllerIndex]);

              WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
                await controllers[previousControllerIndex]?.dispose();
                await writeLog('${DateTime.now()}  FinishChange\n');
                changeLock = false;
                lastFive = false;
                flagVideo = false;
              });
              context.read<Controllers>().changeIndex(controllerIndex);
            } else {
              Timer.periodic(Duration(milliseconds: 500), (f) async {
                if (flagVideo == false && flagImage == false) {
                  flagVideo = true;
                  f.cancel();
                  await writeLog('${DateTime.now()}  Change2\n');
                  // context
                  //     .read<Images>()
                  //     .changeImages('$dir/${images[imageIndex]}');

                  videos = videoNames2;
                  previousControllerIndex = controllerIndex;
                  controllerIndex = controllerIndex == 0 ? 1 : 0;
                  videoIndex = 0;
                  controllers[controllerIndex] = VideoPlayerController.file(
                      File('$dir/${videos[videoIndex]}'));
                  await controllers[controllerIndex]?.initialize();
                  await controllers[controllerIndex]?.play();
                  attachListener(controllers[controllerIndex]);

                  WidgetsBinding.instance
                      .addPostFrameCallback((timeStamp) async {
                    await controllers[previousControllerIndex]?.dispose();
                    await writeLog('${DateTime.now()}  FinishChange2\n');
                    changeLock = false;
                    lastFive = false;
                    flagVideo = false;
                  });
                  context.read<Controllers>().changeIndex(controllerIndex);
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
    if (flagVideo == false) {
      flagImage = true;
      await writeLog('${DateTime.now()}  StartLoopImage\n');
      imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
      await precacheImage(
          FileImage(File('$dir/${images[imageIndex]}')), context);
      await writeLog('${DateTime.now()}  LoopImage\n');
      context.read<Images>().changeImages('$dir/${images[imageIndex]}');
      changeImages();
      flagImage = false;
    } else {
      Timer.periodic(Duration(milliseconds: 500), (t) async {
        if (flagVideo == false) {
          flagImage = true;
          t.cancel();
          await writeLog('${DateTime.now()}  StartLoopImage2\n');
          imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
          await precacheImage(
              FileImage(File('$dir/${images[imageIndex]}')), context);
          await writeLog('${DateTime.now()}  LoopImage2\n');
          context.read<Images>().changeImages('$dir/${images[imageIndex]}');
          changeImages();
          flagImage = false;
        }
      });
    }
  }

  Future<void> loopImages() async {
    if (flagVideo == false) {
      flagImage = true;
      await writeLog('${DateTime.now()}  LoopImageInit\n');
      imageCache.clear();
      imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
      await precacheImage(
          FileImage(File('$dir/${images[imageIndex]}')), context);
      flagImage = false;
    } else {
      Timer.periodic(Duration(milliseconds: 500), (timer) async {
        if (flagVideo == false) {
          flagImage = true;
          timer.cancel();
          await writeLog('${DateTime.now()}  LoopImageInit2\n');
          imageCache.clear();
          imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
          await precacheImage(
              FileImage(File('$dir/${images[imageIndex]}')), context);
          flagImage = false;
        }
      });
    }

    periodicImages = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (flagVideo == false && flagImage == false) {
        flagImage = true;
        await writeLog('${DateTime.now()}  LoopImage\n');
        context.read<Images>().changeImages('$dir/${images[imageIndex]}');
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
          imageCache.clear();
          await precacheImage(
              FileImage(File('$dir/${images[imageIndex]}')), context);
          flagImage = false;
        });
      } else {
        Timer.periodic(Duration(milliseconds: 500), (t) async {
          if (flagVideo == false && flagImage == false) {
            flagImage = true;
            t.cancel();
            await writeLog('${DateTime.now()}  FlagVideo\n');
            context.read<Images>().changeImages('$dir/${images[imageIndex]}');
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
              imageIndex = imageIndex < images.length - 1 ? imageIndex + 1 : 0;
              imageCache.clear();
              await precacheImage(
                  FileImage(File('$dir/${images[imageIndex]}')), context);
              flagImage = false;
            });
          }
        });
      }
    });
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

    if (flagImage == false) {
      flagVideo = true;
      await writeLog('${DateTime.now()}  NextVideo1\n');
      previousControllerIndex = controllerIndex;
      controllerIndex = controllerIndex == 0 ? 1 : 0;
      videoIndex = videoIndex < videos.length - 1 ? videoIndex + 1 : 0;
      controllers[controllerIndex] =
          VideoPlayerController.file(File('$dir/${videos[videoIndex]}'));
      await controllers[controllerIndex]?.initialize();
      await writeLog('${DateTime.now()}  NextVideo2\n');
      await controllers[controllerIndex]?.play();
      attachListener(controllers[controllerIndex]);
      disposePreviousController();
      context.read<Controllers>().changeIndex(controllerIndex);
    } else {
      Timer.periodic(Duration(milliseconds: 500), (e) async {
        if (flagImage == false) {
          flagVideo = true;
          e.cancel();
          await writeLog('${DateTime.now()}  NextVideo1b\n');
          previousControllerIndex = controllerIndex;
          controllerIndex = controllerIndex == 0 ? 1 : 0;
          videoIndex = videoIndex < videos.length - 1 ? videoIndex + 1 : 0;
          controllers[controllerIndex] =
              VideoPlayerController.file(File('$dir/${videos[videoIndex]}'));
          await controllers[controllerIndex]?.initialize();
          await writeLog('${DateTime.now()}  NextVideo3\n');
          await controllers[controllerIndex]?.play();
          attachListener(controllers[controllerIndex]);
          disposePreviousController();
          context.read<Controllers>().changeIndex(controllerIndex);
        }
      });
    }
  }

  void disposePreviousController() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await controllers[previousControllerIndex]?.dispose();
      await writeLog('${DateTime.now()}  NextVideo4\n');
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
