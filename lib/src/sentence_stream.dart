import 'dart:async';

import 'package:sentence_splitter/src/sentence_iterator.dart';

class SentenceStreamTransformer extends StreamTransformerBase<String, String> {
  const SentenceStreamTransformer();

  @override
  Stream<String> bind(Stream<String> stream) {
    return stream.transform(_SentenceStreamTransformerImpl());
  }
}

class _SentenceStreamTransformerImpl
    extends StreamTransformerBase<String, String> {
  @override
  Stream<String> bind(Stream<String> stream) {
    return Stream<String>.multi((StreamController<String> controller) {
      final buffer = StringBuffer();
      late StreamSubscription subscription;

      subscription = stream.listen(
        (String text) {
          buffer.write(text);
          _processInput(buffer, controller);
        },
        onError: controller.addError,
        onDone: () {
          _flush(buffer, controller);
          controller.close();
        },
        cancelOnError: false,
      );

      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  void _processInput(StringBuffer buffer, StreamController<String> controller) {
    final toProcess = buffer.toString();
    buffer.clear();

    for (final sentence in toProcess.splitSentences()) {
      if (sentence.isComplete) {
        controller.add(sentence.text);
      } else {
        buffer.write(sentence.text);
      }
    }
  }

  void _flush(StringBuffer buffer, StreamController<String> controller) {
    if (buffer.isNotEmpty) {
      controller.add(buffer.toString().trim());
      buffer.clear();
    }
  }
}

extension SentenceStreamExt on Stream<String> {
  /// Transforms this stream to emit complete sentences instead of raw text chunks.
  Stream<String> splitSentences() {
    return transform(const SentenceStreamTransformer());
  }
}
