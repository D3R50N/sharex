import 'dart:io';

extension FileExtension on File {
  bool get isImage =>
      path.endsWith('.jpg') ||
      path.endsWith('.png') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp');
  bool get isVideo =>
      path.endsWith('.mp4') ||
      path.endsWith('.mkv') ||
      path.endsWith('.avi') ||
      path.endsWith('.mov') ||
      path.endsWith('.wmv') ||
      path.endsWith('.flv') ||
      path.endsWith('.webm');
  bool get isAudio =>
      path.endsWith('.mp3') ||
      path.endsWith('.wav') ||
      path.endsWith('.ogg') ||
      path.endsWith('.m4a') ||
      path.endsWith('.flac');

  String get extension => path.split('.').last;
  String get name => path.split(Platform.pathSeparator).last;
}
