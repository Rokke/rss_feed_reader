import 'package:flutter/material.dart';

class HeroDialogRoute<T> extends PageRoute<T> {
  final WidgetBuilder _builder;

  HeroDialogRoute({required WidgetBuilder builder, RouteSettings? settings, bool fullscreenDialog = false})
      : _builder = builder,
        super(settings: settings, fullscreenDialog: fullscreenDialog);
  @override
  Color? get barrierColor => Colors.black54;
  @override
  bool get opaque => false;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Popup dialog open';

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _builder(context);
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}
