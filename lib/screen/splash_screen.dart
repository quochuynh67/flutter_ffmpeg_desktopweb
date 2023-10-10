
import 'package:flutter/material.dart';
import '../ffmpeg_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    FfmpegManager.instance.loadFFmpeg(() {
    }, onFailed: (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            titlePadding:  const EdgeInsets.all(0),
            contentPadding:  const EdgeInsets.all(0),
            content: SingleChildScrollView(
                child: Text(e)
            ),
          );
        },
      );
    }).whenComplete(() {
      Navigator.pushReplacementNamed(context, '/home');
      // Navigator.pushReplacementNamed(context, '/quoteMaker');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Splash Screen'),
      ),
    );
  }
}
