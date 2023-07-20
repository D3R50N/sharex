extension IntExtension on int {
  String get toFileSize {
    if (this < 1024) {
      return "$this b";
    } else if (this < 1024 * 1024) {
      return "${(this / 1024).toStringAsFixed(2)} ko";
    } else if (this < 1024 * 1024 * 1024) {
      return "${(this / (1024 * 1024)).toStringAsFixed(2)} mo";
    } else {
      return "${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} go";
    }
  }
}
