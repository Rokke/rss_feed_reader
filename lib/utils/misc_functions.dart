String padDateNumber(int val) => val.toString().padLeft(2, '0');
String dateTimeFormat(DateTime dt) => '${dt.year}-${padDateNumber(dt.month)}-${padDateNumber(dt.day)} ${padDateNumber(dt.hour)}:${padDateNumber(dt.minute)}';
String timeSinceNow(int millisecondsSinceEpoch) {
  if (millisecondsSinceEpoch == 0) return 'aldri';
  int totalTime = DateTime.now().millisecondsSinceEpoch - millisecondsSinceEpoch;
  if (totalTime < 2000) return '<1 sek';
  totalTime = totalTime ~/ 1000;
  if (totalTime < 60) return '$totalTime sek';
  totalTime = totalTime ~/ 60;
  if (totalTime < 60) return '$totalTime min';
  totalTime = totalTime ~/ 60;
  if (totalTime < 24) return '$totalTime timer';
  totalTime = totalTime ~/ 100;
  if (totalTime < 24) return '$totalTime dager';
  totalTime = totalTime ~/ 30;
  if (totalTime <= 12) return '$totalTime måneder';
  return '${totalTime / 12} år';
}
