String padDateNumber(int val) => val.toString().padLeft(2, '0');
String dateTimeFormat(DateTime dt) => '${dt.year}-${padDateNumber(dt.month)}-${padDateNumber(dt.day)} ${padDateNumber(dt.hour)}:${padDateNumber(dt.minute)}';
