/// {@template range}
/// Range of a text.
/// {@endtemplate}
class Range {
  /// Start index of the text.
  final int start;

  /// End index of the text.
  final int end;

  /// {@macro range}
  const Range({required this.start, required this.end});

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
