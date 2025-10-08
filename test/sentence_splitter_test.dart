/*
 * Portions of this file are derived from hexgrad/kokoro
 * Original source: https://github.com/hexgrad/kokoro/blob/5229a254b7b9573c053d6dc91b133d80ff72a458/kokoro.js/tests/splitting.test.js
 * 
 * Licensed under the Apache License, Version 2.0
 * Original copyright holder: hexgrad/kokoro Contributors
 * 
 */
import "dart:async";

import "package:sentence_splitter/sentence_splitter.dart";
import "package:test/test.dart";

void main() {
  test("Sentence iterator", () {
    final text =
        "Hello world, I live in the U.K not near london. This is a test. Let's see how it works.";
    final iterator = SentenceIterable(text);
    final sentences = <String>[];
    for (final sentence in iterator) {
      sentences.add(sentence.text);
    }

    expect(sentences.length, 3);
    expect(
      sentences[0],
      equals("Hello world, I live in the U.K not near london."),
    );
    expect(sentences[1], equals("This is a test."));
    expect(sentences[2], equals("Let's see how it works."));
  });

  group('synchronous', () {
    for (final testCase in tests) {
      test(testCase.name, () {
        expect(splitSentences(testCase.input), equals(testCase.target));
      });
    }

    for (final testCase in additionalTests) {
      test(testCase.name, () {
        expect(splitSentences(testCase.input), equals(testCase.target));
      });
    }

    for (final testCase in wikimediaTests) {
      test(testCase.name, () {
        expect(splitSentences(testCase.input), equals(testCase.target));
      });
    }
  });
  group("streaming", () {
    test("Sentence incomplete iterator", () async {
      final input = StreamController<String>();

      final res = () async {
        final sentences = <String>[];
        await for (final sentence in input.stream.splitSentences()) {
          sentences.add(sentence);
        }
        return sentences;
      }();

      input.add("Hello, world.");
      input.add(" This is a test. Where the sentences are incom");
      input.add("plete at first. Let's see how it works.");
      input.close();
      expect(
        await res,
        equals([
          "Hello, world.",
          "This is a test.",
          "Where the sentences are incomplete at first.",
          "Let's see how it works.",
        ]),
      );
    });
  });

  test('asynchronous stream await for', () async {
    final streamer = StreamController<String>();
    // Initial text
    streamer.add("Hello, how are");

    // Consumes the stream asynchronously
    final sentences = <String>[];
    final consumeStream = () async {
      await for (final sentence in streamer.stream.splitSentences()) {
        sentences.add(sentence);
      }
    }();

    Future.delayed(const Duration(milliseconds: 10), () {
      streamer.add(" you? I'm fine, thanks.");
    });
    Future.delayed(const Duration(milliseconds: 20), () {
      streamer.add(" This is a test. This is unfinish-");
    });
    Future.delayed(const Duration(milliseconds: 30), () {
      streamer.add("ed.");
      streamer.add(" Finished.");
    });
    Future.delayed(const Duration(milliseconds: 40), () {
      streamer.close();
    });

    await consumeStream;
    expect(
      sentences,
      equals([
        "Hello, how are you?",
        "I'm fine, thanks.",
        "This is a test.",
        "This is unfinish-ed.",
        "Finished.",
      ]),
    );
  });
  test("Stream Basic", () async {
    final inputs = "This is a test. This is another test.".split('');
    final outputs = ["This is a test.", "This is another test."];
    final streamer = StreamController<String>();

    final sentences = <String>[];
    final consumeStream = () async {
      await for (final sentence in streamer.stream.splitSentences()) {
        sentences.add(sentence);
      }
    }();

    for (final chunk in inputs) {
      streamer.add(chunk);
    }
    streamer.close();

    await consumeStream;
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

        final sentences = <String>[];
        final consumeStream = () async {
          await for (final sentence in streamer.stream.splitSentences()) {
            sentences.add(sentence);
          }
        }();

        for (final chunk in testCase.input) {
          streamer.add(chunk);
        }
        streamer.close();

        await consumeStream;
        expect(sentences, equals(testCase.target));
      });
    }
  });
}

class TestCase {
  final String name;
  final String input;
  final List<String> target;

  const TestCase({
    required this.name,
    required this.input,
    required this.target,
  });
}

class StreamedTestCase {
  final String name;
  final List<String> input;
  final List<String> target;

