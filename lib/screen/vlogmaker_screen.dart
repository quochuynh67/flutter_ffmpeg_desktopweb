import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:flutter_ffmpeg_desktopweb/app_const.dart';
import 'package:flutter_ffmpeg_desktopweb/file_utils.dart';

import '../ffmpeg_manager.dart';

class VlogMakerScreen extends StatefulWidget {
  const VlogMakerScreen({Key? key}) : super(key: key);

  @override
  State<VlogMakerScreen> createState() => _VlogMakerScreenState();
}

class _VlogMakerScreenState extends State<VlogMakerScreen> {
  FilePickerResult? filePickerResult;

  /// File store
  final mediaList = ValueNotifier<List<Uint8List>>([]);
  final audioList = ValueNotifier<List<String>>([]);

  /// CMD
  String cmd = ''
      '-f concat '
      '-i input.txt '
      '';

  @override
  void initState() {
    FfmpegManager.instance.loadFFmpeg(() {}, setLog: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              /// Select video/image Button
              ///
              OutlinedButton(
                  onPressed: pickVideoImageFiles,
                  child: const Text('Select video/image')),

              /// Select audio Button
              ///
              OutlinedButton(
                  onPressed: pickAudioFiles,
                  child: const Text('Select background music')),
            ],
          ),

          /// Export button
          ///
          Row(
            children: [
              OutlinedButton(
                  onPressed: _handleExport,
                  child: const Text('Export as AutoCrop')),
              OutlinedButton(
                  onPressed: _handleExport,
                  child: const Text('Export as 9:16')),
              OutlinedButton(
                  onPressed: _handleExport,
                  child: const Text('Export as 16:9')),
              OutlinedButton(
                  onPressed: _handleExport, child: const Text('Export as 1:1')),
            ],
          ),

          /// Clips list
          ///
          Expanded(
            child: ValueListenableBuilder(
              builder: (context, data, __) {
                return ListView.builder(
                    itemCount: data.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, index) {
                      final bytes = data.elementAt(index);
                      return AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          color: Colors.grey,
                          child: Image.memory(bytes, fit: BoxFit.cover),
                        ),
                      );
                    });
              },
              valueListenable: mediaList,
            ),
          ),

          /// Clips list
          ///
          Expanded(
            child: ValueListenableBuilder(
              builder: (context, data, __) {
                return ListView.builder(
                    itemCount: data.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, index) {
                      final item = data.elementAt(index);
                      return Container(
                        color: Colors.grey,
                        padding: const EdgeInsets.all(8.0),
                        child: Text(item),
                      );
                    });
              },
              valueListenable: audioList,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickAudioFiles() async {
    filePickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
        allowMultiple: false);

    if (filePickerResult != null) {
      List<String> picked = [];
      for (int i = 0; i < filePickerResult!.files.length; ++i) {
        final file = filePickerResult!.files.elementAt(i);
        FfmpegManager.instance.ffmpeg.writeFile('audio$i.mp3', file.bytes!);
        picked.add(''
            '\n- name: ${file.name} '
            '\n- extension: ${file.extension} '
            '\n- bytes: ${file.bytes?.length}');

        cmd += '-i audio$i.mp3 ';
      }
      audioList.value = picked;
    }
  }

  Future<void> pickVideoImageFiles() async {
    filePickerResult = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: true);

    if (filePickerResult != null) {
      List<Uint8List> picked = [];
      String input = '';
      for (int i = 0; i < filePickerResult!.files.length; ++i) {
        final file = filePickerResult!.files.elementAt(i);
        picked.add(file.bytes!);
        FfmpegManager.instance.ffmpeg.writeFile('input$i.png', file.bytes!);
        input +=
            'file ${'input$i.png'}\nduration ${AppConst.IMAGE_DEFAULT_DURATION}\n';
      }
      FfmpegManager.instance.ffmpeg
          .writeFile('input.txt', Uint8List.fromList(utf8.encode(input)));
      mediaList.value = picked;
    }
  }

  Future<void> _handleExport() async {
    cmd = '$cmd output.mp4';
    print('HAHA _handleExport cmd $cmd');
    await FfmpegManager.instance.ffmpeg.runCommand(cmd);
    FileUtils.downloadVideoOutputInWeb('output.mp4');
  }
}
