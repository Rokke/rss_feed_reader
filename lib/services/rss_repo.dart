

// class RSSRepo {
//   final _controller = StreamController<RSSArticle>();
//   int _index = 0;
//   Timer? _timer;

//   RSSRepo();
//   Stream<RSSArticle> startMonitoring() {
//     assert(_timer == null, 'Stream is active');
//     _timer = Timer.periodic(Duration(seconds: 5), _fetchInfo);
//     return _controller.stream;
//   }

//   close() {
//     _timer?.cancel();
//     _timer = null;
//     _controller.close();
//   }

//   bool get isActive => _timer != null;

//   void _fetchInfo(timer) {
//     debugPrint('Adding new');
//   }
// }
