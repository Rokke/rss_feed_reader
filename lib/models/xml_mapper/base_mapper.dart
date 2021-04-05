class XMLBaseMapper {
  String? getMonthNumber(String month) {
    switch (month) {
      case 'Jan':
        return '01';
      case 'Feb':
        return '02';
      case 'Mar':
        return '03';
      case 'Apr':
        return '04';
      case 'May':
        return '05';
      case 'Jun':
        return '06';
      case 'Jul':
        return '07';
      case 'Aug':
        return '08';
      case 'Sep':
        return '09';
      case 'Oct':
        return '10';
      case 'Nov':
        return '11';
      case 'Dec':
        return '12';
      default:
        assert(true, 'Illegal month name: $month');
    }
  }

  DateTime? parseRSSString(String val) {
    final parts = val.split(' ');
    return DateTime.tryParse('${parts[3]}-${getMonthNumber(parts[2])!}-${parts[1].padLeft(2, "0")}T${parts[4].padLeft(2, "0")}${parts[5].padLeft(2, "0")}');
  }
}
