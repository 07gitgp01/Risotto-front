String _two(int n) => n.toString().padLeft(2, '0');

const _weekdays = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];

/// Whole calendar days between [value] and [now] (0 = same day).
int _daysAgo(DateTime value, DateTime now) {
  final a = DateTime(value.year, value.month, value.day);
  final b = DateTime(now.year, now.month, now.day);
  return b.difference(a).inHours ~/ 24;
}

/// "14:05".
String clockTime(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// List timestamp: "14:05" today, "Hier", "Mar." this week, "12/03" otherwise.
String shortTime(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final days = _daysAgo(local, (now ?? DateTime.now()).toLocal());
  if (days <= 0) {
    return clockTime(local);
  }
  if (days == 1) {
    return 'Hier';
  }
  if (days < 7) {
    return _weekdays[local.weekday - 1];
  }
  return '${_two(local.day)}/${_two(local.month)}';
}

/// Activity timestamp: "à l’instant", "il y a 5 min", "il y a 2 h", "hier",
/// "il y a 3 jours", then the date.
String relativeTime(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final elapsed = current.difference(local);
  if (elapsed.inMinutes < 1) {
    return 'à l’instant';
  }
  if (elapsed.inHours < 1) {
    return 'il y a ${elapsed.inMinutes} min';
  }
  final days = _daysAgo(local, current);
  if (days == 0) {
    return 'il y a ${elapsed.inHours} h';
  }
  if (days == 1) {
    return 'hier';
  }
  if (days < 7) {
    return 'il y a $days jours';
  }
  return '${_two(local.day)}/${_two(local.month)}/${local.year}';
}

/// Chat day separator: "Aujourd’hui", "Hier", or "12 mars 2026".
String dayLabel(DateTime value, {DateTime? now}) {
  const months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', //
    'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  final local = value.toLocal();
  final days = _daysAgo(local, (now ?? DateTime.now()).toLocal());
  if (days == 0) {
    return 'Aujourd’hui';
  }
  if (days == 1) {
    return 'Hier';
  }
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

/// Chat header: "Vu aujourd’hui à 14:05", "Vu hier à 09:12", "Vu le 3 mars 2026".
String lastSeenLabel(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final days = _daysAgo(local, (now ?? DateTime.now()).toLocal());
  if (days <= 0) {
    return 'Vu aujourd’hui à ${clockTime(local)}';
  }
  if (days == 1) {
    return 'Vu hier à ${clockTime(local)}';
  }
  return 'Vu le ${dayLabel(local, now: now)}';
}
