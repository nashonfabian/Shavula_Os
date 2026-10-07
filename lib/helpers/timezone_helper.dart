const tanzaniaOffset = Duration(hours: 3);

DateTime tanzaniaNow() => DateTime.now().toUtc().add(tanzaniaOffset);

String tanzaniaDateOnly(dynamic value) {
  final text = '${value ?? ''}'.trim();
  if (text.length < 10) return text;

  final hasTimezone =
      RegExp(r'(?:Z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(text);
  if (!hasTimezone) return text.substring(0, 10);

  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text.substring(0, 10);

  final date = parsed.toUtc().add(tanzaniaOffset);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String tanzaniaTimestamp([DateTime? value]) {
  final date = (value ?? DateTime.now()).toUtc().add(tanzaniaOffset);
  String twoDigits(int part) => part.toString().padLeft(2, '0');

  return '${date.year.toString().padLeft(4, '0')}-${twoDigits(date.month)}-${twoDigits(date.day)}'
      'T${twoDigits(date.hour)}:${twoDigits(date.minute)}:${twoDigits(date.second)}'
      '.${date.millisecond.toString().padLeft(3, '0')}+03:00';
}
