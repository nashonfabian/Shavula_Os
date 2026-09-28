const tanzaniaOffset = Duration(hours: 3);

DateTime tanzaniaNow() => DateTime.now().toUtc().add(tanzaniaOffset);

String tanzaniaTimestamp([DateTime? value]) {
  final date = (value ?? DateTime.now()).toUtc().add(tanzaniaOffset);
  String twoDigits(int part) => part.toString().padLeft(2, '0');

  return '${date.year.toString().padLeft(4, '0')}-${twoDigits(date.month)}-${twoDigits(date.day)}'
      'T${twoDigits(date.hour)}:${twoDigits(date.minute)}:${twoDigits(date.second)}'
      '.${date.millisecond.toString().padLeft(3, '0')}+03:00';
}
