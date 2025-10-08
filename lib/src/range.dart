class Range {
  final int start;
  final int end;
  Range(this.start, this.end);

  @override
  String toString() {
    return 'Range(start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Range && start == other.start && end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
