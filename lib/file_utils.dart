import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';

import 'ffmpeg_manager.dart';

class FileUtils {
  static List<int> writeTextFile(String text, {String fileName = 'input.txt'}) {
    // prepare
    final bytes = utf8.encode(text);
    final blob = Blob([bytes]);
    final url = Url.createObjectUrlFromBlob(blob);
    final anchor = document.createElement('a') as AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    document.body?.children.add(anchor);

    // download
    anchor.click();

    // cleanup
    document.body?.children.remove(anchor);
    Url.revokeObjectUrl(url);

    return bytes;
  }

  static void downloadVideoOutputInWeb(String outputFileName) {
    final outputVideo = FfmpegManager.instance.ffmpeg.readFile(outputFileName);
    context.callMethod('webSaveAs', [
      Blob([outputVideo]),
      outputFileName
    ]);
  }
}
