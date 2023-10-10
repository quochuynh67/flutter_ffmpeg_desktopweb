import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:flutter/material.dart';
import 'dart:js' as js;

class FfmpegManager {
  late FFmpeg ffmpeg;

  final progress = ValueNotifier<double?>(null);
  final statistics = ValueNotifier<String?>(null);
  final status = ValueNotifier<String?>(null);

  bool isLoaded = false;

  Future<void> loadFFmpeg(VoidCallback onInitialized, {bool setLog = true, Function(String)? onFailed}) async {
    try{
      js.context.callMethod('logger', [
        'FFmpegManager start 1'
      ]);
      ffmpeg = createFFmpeg(
        CreateFFmpegParam(
          log: true,
          corePath: 'https://unpkg.com/@ffmpeg/core@0.11.0/dist/ffmpeg-core.js',
        ),
      );

      if(setLog) {
        ffmpeg.setProgress(_onProgressHandler);
        ffmpeg.setLogger(_onLogHandler);
      }

      await ffmpeg.load();
      js.context.callMethod('logger', [
        'FFmpegManager await ffmpeg.load()'
      ]);
      checkLoaded();
      onInitialized.call();
    } catch(e) {
      js.context.callMethod('logger', [
        'FFmpegManager catch error when init $e'
      ]);
      onFailed?.call(e.toString());
    }
  }

  void checkLoaded() {
    isLoaded = ffmpeg.isLoaded();
    js.context.callMethod('logger', [
      'FFmpegManager checkLoaded isLoaded $isLoaded'
    ]);
  }

  void _onProgressHandler(ProgressParam progress) {
    final isDone = progress.ratio >= 1;

    this.progress.value = isDone ? null : progress.ratio;
    if (isDone) {
      statistics.value = null;
    }
  }

  static final regex = RegExp(
    r'frame\s*=\s*(\d+)\s+fps\s*=\s*(\d+(?:\.\d+)?)\s+q\s*=\s*([\d.-]+)\s+L?size\s*=\s*(\d+)\w*\s+time\s*=\s*([\d:\.]+)\s+bitrate\s*=\s*([\d.]+)\s*(\w+)/s\s+speed\s*=\s*([\d.]+)x',
  );

  void _onLogHandler(LoggerParam logger) {
    if (logger.type == 'fferr') {
      final match = regex.firstMatch(logger.message);

      if (match != null) {
        // indicates the number of frames that have been processed so far.
        final frame = match.group(1);
        // is the current frame rate
        final fps = match.group(2);
        // stands for quality 0.0 indicating lossless compression, other values indicating that there is some lossy compression happening
        final q = match.group(3);
        // indicates the size of the output file so far
        final size = match.group(4);
        // is the time that has elapsed since the beginning of the conversion
        final time = match.group(5);
        // is the current output bitrate
        final bitrate = match.group(6);
        // for instance: 'kbits/s'
        final bitrateUnit = match.group(7);
        // is the speed at which the conversion is happening, relative to real-time
        final speed = match.group(8);

        statistics.value =
            'frame: $frame, fps: $fps, q: $q, size: $size, time: $time, bitrate: $bitrate$bitrateUnit, speed: $speed';
      }
    }
  }

  void dispose() {
    progress.dispose();
    statistics.dispose();
  }

  static final FfmpegManager instance = FfmpegManager._internal();

  factory FfmpegManager() {
    return instance;
  }

  FfmpegManager._internal();
}

 enum ProcessingStatus {
   started,
   saving,
   downloading,
   completed
}