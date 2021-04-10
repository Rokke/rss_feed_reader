import 'package:flutter/material.dart';
import 'package:moor/moor.dart' as moor;
import 'package:rss_feed_reader/screens/widgets/popups/color_picker.dart';
import 'package:rss_feed_reader/utils/popup_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';

final categoryProvider = StreamProvider.autoDispose.family<CategoryData?, String>((ref, category) {
  final db = ref.watch(rssDatabase);
  final ret = db.fetchCategoryByName(categoryName: category);
  return ret;
});

class CategoryWidget extends ConsumerWidget {
  final String categoryName;
  final int articleId;
  const CategoryWidget(this.articleId, this.categoryName, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final categoryRef = watch(categoryProvider(categoryName));
    return categoryRef.when(
      data: (category) {
        final backgroundColor = category?.color != null ? Color(category!.color!) : Colors.black;
        final textColor = backgroundColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;
        return Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(3)),
            child: GestureDetector(
                child: Hero(
                    tag: '${CategoryPopup.HERO_TAG}$articleId$categoryName',
                    child: Material(
                        color: backgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: SingleChildScrollView(
                            child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                margin: EdgeInsets.all(2),
                                child: Text(
                                  category?.displayName ?? categoryName,
                                  style: TextStyle(color: textColor),
                                ))))),
                onTap: () async {
                  final ret = await Navigator.of(context).push(HeroDialogRoute(builder: (context) {
                    return CategoryPopup(articleId, category ?? CategoryData(name: categoryName));
                  }));
                  if (ret != null) {
                    if (category != null)
                      context.read(rssDatabase).updateCategory(categoryId: category.id, categoryCompanion: CategoryCompanion(name: moor.Value(categoryName), displayName: moor.Value(category.displayName), color: ret));
                    else
                      context.read(rssDatabase).insertCategory(CategoryCompanion.insert(name: categoryName, displayName: moor.Value(categoryName), color: ret));
                  }
                }));
      },
      loading: () => Container(),
      error: (err, _) {
        debugPrint('Err: $err');
        return Container(color: Colors.red, child: Text(err.toString()));
      },
    );
  }
}