  const StreamedTestCase({
    required this.name,
    required this.input,
    required this.target,
  });
}

const List<TestCase> tests = [
  TestCase(
    name: "Basic sentence splitting",
    input: "This is a test. This is another test.",
    target: ["This is a test.", "This is another test."],
  ),
  TestCase(
    name: "Sentence with dash (em dash)",
    input: "This is a test — yes, it is.",
    target: ["This is a test — yes, it is."],
  ),
  TestCase(
    name: "Sentences with quoted speech",
    input: 'She said, "Hello there. How are you?". I replied, "I\'m fine."',
    target: [
      'She said, "Hello there. How are you?".',
      'I replied, "I\'m fine."',
    ],
  ),
  TestCase(
    name: "Sentences with abbreviations",
    input: "Dr. Smith is here. At 10 a.m. I saw him.",
    target: ["Dr. Smith is here.", "At 10 a.m. I saw him."],
  ),
  TestCase(
    name: "Advanced sentences with abbreviations",
    input: "I went to Dr. Smith this morning at 10 a.m. and said hi.",
    target: ["I went to Dr. Smith this morning at 10 a.m. and said hi."],
  ),
  TestCase(
    name: "Abbreviations with possessive",
    input: "The Dr.'s office.",
    target: ["The Dr.'s office."],
  ),
  TestCase(
    name: "Ellipses in sentences",
    input: "Wait... what just happened? I don't understand...",
    target: ["Wait... what just happened?", "I don't understand..."],
  ),
  TestCase(
    name: "Sentences with numbers and decimals",
    input: "The price is \$4.99. Do you want to buy it?",
    target: ["The price is \$4.99.", "Do you want to buy it?"],
  ),
  TestCase(
    name: "Sentences starting and ending with numbers",
    input: "10 people died in 2025. 20 people died in 2026.",
    target: ["10 people died in 2025.", "20 people died in 2026."],
  ),
  TestCase(
    name: "Sentences with scientific notation",
    input: "The star is 3.2×10^4 light-years away.",
    target: ["The star is 3.2×10^4 light-years away."],
  ),
  TestCase(
    name: "Sentences with multiple punctuation marks",
    input: "What?! Are you serious?! This is crazy...",
    target: ["What?!", "Are you serious?!", "This is crazy..."],
  ),
  TestCase(
    name: "Sentences with parentheses",
    input: "This is an example (which is quite useful). Do you agree?",
    target: ["This is an example (which is quite useful).", "Do you agree?"],
  ),
  TestCase(
    name: "Nested sentences with parentheses",
    input:
        "This is an example (This is pretty cool. Another sentence). Do you agree?",
    target: [
      "This is an example (This is pretty cool. Another sentence).",
      "Do you agree?",
    ],
  ),
  TestCase(
    name: "Sentences with newlines",
    input: "First sentence.\nSecond sentence.\nThird sentence.",
    target: ["First sentence.", "Second sentence.", "Third sentence."],
  ),
  TestCase(
    name: "Sentences with emojis",
    input: "I love pizza! 🍕 Do you? 😊",
    target: ["I love pizza!", "🍕 Do you?", "😊"],
  ),
  TestCase(
    name: "Sentences with unicode and non-Latin characters",
    input: "これはテストです。 次の文です。",
    target: ["これはテストです。", "次の文です。"],
  ),
  TestCase(
    name: "Sentences with bullet points",
    input: "- First point.\n- Second point.\n- Third point.",
    target: ["- First point.", "- Second point.", "- Third point."],
  ),
  TestCase(
    name: "Sentences with email addresses",
    input: "My email is test@example.com. Contact me!",
    target: ["My email is test@example.com.", "Contact me!"],
  ),
  TestCase(
    name: "Sentences with URLs",
    input: "Visit https://example.com. It's a great site!",
    target: ["Visit https://example.com.", "It's a great site!"],
  ),
  TestCase(
    name: "Sentences with URLs (subdomains)",
    input: "Visit https://test.example.com. It's a great site!",
    target: ["Visit https://test.example.com.", "It's a great site!"],
  ),
  TestCase(
    name: "Sentences with trailing spaces",
    input: "  This is a sentence.   Another one.  ",
    target: ["This is a sentence.", "Another one."],
  ),
  TestCase(
    name: "Sentences with contractions",
    input: "You can't be serious. It's too late.",
    target: ["You can't be serious.", "It's too late."],
  ),
  TestCase(
    name: "Sentences with title case and proper nouns",
    input: "Mr. Johnson went to New York. He loves it there.",
    target: ["Mr. Johnson went to New York.", "He loves it there."],
  ),
  TestCase(
    name: "Sentences with mixed cases",
    input: "i am happy. Are you?",
    target: ["i am happy.", "Are you?"],
  ),
  TestCase(
    name: "Sentences with missing punctuation",
    input: "This is a test without punctuation What should happen",
    target: ["This is a test without punctuation What should happen"],
  ),
  TestCase(
    name: "Sentences with mixed symbols",
    input: "Hello @John! How's it going? #excited",
    target: ["Hello @John!", "How's it going?", "#excited"],
  ),
  TestCase(
    name: "Sentences with math expressions",
    input: "The result is 3.14. It's an approximation of pi.",
    target: ["The result is 3.14.", "It's an approximation of pi."],
  ),
  TestCase(
    name: "Excessive punctuation",
    input: "Wait!!!! Are you sure??? This is insane!!! Right???",
    target: ["Wait!!!!", "Are you sure???", "This is insane!!!", "Right???"],
  ),
  TestCase(
    name: "Mixed languages in one line",
    input: "English sentence. 这是一句中文？ Another English sentence!",
    target: ["English sentence.", "这是一句中文？", "Another English sentence!"],
  ),
  TestCase(
    name: "Sequence of punctuation plus emoji",
    input: "What??! 🤯Wait??  Hello!",
    target: ["What??!", "🤯Wait??", "Hello!"],
  ),
  TestCase(
    name: "Nested parentheses and quotes",
    input: '(This is "very (strange)" text). Right?',
    target: ['(This is "very (strange)" text).', "Right?"],
  ),
  TestCase(
    name: "Sentence with ellipsis following a question mark",
    input: "Are you coming? ... I don't know.",
    target: ["Are you coming?", "... I don't know."],
  ),
  TestCase(
    name: "Sentence with mixed punctuation marks (colon, comma, question mark)",
    input: "What do you think: Is this the answer, or not?",
    target: ["What do you think: Is this the answer, or not?"],
  ),
  TestCase(
    name: "Sentence with parentheses and question mark",
    input: "Did you understand (after all)?",
    target: ["Did you understand (after all)?"],
  ),
  TestCase(
    name: "Sentence with repeated punctuation marks (exclamation)",
    input: "What a great day!!! This is amazing!!!",
    target: ["What a great day!!!", "This is amazing!!!"],
  ),
  TestCase(
    name: "Sentence with multiple short sentences and abbreviations",
    input: "Dr. Lee is busy. Mr. Brown is in a meeting.",
    target: ["Dr. Lee is busy.", "Mr. Brown is in a meeting."],
  ),
  TestCase(
    name: "Sentence with only emojis",
    input: "🍕🍔🍟🍦",
    target: ["🍕🍔🍟🍦"],
  ),
  TestCase(
    name: "Sentence with single quotes around a word",
    input: "The word 'apple' is red.",
    target: ["The word 'apple' is red."],
  ),
  TestCase(
    name: "Sentence with an email and a period",
    input: "My email is example@domain.com. Please contact me.",
    target: ["My email is example@domain.com.", "Please contact me."],
  ),
  TestCase(
    name: "Sentence with non-standard punctuation (pipe)",
    input: "This | is | a | test.",
    target: ["This | is | a | test."],
  ),
  TestCase(
    name: "Sentence with a URL and a period after it",
    input: "You can find more info at https://www.website.com. It's reliable.",
    target: [
      "You can find more info at https://www.website.com.",
      "It's reliable.",
    ],
  ),
  TestCase(
    name: "Sentence with multiple hashtags",
    input: "I love coding! #developer #javascript #testing",
    target: ["I love coding!", "#developer #javascript #testing"],
  ),
  TestCase(
    name: "Sentence with numbers and currency",
    input: "I have \$99.99 in my wallet. It's not enough.",
    target: ["I have \$99.99 in my wallet.", "It's not enough."],
  ),
  TestCase(
    name: "Sentence with mixed punctuation marks and parentheses",
    input: "Are you sure (really)? I don't think so!",
    target: ["Are you sure (really)?", "I don't think so!"],
  ),
  TestCase(
    name: "Sentence with parentheses and ellipses",
    input: "This is a test (and it's great)... seriously.",
    target: ["This is a test (and it's great)... seriously."],
  ),
  TestCase(
    name: "Sentence with an uncommon abbreviation",
    input: "The event is scheduled for noon PST. I'll be there.",
    target: ["The event is scheduled for noon PST.", "I'll be there."],
  ),
  TestCase(
    name: "Sentence with a phone number",
    input: "Call me at 555-1234. Or email me at example@domain.com.",
    target: ["Call me at 555-1234.", "Or email me at example@domain.com."],
  ),
  TestCase(
    name: "Sentence with nested punctuation (quotes inside quotes)",
    input: 'He said, "It\'s a test," and left.',
    target: ['He said, "It\'s a test," and left.'],
  ),
  TestCase(
    name: "Sentences only containing a quotation",
    input:
        "\"It's not like I'm using,\" Case heard someone say, as he shouldered his way through the crowd around the door of the Chat. \"It's like my body's developed this massive drug deficiency.\"\nThis is a test.",
    target: [
      "\"It's not like I'm using,\" Case heard someone say, as he shouldered his way through the crowd around the door of the Chat.",
      "\"It's like my body's developed this massive drug deficiency.\"",
      "This is a test.",
    ],
  ),
  TestCase(
    name: "Sentence with a URL containing a question mark",
    input: "Visit https://www.example.com?query=test. It's useful.",
    target: ["Visit https://www.example.com?query=test.", "It's useful."],
  ),
  TestCase(
    name: "Sentence with mixed punctuation and commas",
    input: "Hello, how are you? I'm fine, thanks.",
    target: ["Hello, how are you?", "I'm fine, thanks."],
  ),
  TestCase(
    name: "Sentence with a comma before 'and'",
    input: "I like ice cream, and I like cake.",
    target: ["I like ice cream, and I like cake."],
  ),
  TestCase(
    name: "Sentence with capital letters inside parentheses",
    input: "I went to the store (THE BIG ONE).",
    target: ["I went to the store (THE BIG ONE)."],
  ),
  TestCase(
    name: "Sentence with dates and periods",
    input: "The event is on January 1st. It's a new year.",
    target: ["The event is on January 1st.", "It's a new year."],
  ),
  TestCase(
    name: "Sentence with suffixes and periods",
    input:
        "Kokoro.js is powered by Transformers.js, a JavaScript library by Hugging Face.",
    target: [
      "Kokoro.js is powered by Transformers.js, a JavaScript library by Hugging Face.",
    ],
  ),
  TestCase(
    name: "Non-splitting after a period",
    input:
        "Pi is 3.14 i.e., a mathematical constant. J.R.R. Tolkien wrote The Lord of the Rings. Wait... what? The files are /path/to/file.txt, VIDEO.MP4 and image.jpg.",
    target: [
      "Pi is 3.14 i.e., a mathematical constant.",
      "J.R.R. Tolkien wrote The Lord of the Rings.",
      "Wait... what?",
      "The files are /path/to/file.txt, VIDEO.MP4 and image.jpg.",
    ],
  ),
  TestCase(
    name: "Long text with multiple sentences",
    input:
        "The sky above the port was the color of television, tuned to a dead channel.\n\"It's not like I'm using,\" Case heard someone say, as he shouldered his way through the crowd around the door of the Chat. \"It's like my body's developed this massive drug deficiency.\"\nIt was a Sprawl voice and a Sprawl joke. The Chatsubo was a bar for professional expatriates; you could drink there for a week and never hear two words in Japanese.\nThese were to have an enormous impact, not only because they were associated with Constantine, but also because, as in so many other areas, the decisions taken by Constantine (or in his name) were to have great significance for centuries to come. One of the main issues was the shape that Christian churches were to take, since there was not, apparently, a tradition of monumental church buildings when Constantine decided to help the Christian church build a series of truly spectacular structures. The main form that these churches took was that of the basilica, a multipurpose rectangular structure, based ultimately on the earlier Greek stoa, which could be found in most of the great cities of the empire. Christianity, unlike classical polytheism, needed a large interior space for the celebration of its religious services, and the basilica aptly filled that need. We naturally do not know the degree to which the emperor was involved in the design of new churches, but it is tempting to connect this with the secular basilica that Constantine completed in the Roman forum (the so-called Basilica of Maxentius) and the one he probably built in Trier, in connection with his residence in the city at a time when he was still caesar.",
    target: [
      "The sky above the port was the color of television, tuned to a dead channel.",
      "\"It's not like I'm using,\" Case heard someone say, as he shouldered his way through the crowd around the door of the Chat.",
      "\"It's like my body's developed this massive drug deficiency.\"",
      "It was a Sprawl voice and a Sprawl joke.",
      "The Chatsubo was a bar for professional expatriates; you could drink there for a week and never hear two words in Japanese.",
      "These were to have an enormous impact, not only because they were associated with Constantine, but also because, as in so many other areas, the decisions taken by Constantine (or in his name) were to have great significance for centuries to come.",
      "One of the main issues was the shape that Christian churches were to take, since there was not, apparently, a tradition of monumental church buildings when Constantine decided to help the Christian church build a series of truly spectacular structures.",
      "The main form that these churches took was that of the basilica, a multipurpose rectangular structure, based ultimately on the earlier Greek stoa, which could be found in most of the great cities of the empire.",
      "Christianity, unlike classical polytheism, needed a large interior space for the celebration of its religious services, and the basilica aptly filled that need.",
      "We naturally do not know the degree to which the emperor was involved in the design of new churches, but it is tempting to connect this with the secular basilica that Constantine completed in the Roman forum (the so-called Basilica of Maxentius) and the one he probably built in Trier, in connection with his residence in the city at a time when he was still caesar.",
    ],
  ),
];

