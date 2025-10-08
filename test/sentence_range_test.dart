import 'dart:async';

import 'package:sentence_splitter/sentence_splitter.dart';
import 'package:test/test.dart';

void main() {
  group("Iterator tests", () {
    test("Manual iterator test", () {
      final text = "This is a sentence. And another one!";
      final iterator = SentenceIterator(text);
      final sentences = <Sentence>[];
      while (iterator.moveNext()) {
        sentences.add(iterator.current);
      }
      expect(sentences.length, equals(2));
      expect(sentences[0].text, equals("This is a sentence."));
      expect(sentences[0].range, equals(Range(start: 0, end: 18)));
      expect(sentences[1].text, equals("And another one!"));
      expect(sentences[1].range, equals(Range(start: 20, end: 35)));
    });
    group("all iterator tests", () {
      for (final t in tests) {
        test(t.name, () {
          final sentences = t.input.splitSentences().toList();
          for (var i = 0; i < sentences.length; i++) {
            expect(sentences[i].text, equals(t.target[i].text));
            expect(sentences[i].range, equals(t.target[i].range));
          }
        });
      }
    });
  });
  test("Stream Basic", () async {
    final inputs = "This is a test. This is another test.".split('');
    final outputs = ["This is a test.", "This is another test."];
    final streamer = StreamController<String>();

    final sentenceFuture = streamer.stream.splitSentences().asString().toList();

    for (final chunk in inputs) {
      streamer.add(chunk);
    }
    streamer.close();

    final sentences = await sentenceFuture;
    expect(sentences, equals(outputs));
  });

  group('streaming full', () {
    final streamTests = [
      // Pre-defined test cases
      ...streamedTests,
      // Test that adding character by character (the most extreme case) also works correctly
      ...tests.map(
        (testCase) => StreamedTestCase(
          name: testCase.name,
          input: testCase.input.split(''),
          target: testCase.target,
        ),
      ),
    ];

    for (final testCase in streamTests) {
      test(testCase.name, () async {
        final streamer = StreamController<String>();

        final sentenceFuture = streamer.stream.splitSentences().toList();

        for (final chunk in testCase.input) {
          streamer.add(chunk);
        }
        streamer.close();

        final sentences = await sentenceFuture;
        expect(sentences, equals(testCase.target));
      });
    }
  });
}

class TestCase {
  final String name;
  final String input;
  final List<Sentence> target;

  const TestCase({
    required this.name,
    required this.input,
    required this.target,
  });
}

class StreamedTestCase {
  final String name;
  final List<String> input;
  final List<Sentence> target;

  const StreamedTestCase({
    required this.name,
    required this.input,
    required this.target,
  });
}

