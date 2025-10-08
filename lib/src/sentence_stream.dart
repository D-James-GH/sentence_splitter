import 'dart:async';

import 'package:sentence_splitter/sentence_splitter.dart';
import 'package:sentence_splitter/src/sentence_processor.dart';
import 'package:sentence_splitter/src/trim.dart';

/// {@template sentence_string_stream_ext}
/// Extension method to transform a stream of sentences into a stream of strings.
/// {@endtemplate}
extension SentenceStringStreamExt on Stream<Sentence> {
  /// {@macro sentence_string_stream_ext}
  Stream<String> asString() {
    return map((sentence) => sentence.text);
  }
}

/// {@template sentence_stream_ext}
/// Extension method to transform a stream of strings into a stream of sentences.
/// The stream will emit the sentences as they are complete.
/// The last text chunk added will be held until the next text chunk is added, to make sure
/// the sentence is complete.
/// {@endtemplate}
extension SentenceStreamExt on Stream<String> {
  /// {@macro sentence_stream_ext}
  Stream<Sentence> splitSentences() {
    return transform(const SentenceStreamTransformer());
  }
}

/// {@template sentence_stream_transformer}
/// Transformer to transform a stream of strings into a stream of sentences.
/// {@endtemplate}
class SentenceStreamTransformer
    extends StreamTransformerBase<String, Sentence> {
  /// {@macro sentence_stream_transformer}
  const SentenceStreamTransformer();

  @override
  Stream<Sentence> bind(Stream<String> stream) {
    return stream.transform(_SentenceStreamTransformerImpl());
  }
}

class _StreamState {
  String text = "";
  int sentenceStart = 0;
}

class _SentenceStreamTransformerImpl
    extends StreamTransformerBase<String, Sentence> {
  @override
  Stream<Sentence> bind(Stream<String> stream) {
    return Stream<Sentence>.multi((controller) {
      final state = _StreamState();
      StreamSubscription<String> subscription;

      subscription = stream.listen(
        (input) {
          state.text += input;
          _processInput(state, controller);
        },
        onError: controller.addError,
        onDone: () {
          _flush(state, controller);
          controller.close();
        },
        cancelOnError: false,
      );

      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  void _processInput(
    _StreamState state,
    StreamController<Sentence> controller,
  ) {
    var result = findNextSentence(state.text);

    while (result.isComplete && state.text.isNotEmpty) {
      final (text: sentence, :trimmedStart, :trimmedEnd) = trimWithRange(
        result.sentence,
      );

      final range = Range(
        start: state.sentenceStart + trimmedStart,
        end: state.sentenceStart + result.boundaryEnd - trimmedEnd,
      );
      controller.add(Sentence(sentence, range));

      state
        ..sentenceStart += result.boundaryEnd + 1
        ..text = state.text.substring(result.boundaryEnd + 1);
      result = findNextSentence(state.text);
    }
  }

  void _flush(_StreamState state, StreamController<Sentence> controller) {
    if (state.text.isNotEmpty) {
      final (text: sentence, :trimmedStart, :trimmedEnd) = trimWithRange(
        state.text,
      );

      final range = Range(
        start: state.sentenceStart + trimmedStart,
        end: (state.sentenceStart + state.text.length - 1) - trimmedEnd,
      );
      controller.add(Sentence(sentence, range));
      state.text = "";
    }
  }
}
