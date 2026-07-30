/// Date-key helpers used to index goal completion history by day.
String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String todayKey() => dateKey(DateTime.now());

String twoDigits(int n) => n.toString().padLeft(2, '0');

String formatHms(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${twoDigits(h)}:${twoDigits(m)}:${twoDigits(s)}';
  }
  return '${twoDigits(m)}:${twoDigits(s)}';
}

String formatMinutesLabel(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayFull = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
