import 'package:sentence_splitter/src/range.dart';
import 'package:sentence_splitter/src/sentence.dart';
import 'package:sentence_splitter/src/sentence_processor.dart';
import 'package:sentence_splitter/src/trim.dart';

/// Split a string into sentences.
List<String> splitSentences(String text) {
  final sentences = <String>[];
  final iterator = SentenceIterator(text);
  while (iterator.moveNext()) {
    sentences.add(iterator.current.text);
  }
  return sentences;
}

/// Extension method to split a string into an iterable of sentences.
extension SentenceSplitterExt on String {
  /// Split the string into an iterable of sentences.
  Iterable<Sentence> splitSentences() => SentenceIterable(this);
}

/// {@template sentence_iterable}
/// Iterable of sentences.
/// {@endtemplate}
class SentenceIterable extends Iterable<Sentence> {
  final String _text;

  /// {@macro sentence_iterable}
  SentenceIterable(this._text);

  @override
  Iterator<Sentence> get iterator => SentenceIterator(_text);
}

/// {@template sentence_iterator}
/// Iterator of sentences.
/// {@endtemplate}
class SentenceIterator implements Iterator<Sentence> {
  /// {@macro sentence_iterator}
  SentenceIterator(this._text);
  String _text;
  int _sentenceStart = 0;

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

    final (sentence: s, isComplete: _, :boundaryEnd) = findNextSentence(_text);
    final (text: sentence, :trimmedStart, :trimmedEnd) = trimWithRange(s);
    final range = Range(
      start: _sentenceStart + trimmedStart,
      end: _sentenceStart + boundaryEnd - trimmedEnd,
    );
    _sentenceStart += boundaryEnd + 1;
    _text = _text.substring(boundaryEnd + 1);
    _current = Sentence(sentence, range);

    return sentence.isNotEmpty;
  }
}
