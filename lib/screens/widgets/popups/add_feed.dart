import 'package:flutter/material.dart';

class AddFeedPopup extends StatelessWidget {
  const AddFeedPopup({Key? key}) : super(key: key);
  static const HERO_TAG = 'popupHeroAddFeed';

  @override
  Widget build(BuildContext context) {
    TextEditingController txtUrl = TextEditingController();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Hero(
            tag: HERO_TAG,
            child: Material(
                color: Colors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  child: Container(
                      constraints: BoxConstraints.tightFor(width: 600, height: 500),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextField(controller: txtUrl, decoration: InputDecoration(labelText: 'RSS url')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, txtUrl.text), child: Text('Legg til RSS')),
                          ],
                        ),
                      )),
                ))),
      ),
    );
  }
}
