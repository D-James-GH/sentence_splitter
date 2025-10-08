import 'package:sentence_splitter/sentence_splitter.dart';

/// {@template sentence}
/// Sentence with text and range.
/// {@endtemplate}
class Sentence {
  /// The text of the sentence.
  final String text;

  /// The range of the sentence relative to the whole text.
  final Range range;

  /// {@macro sentence}
  const Sentence(this.text, this.range);

  @override
  String toString() {
    return 'Sentence(text: $text, range: $range)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sentence && text == other.text && range == other.range;

  @override
  int get hashCode => text.hashCode ^ range.hashCode;
}
