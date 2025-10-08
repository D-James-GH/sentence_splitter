Dart library for splitting strings into sentences via a stream or iterator. This library is based on the sentence splitter used in the [kokoro tts framework.](https://github.com/hexgrad/kokoro)

View on pub: https://pub.dev/packages/sentence_splitter

## Usage
```dart
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
```
## Using a lazy iterator to get the text and range
The range of each sentence is available when using the iterator to split into sentences. 

> [!NOTE]  
> The iterator is lazy, meaning the next sentence is only calcualted when moveNext is called. However, it is not a effecient length iterator, this means calls to last, length etc.. will calculate the full split.


```dart
final text =
    'This is a sentence. And another one (and a nested.)! Is this the third? Yes, it is.';
for (final sentence in text.splitSentences()) {
    /// get the start and end index of the sentence, relative to the whole text
    print(sentence.range);
    print(sentence.text);
}
```

## Using a stream transformer
Splitting a sentence by a stream allows chunks to be added when they become available. 
The stream will always hold on to the last chunk in order to make sure the sentence is complete before splitting.
```dart

/// Add text in chunks, the stream will emit the sentences as they are complete
final controller = StreamController<String>();
// asString() pulls the text out of the sentence and ignores the range.
controller.stream.splitSentences().asString().forEach((sentence) {
    // prints
    // This is a full sentence.
    // This is another full sentence.
    print(sentence);
});

controller
    ..add("This is ")
    ..add("a full sentence.")
    ..add(" This is ")
    ..add("another full sentence.")
    ..close();

```