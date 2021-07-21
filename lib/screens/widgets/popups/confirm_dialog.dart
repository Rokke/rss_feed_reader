import 'package:flutter/material.dart';

Future<bool?> confirmChoice(BuildContext context, String title, String body) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      titlePadding: const EdgeInsets.all(5),
      contentPadding: const EdgeInsets.all(10),
      title: Center(child: Text(title)),
      content: Container(
        constraints: const BoxConstraints.tightFor(width: 160),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(8).copyWith(bottom: 20),
            color: (HSLColor.fromColor(Theme.of(context).backgroundColor).withLightness(0.3)).toColor(),
            child: Column(
              children: [
                Center(child: Text(body)),
              ],
            ),
          ),
          Container(
              margin: const EdgeInsets.only(top: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.cancel), label: const Text('Avbryt')),
                Flexible(child: Container()),
                ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(true), icon: const Icon(Icons.verified), label: const Text('OK')),
              ])),
        ]),
      ),
    ),
  );
}
