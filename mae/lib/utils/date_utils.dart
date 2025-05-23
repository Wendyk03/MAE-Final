String formatEventDate(String dateStr) {
  try {
    final dt = DateTime.parse(dateStr);
    return '${_weekday(dt.weekday)}, ${_month(dt.month)} ${dt.day}, ${dt.year}';
  } catch (_) {
    return dateStr;
  }
}

String _weekday(int w) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return days[w - 1];
}

String _month(int m) {
  const months = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  return months[m];
}