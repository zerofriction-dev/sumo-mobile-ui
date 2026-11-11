enum MovingType {
  etc('etc', 'อื่นๆ'),
  knockdownHouse('knockdown-house', 'บ้านน็อคดาว์น'),
  container('container', 'ตู้คอนเทรนเนอร์'),
  earthCompactor('earth-compactor', 'รถบดดิน'),
  machine('machine', 'เครื่องจักร'),
  car('car', 'รถยนต์'),
  motorcycle('motorcycle', 'รถมอเตอร์ไซค์');

  const MovingType(this.value, this.label);

  final String value;
  final String label;

  static MovingType? fromString(String? type) {
    if (type == null) return null;
    for (final t in MovingType.values) {
      if (t.value == type) return t;
    }
    return null;
  }
}
