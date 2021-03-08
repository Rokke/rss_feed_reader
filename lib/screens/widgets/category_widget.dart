import 'package:flutter/material.dart';
import 'package:rss_feed_reader/screens/widgets/popups/color_picker.dart';
import 'package:rss_feed_reader/utils/popup_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';

final categoryProvider = StreamProvider.autoDispose.family<CategoryData, String>((ref, category) {
  final db = ref.watch(rssDatabase);
  final ret = db.findCategory(category).watchSingle();
  () async {
    if (await ret.isEmpty) db.into(db.category).insert(CategoryData(name: category));
    debugPrint('Added new category: $category');
  }();
  return ret;
});

class CategoryWidget extends ConsumerWidget {
  final String categoryName;
  const CategoryWidget(this.categoryName, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final categoryRef = watch(categoryProvider(categoryName));
    return categoryRef.when(
      data: (category) => Container(
          padding: EdgeInsets.symmetric(horizontal: 4),
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(color: category.color != null ? Color(category.color!) : Colors.black, borderRadius: BorderRadius.circular(3)),
          child: GestureDetector(
              child: Hero(tag: CategoryPopup.HERO_TAG, child: Text(category.displayName ?? category.name)),
              onTap: () async {
                final ret = await Navigator.of(context).push(HeroDialogRoute(builder: (context) {
                  return CategoryPopup(category);
                }));
                if (ret != null) context.read(rssDatabase).updateCategory(category.name, category.displayName, ret, category.id);
              })),
      loading: () => Container(),
      error: (err, _) {
        debugPrint('Err: $err');
        // context.read(rssDatabase).addCategory(categoryName, null, null);
        return Container(color: Colors.red, child: Text(err.toString()));
      },
    );
  }
}
