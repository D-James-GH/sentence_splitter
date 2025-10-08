import 'package:sentence_splitter/src/sentence.dart';
import 'package:sentence_splitter/src/sentence_processor.dart';

// List<String> splitSentences(String text) {
//   return text.splitSentences().map((s) => s.text).toList();
// }
List<String> splitSentences(String text) {
  final sentences = <String>[];
  final iterator = SentenceIterator(text.trim());
  while (iterator.moveNext()) {
    sentences.add(iterator.current.text);
  }
  return sentences;
}

extension SentenceSplitterExt on String {
  Iterable<Sentence> splitSentences() => SentenceIterable(this);
}

class SentenceIterable extends Iterable<Sentence> {
  final String _text;

  SentenceIterable(this._text);

  @override
  Iterator<Sentence> get iterator => SentenceIterator(_text);
}

class SentenceIterator implements Iterator<Sentence> {
  SentenceIterator(this._text);
  String _text;

  Sentence? _current;

  @override
  Sentence get current {
    if (_current == null) {
      throw StateError('No current sentence. Call moveNext() first.');
    }
    return _current!;
  }

  @override
  bool moveNext() {
    if (_text.isEmpty) {
      return false;
    }

    final (:sentence, :isComplete, :boundaryEnd) = findFirstSentence(_text);
    _current = Sentence(sentence, isComplete);
    _text = _text.substring(boundaryEnd + 1).trim();

    return sentence.isNotEmpty;
  }
}
