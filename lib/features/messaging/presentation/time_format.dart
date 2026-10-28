/// "14:05" today, "12/03" otherwise (French order).
String shortTime(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  return sameDay
      ? '${two(local.hour)}:${two(local.minute)}'
      : '${two(local.day)}/${two(local.month)}';
}
