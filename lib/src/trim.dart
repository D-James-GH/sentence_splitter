/// Trims the text and returns the trimmed text and the number of characters trimmed from the start and end.
({String text, int trimmedStart, int trimmedEnd}) trimWithRange(String text) {
  final leftTrimmed = text.trimLeft();
  final int start = text.length - leftTrimmed.length;
  text = leftTrimmed;
  final rightTrimmed = text.trimRight();
  final int end = text.length - rightTrimmed.length;
  text = rightTrimmed;
  return (text: text, trimmedStart: start, trimmedEnd: end);
}
