import 'dart:html' as html;
import 'dart:js' as js;

import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg_desktopweb/ffmpeg_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoaded = false;
  String? selectedFile;
  String? conversionStatus;

  FilePickerResult? filePickerResult;

  @override
  void initState() {
    isLoaded = FfmpegManager.instance.isLoaded;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 8),
            Text('Conversion Status : $conversionStatus'),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: FfmpegManager.instance.progress,
              builder: (context, value, child) {
                return value == null
                    ? const SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Exporting ${(value * 100).ceil()}%'),
                          const SizedBox(width: 6),
                          const CircularProgressIndicator(),
                        ],
                      );
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: FfmpegManager.instance.statistics,
              builder: (context, value, child) {
                return value == null
                    ? const SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(value),
                          const SizedBox(width: 6),
                          const CircularProgressIndicator(),
                        ],
                      );
              },
            ),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16),
                children: [
                  OutlinedButton(
                    onPressed: extractFirstFrame,
                    child: const Text('Extract First Frame'),
                  ),
                  OutlinedButton(
                    onPressed: createPreviewVideo,
                    child: const Text('Create Preview Image'),
                  ),
                  OutlinedButton(
                    onPressed: create720PQualityVideo,
                    child: const Text('Video 720P Quality'),
                  ),
                  OutlinedButton(
                    onPressed: create480PQualityVideo,
                    child: const Text('Video 480P Quality'),
                  ),
                  OutlinedButton(
                    onPressed: heicToJpeg,
                    child: const Text('[IOS] HEIC to jpeg'),
                  ),
                  OutlinedButton(
                    onPressed: movToMp4,
                    child: const Text('[IOS] MOV to MP4'),
                  ),
                  OutlinedButton(
                    onPressed: navigateToVlogMakerScreen,
                    child: const Text('Images to video with music'),
                  ),

                  OutlinedButton(
                    onPressed: navigateToQuoteMakerScreen,
                    child: const Text('Tạo quote/music'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickFile({List<String>? allowExt}) async {
    if (allowExt != null && allowExt.isNotEmpty) {
      filePickerResult = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: allowExt);
    } else {
      filePickerResult =
          await FilePicker.platform.pickFiles(type: FileType.video);
    }

    if (filePickerResult != null &&
        filePickerResult!.files.single.bytes != null) {
      /// Writes File to memory
      FfmpegManager.instance.ffmpeg.writeFile(
          'input.${filePickerResult!.files.single.extension}',
          filePickerResult!.files.single.bytes!);

      setState(() {
        selectedFile = 'input.${filePickerResult!.files.single.extension}';
      });
    }
  }

  /// Extracts First Frame from video
  Future<void> extractFirstFrame() async {
    await pickFile();
    await FfmpegManager.instance.ffmpeg.run([
      '-i',
      '$selectedFile',
      '-vf',
      "select='eq(n,0)'",
      '-vsync',
      '0',
      'frame1.webp'
    ]);
    final data = FfmpegManager.instance.ffmpeg.readFile('frame1.webp');
    js.context.callMethod('webSaveAs', [
      html.Blob([data]),
      'frame1.webp'
    ]);
  }

  /// Creates Preview Image of Video
  Future<void> createPreviewVideo() async {
    await pickFile();
    await FfmpegManager.instance.ffmpeg.run([
      '-i',
      'input.mp4',
      '-t',
      '5.0',
      '-ss',
      '2.0',
      '-s',
      '480x720',
      '-f',
      'webp',
      '-r',
      '5',
      'previewWebp.webp'
    ]);
    final previewWebpData =
        FfmpegManager.instance.ffmpeg.readFile('previewWebp.webp');
    js.context.callMethod('webSaveAs', [
      html.Blob([previewWebpData]),
      'previewWebp.webp'
    ]);
  }

  Future<void> create720PQualityVideo() async {
    await pickFile();
    setState(() {
      conversionStatus = 'Started';
    });
    await FfmpegManager.instance.ffmpeg.run([
      '-i',
      'input.mp4',
      '-s',
      '720x1280',
      '-c:a',
      'copy',
      '720P_output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Saving';
    });
    final hqVideo = FfmpegManager.instance.ffmpeg.readFile('720P_output.mp4');
    setState(() {
      conversionStatus = 'Downloading';
    });
    js.context.callMethod('webSaveAs', [
      html.Blob([hqVideo]),
      '720P_output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Completed';
    });
  }

  Future<void> create480PQualityVideo() async {
    await pickFile();
    setState(() {
      conversionStatus = 'Started';
    });
    await FfmpegManager.instance.ffmpeg.run([
      '-i',
      'input.mp4',
      '-s',
      '480x720',
      '-c:a',
      'copy',
      '480P_output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Saving';
    });
    final hqVideo = FfmpegManager.instance.ffmpeg.readFile('480P_output.mp4');
    setState(() {
      conversionStatus = 'Downloading';
    });
    js.context.callMethod('webSaveAs', [
      html.Blob([hqVideo]),
      '480P_output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Completed';
    });
  }

  void navigateToVlogMakerScreen() {
    Navigator.pushNamed(context, '/vlogMaker');
  }

  void navigateToQuoteMakerScreen() {
    Navigator.pushNamed(context, '/quoteMaker');
  }

  Future<void> heicToJpeg() async {
    await pickFile(allowExt: ['heic']);
    setState(() {
      conversionStatus = 'Started - HEIC to jpeg/png';
    });
    await FfmpegManager.instance.ffmpeg.run([
      '-i',
      '$selectedFile',
      'output.jpg'
    ]);
    setState(() {
      conversionStatus = 'Saving';
    });
    final hqVideo = FfmpegManager.instance.ffmpeg.readFile('output.jpg');
    if (hqVideo.isEmpty) {
      setState(() {
        conversionStatus = 'Failed';
      });
    }
    setState(() {
      conversionStatus = 'Downloading';
    });
    js.context.callMethod('webSaveAs', [
      html.Blob([hqVideo]),
      'output.jpg'
    ]);
    setState(() {
      conversionStatus = 'Completed';
    });
  }

  Future<void> movToMp4() async {
    await pickFile(allowExt: ['mov']);
    setState(() {
      conversionStatus = 'Started - MOV to MP4';
    });
    await FfmpegManager.instance.ffmpeg.run([
      '-i',
      '$selectedFile',
      '-c', 'copy', '-movflags' ,'+faststart',
      'output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Saving';
    });
    final hqVideo = FfmpegManager.instance.ffmpeg.readFile('output.mp4');
    if (hqVideo.isEmpty) {
      setState(() {
        conversionStatus = 'Failed';
      });
    }
    setState(() {
      conversionStatus = 'Downloading';
    });
    js.context.callMethod('webSaveAs', [
      html.Blob([hqVideo]),
      'output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Completed';
    });
  }
}
