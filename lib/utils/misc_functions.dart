import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:win32/win32.dart';

String padDateNumber(int val) => val.toString().padLeft(2, '0');
String dateTimeFormat(DateTime dt) => '${dt.year}-${padDateNumber(dt.month)}-${padDateNumber(dt.day)} ${padDateNumber(dt.hour)}:${padDateNumber(dt.minute)}';
String timeSinceNow(int millisecondsSinceEpoch) {
  if (millisecondsSinceEpoch == 0) return 'aldri';
  var totalTime = DateTime.now().millisecondsSinceEpoch - millisecondsSinceEpoch;
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

String smartDateTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff > const Duration(days: 100)) return '${dt.year}-${dt.month}-${dt.day}';
  if (diff > const Duration(days: 20)) return '${dt.month}-${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, "0")}';
  if (diff > const Duration(hours: 20)) {
    return '${dt.day} ${timeFormat(dt, ignoreSeconds: true)}';
  } else {
    return timeFormat(dt);
  }
}

String timeFormat(DateTime dt, {bool ignoreSeconds = false}) => '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}${ignoreSeconds ? '' : ':' + dt.second.toString().padLeft(2, "0")}';

String fetchHostUrl(String fullLink) {
  String url;
  final link = fullLink + '/';
  try {
    if (link.toLowerCase().startsWith('https')) {
      url = 'https://';
    } else {
      url = 'http://';
    }
    final startPos = link.indexOf('//');
    if (startPos > 0) {
      url += link.substring(startPos + 2, link.indexOf('/', startPos + 2));
    } else {
      url += link.substring(0, link.indexOf('/', startPos + 2));
    }
    return url;
  } catch (err) {
    debugPrint('fetchHostUrl error: $fullLink, error: $err');
    rethrow;
  }
}

Future<void> launchURL(String url) async {
  final completeUrl = url.startsWith('http') ? url : 'http://$url';
  if (await canLaunch(completeUrl)) {
    await launch(completeUrl);
  } else {
    throw 'Could not launch $url';
  }
}

// void powershellBeep() {
//   try {
//     Process.runSync('pwsh', ['-c', 'Invoke-Command', '-ScriptBlock', '{[System.Console]::Beep(2000,100); [System.Console]::Beep(3000,100)}']);
//   } catch (err) {
//     debugPrint('updateTweetsFromUser()-error playing sound: $err');
//   }
// }

void showSnackbar(BuildContext context, String text, {IconData? icon = Icons.info, Color color = Colors.green, TextStyle? textStyle}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(icon),
            ),
          Text(text, style: textStyle ?? Theme.of(context).textTheme.bodyText1),
        ],
      ),
      backgroundColor: color,
    ));

Future<void> playSound({required SOUND_FILE soundFile, Logger? log}) async {
  debugPrint('playSound($soundFile)');
  if (log != null) log.fine('playSound: $soundFile: ${soundFile.path}');
  debugPrint('test: ${compute(playSoundIsolate, soundFile.path)}');
  debugPrint('playSound func finished');
}

enum SOUND_FILE { SOUND_NEWTWEET, SOUND_NEWITEM }

extension SoundPath on SOUND_FILE {
  String get _pathExtra => kDebugMode ? '' : 'data/flutter_assets/';
  String get path {
    switch (this) {
      case SOUND_FILE.SOUND_NEWITEM:
        return '${_pathExtra}assets/sounds/article.wav';
      default:
        return '${_pathExtra}assets/sounds/twitter.wav';
    }
  }
}

int playSoundIsolate(String soundFilename) {
  debugPrint('sound: soundFile: $soundFilename');
  final sound = TEXT(soundFilename);
  PlaySound(sound, NULL, SND_ALIAS);
  free(sound);
  debugPrint('played sound');
  return 0;
}