// Tests adapted from https://github.com/textlint-rule/sentence-splitter/blob/master/test/sentence-splitter-test.ts
const List<TestCase> additionalTests = [
  TestCase(
    name: "Basic sentence splitting (single)",
    input: "text",
    target: ["text"],
  ),
  TestCase(
    name: "Should not split number",
    input: "Temperature is 40.2 degrees.",
    target: ["Temperature is 40.2 degrees."],
  ),
  TestCase(
    name: "Should not split in pair string with same mark",
    input: 'I hear "I\'m back to home." from radio.',
    target: ['I hear "I\'m back to home." from radio.'],
  ),
  TestCase(
    name: "Should not split in pair string",
    input: "彼は「ココにある。」と言った。",
    target: ["彼は「ココにある。」と言った。"],
  ),
  TestCase(
    name: "Should split by first line break",
    input: "text",
    target: ["text"],
  ),
  TestCase(
    name: "Should split by last line break",
    input: "text\n",
    target: ["text"],
  ),
  TestCase(
    name: "Should split by double line break",
    input: "text\n\ntext",
    target: ["text", "text"],
  ),
  TestCase(
    name: "Should split by 。",
    input: "text。。text",
    target: ["text。。", "text"],
  ),
  TestCase(
    name: "Should split by 。 and linebreak",
    input: "text。\ntext",
    target: ["text。", "text"],
  ),
  TestCase(
    name: "Should split by . and whitespace",
    input: "1st text. 2nd text",
    target: ["1st text.", "2nd text"],
  ),
  TestCase(
    name: "Should split by multiple whitespaces",
    input: "1st text.   2nd text",
    target: ["1st text.", "2nd text"],
  ),
  TestCase(
    name: "Should support start and end whitespace",
    input: " text. ",
    target: ["text."],
  ),
  TestCase(
    name: "Should split by text, whitespaces, and newline",
    input: "1st text. \n 2nd text",
    target: ["1st text.", "2nd text"],
  ),
  TestCase(
    name: "Should split by !?",
    input: "text!?text",
    target: ["text!?", "text"],
  ),
  TestCase(name: "Should split by last 。", input: "text。", target: ["text。"]),
  TestCase(
    name: "Should not split numbered list",
    input: "1. 1st text.\n2. 2nd text.\n10. 10th text.",
    target: ["1. 1st text.", "2. 2nd text.", "10. 10th text."],
  ),
];

