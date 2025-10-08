// ignore_for_file: avoid_print

import 'dart:async';

import 'package:sentence_splitter/sentence_splitter.dart';

void main() async {
  final text =
      'This is a sentence. And another one (and a nested.)! Is this the third? Yes, it is.';
  final sentences = splitSentences(text);

  // This is a sentence.
  // And another one (and a nested.)!
  // Is this the third?
  // Yes, it is.
  for (final sentence in sentences) {
    print(sentence);
  }

  for (final sentence in text.splitSentences()) {
    /// get the start and end index of the sentence, relative to the whole text
    print(sentence.range);
    print(sentence.text);
  }

  /// Add text in chunks, the stream will emit the sentences as they are complete
  final controller = StreamController<String>();
  final sentenceFuture = controller.stream.splitSentences().asString().toList();
  controller
    ..add("This is ")
    ..add("a full sentence.")
    ..add(" This is ")
    ..add("another full sentence.")
    ..close();
  final sentencesStream = await sentenceFuture;
  // prints
  // This is a full sentence.
  // This is another full sentence.
  for (final sentence in sentencesStream) {
    print(sentence);
  }
}