const tests = [
  TestCase(
    name: "Basic range",
    input: "This is a sentence",
    target: [Sentence("This is a sentence", Range(start: 0, end: 17))],
  ),
  TestCase(
    name: "Basic range with weird spaces",
    input: "      This is a sentence      ",
    target: [Sentence("This is a sentence", Range(start: 6, end: 23))],
  ),
  TestCase(
    name: "Basic range with even more weird spaces",
    input: "      This is a sentence      .",
    target: [Sentence("This is a sentence      .", Range(start: 6, end: 30))],
  ),
  TestCase(
    name: "Sentence with dash (em dash)",
    input: "This is a test — yes, it is.",
    target: [
      Sentence("This is a test — yes, it is.", Range(start: 0, end: 27)),
    ],
  ),
  TestCase(
    name: "Sentences with quoted speech",
    input: 'She said, "Hello there. How are you?". I replied, "I\'m fine."',
    target: [
      Sentence(
        'She said, "Hello there. How are you?".',

        Range(start: 0, end: 37),
      ),
      Sentence('I replied, "I\'m fine."', Range(start: 39, end: 60)),
    ],
  ),
  TestCase(
    name: "Sentences with abbreviations",
    input: "Dr. Smith is here. At 10 a.m. I saw him.",
    target: [
      Sentence("Dr. Smith is here.", Range(start: 0, end: 17)),
      Sentence("At 10 a.m. I saw him.", Range(start: 19, end: 39)),
    ],
  ),

  TestCase(
    name: "Ellipses in sentences",
    input: "Wait... what just happened? I don't understand...",
    target: [
      Sentence("Wait... what just happened?", Range(start: 0, end: 26)),
      Sentence("I don't understand...", Range(start: 28, end: 48)),
    ],
  ),
  TestCase(
    name: "Sentences with trailing spaces",
    input: "  This is a sentence.   Another one.  ",
    target: [
      Sentence("This is a sentence.", Range(start: 2, end: 20)),
      Sentence("Another one.", Range(start: 24, end: 35)),
    ],
  ),
  TestCase(
    name: "Sentences with mixed symbols",
    input: "Hello @John! How's it going? #excited",
    target: [
      Sentence("Hello @John!", Range(start: 0, end: 11)),
      Sentence("How's it going?", Range(start: 13, end: 27)),
      Sentence("#excited", Range(start: 29, end: 36)),
    ],
  ),
  TestCase(
    name: "Sequence of punctuation plus emoji",
    input: "What??! 🤯Wait??  Hello!",
    target: [
      Sentence("What??!", Range(start: 0, end: 6)),
      Sentence("🤯Wait??", Range(start: 8, end: 15)),
      Sentence("Hello!", Range(start: 18, end: 23)),
    ],
  ),
  TestCase(
    name: "Nested parentheses and quotes",
    input: '(This is "very (strange)" text). Right?',
    target: [
      Sentence('(This is "very (strange)" text).', Range(start: 0, end: 31)),
      Sentence("Right?", Range(start: 33, end: 38)),
    ],
  ),
  TestCase(
    name: "Long text with multiple sentences",
    input:
        "The sky above the port was the color of television, tuned to a dead channel.\n\"It's not like I'm using,\" Case heard someone say, as he shouldered his way through the crowd around the door of the Chat. \"It's like my body's developed this massive drug deficiency.\"\nIt was a Sprawl voice and a Sprawl joke. The Chatsubo was a bar for professional expatriates; you could drink there for a week and never hear two words in Japanese.\nThese were to have an enormous impact, not only because they were associated with Constantine, but also because, as in so many other areas, the decisions taken by Constantine (or in his name) were to have great significance for centuries to come. One of the main issues was the shape that Christian churches were to take, since there was not, apparently, a tradition of monumental church buildings when Constantine decided to help the Christian church build a series of truly spectacular structures. The main form that these churches took was that of the basilica, a multipurpose rectangular structure, based ultimately on the earlier Greek stoa, which could be found in most of the great cities of the empire. Christianity, unlike classical polytheism, needed a large interior space for the celebration of its religious services, and the basilica aptly filled that need. We naturally do not know the degree to which the emperor was involved in the design of new churches, but it is tempting to connect this with the secular basilica that Constantine completed in the Roman forum (the so-called Basilica of Maxentius) and the one he probably built in Trier, in connection with his residence in the city at a time when he was still caesar.",
    target: [
      Sentence(
        "The sky above the port was the color of television, tuned to a dead channel.",
        Range(start: 0, end: 75),
      ),
      Sentence(
        "\"It's not like I'm using,\" Case heard someone say, as he shouldered his way through the crowd around the door of the Chat.",
        Range(start: 77, end: 198),
      ),
      Sentence(
        "\"It's like my body's developed this massive drug deficiency.\"",
        Range(start: 200, end: 260),
      ),
      Sentence(
        "It was a Sprawl voice and a Sprawl joke.",
        Range(start: 262, end: 301),
      ),
      Sentence(
        "The Chatsubo was a bar for professional expatriates; you could drink there for a week and never hear two words in Japanese.",
        Range(start: 303, end: 425),
      ),
      Sentence(
        "These were to have an enormous impact, not only because they were associated with Constantine, but also because, as in so many other areas, the decisions taken by Constantine (or in his name) were to have great significance for centuries to come.",
        Range(start: 427, end: 672),
      ),
      Sentence(
        "One of the main issues was the shape that Christian churches were to take, since there was not, apparently, a tradition of monumental church buildings when Constantine decided to help the Christian church build a series of truly spectacular structures.",
        Range(start: 674, end: 925),
      ),
      Sentence(
        "The main form that these churches took was that of the basilica, a multipurpose rectangular structure, based ultimately on the earlier Greek stoa, which could be found in most of the great cities of the empire.",
        Range(start: 927, end: 1136),
      ),
      Sentence(
        "Christianity, unlike classical polytheism, needed a large interior space for the celebration of its religious services, and the basilica aptly filled that need.",
        Range(start: 1138, end: 1297),
      ),
      Sentence(
        "We naturally do not know the degree to which the emperor was involved in the design of new churches, but it is tempting to connect this with the secular basilica that Constantine completed in the Roman forum (the so-called Basilica of Maxentius) and the one he probably built in Trier, in connection with his residence in the city at a time when he was still caesar.",
        Range(start: 1299, end: 1664),
      ),
    ],
  ),
];
const List<StreamedTestCase> streamedTests = [
  StreamedTestCase(
    name: "Basic sentence splitting",
    input: [
      "I went",
      " to the",
      " store. I",
      " bought an apple for \$1.",
      "99. It was",
      " a good deal.",
    ],
    target: [
      Sentence("I went to the store.", Range(start: 0, end: 19)),
      Sentence("I bought an apple for \$1.99.", Range(start: 21, end: 48)),
      Sentence("It was a good deal.", Range(start: 50, end: 68)),
    ],
  ),
  StreamedTestCase(
    name: "URL with query parameters",
    input: ["Visit https://www", ".example.", "com", "?query=test."],
    target: [
      Sentence(
        "Visit https://www.example.com?query=test.",
        Range(start: 0, end: 40),
      ),
    ],
  ),
];
