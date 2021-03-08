import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:rss_feed_reader/database/database.dart';

class CategoryPopup extends StatelessWidget {
  final CategoryData category;
  const CategoryPopup(this.category, {Key? key}) : super(key: key);
  static const HERO_TAG = 'popupHeroCategoryPopup';

  @override
  Widget build(BuildContext context) {
    int? _color;
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
                            Text('Velg farge for ${category.name}'),
                            ColorPicker(pickerColor: category.color != null ? Color(category.color!) : Colors.black, onColorChanged: (color) => _color = color.value),
                            ElevatedButton(onPressed: () => Navigator.pop(context, _color), child: Text('Endre farge')),
                          ],
                        ),
                      )),
                ))),
      ),
    );
  }
}
