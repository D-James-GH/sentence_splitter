class Sentence {
  final String text;
  final bool isComplete;
  Sentence(this.text, this.isComplete);

  @override
  String toString() {
    return 'Sentence(text: $text, isComplete: $isComplete)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sentence && text == other.text && isComplete == other.isComplete;

  @override
  int get hashCode => text.hashCode ^ isComplete.hashCode;
}
