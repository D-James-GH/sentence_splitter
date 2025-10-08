import 'package:sentence_splitter/sentence_splitter.dart';

void main() {
  final text =
      'This is a sentence. And another one (and a nested.)! Is this the third? Yes, it is.';
  final sentences = splitSentences(text);

  // This is a sentence.
  // And another one (and a nested.)!
  // Is this the third?
  // Yes, it is.
  for (var sentence in sentences) {
    print(sentence);
  }
}