// Tests adapted from https://github.com/wikimedia/sentencex-js/blob/main/test/en.test.js
const List<TestCase> wikimediaTests = [
  TestCase(
    name: "Dr. title should not split",
    input: "This is Dr. Watson",
    target: ["This is Dr. Watson"],
  ),
  TestCase(
    name: "Basic sentence split",
    input: "Roses Are Red. Violets Are Blue",
    target: ["Roses Are Red.", "Violets Are Blue"],
  ),
  TestCase(
    name: "Exclamation and question split",
    input: "Hello! How are you?",
    target: ["Hello!", "How are you?"],
  ),
  TestCase(
    name: "Simple period split",
    input: "This is a test.",
    target: ["This is a test."],
  ),
  TestCase(
    name: "Mr. title should not split",
    input: "Mr. Smith went to Washington.",
    target: ["Mr. Smith went to Washington."],
  ),
  TestCase(
    name: "Words ending in title-like suffixes should split",
    input: "He hit the drums. Then he hit the cymbals.",
    target: ["He hit the drums.", "Then he hit the cymbals."],
  ),
  TestCase(
    name: "Surprise sentence should not split",
    input: "What a suprise?!",
    target: ["What a suprise?!"],
  ),
  TestCase(
    name: "Ellipsis should not split",
    input: "That's all folks...",
    target: ["That's all folks..."],
  ),
  TestCase(
    name: "Single line break should split",
    input: "First line\nSecond line",
    target: ["First line", "Second line"],
  ),
  TestCase(
    name: "Double line break should split",
    input: "First line\nSecond line\n\nThird line",
    target: ["First line", "Second line", "Third line"],
  ),
  TestCase(
    name: "Abbreviations should not split",
    input: "This is UK. Not US",
    target: ["This is UK.", "Not US"],
  ),
  TestCase(
    name: "Dollar amount should not split",
    input: "This balloon costs \$1.20",
    target: ["This balloon costs \$1.20"],
  ),
  TestCase(
    name: "Basic multiple sentence split",
    input: "Hello World. My name is Jonas.",
    target: ["Hello World.", "My name is Jonas."],
  ),
  TestCase(
    name: "Basic question and sentence split",
    input: "What is your name? My name is Jonas.",
    target: ["What is your name?", "My name is Jonas."],
  ),
  TestCase(
    name: "Exclamation and period split",
    input: "There it is! I found it.",
    target: ["There it is!", "I found it."],
  ),
  TestCase(
    name: "Middle initial should not split",
    input: "My name is Jonas E. Smith.",
    target: ["My name is Jonas E. Smith."],
  ),
  TestCase(
    name: "Page reference should not split",
    input: "Please turn to p. 55.",
    target: ["Please turn to p. 55."],
  ),
  TestCase(
    name: "Co. abbreviation should not split",
    input: "Were Jane and co. at the party?",
    target: ["Were Jane and co. at the party?"],
  ),
  TestCase(
    name: "Business name should not split",
    input: "They closed the deal with Pitt, Briggs & Co. at noon.",
    target: ["They closed the deal with Pitt, Briggs & Co. at noon."],
  ),
  TestCase(
    name: "Mount abbreviation should not split",
    input: "I can see Mt. Fuji from here.",
    target: ["I can see Mt. Fuji from here."],
  ),
  TestCase(
    name: "Saint abbreviation should not split",
    input: "St. Michael's Church is on 5th st. near the light.",
    target: ["St. Michael's Church is on 5th st. near the light."],
  ),
  TestCase(
    name: "JFK Jr. should not split",
    input: "That is JFK Jr.'s book.",
    target: ["That is JFK Jr.'s book."],
  ),
  TestCase(
    name: "Country abbreviation should not split",
    input: "I visited the U.S.A. last year.",
    target: ["I visited the U.S.A. last year."],
  ),
  TestCase(
    name: "Dollar amount with period split",
    input: "She has \$100.00. It is in her bag.",
    target: ["She has \$100.00.", "It is in her bag."],
  ),
  TestCase(
    name: "Email should not split",
    input: "Her email is Jane.Doe@example.com. I sent her an email.",
    target: ["Her email is Jane.Doe@example.com.", "I sent her an email."],
  ),
  TestCase(
    name: "URL should not split",
    input:
        "The site is, https://www.example.50.com/new-site/awesome_content.html. Please check it out.",
    target: [
      "The site is, https://www.example.50.com/new-site/awesome_content.html.",
      "Please check it out.",
    ],
  ),
  TestCase(
    name: "Multiple exclamations should split",
    input: "Hello!! Long time no see.",
    target: ["Hello!!", "Long time no see."],
  ),
  TestCase(
    name: "Mixed punctuation should split",
    input: "Hello?! Is that you?",
    target: ["Hello?!", "Is that you?"],
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
      "I went to the store.",
      "I bought an apple for \$1.99.",
      "It was a good deal.",
    ],
  ),
  StreamedTestCase(
    name: "URL with query parameters",
    input: ["Visit https://www", ".example.", "com", "?query=test."],
    target: ["Visit https://www.example.com?query=test."],
  ),
];
