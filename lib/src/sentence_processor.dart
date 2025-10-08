/*
 * Portions of this file are derived from hexgrad/kokoro
 * Original source: https://github.com/hexgrad/kokoro/blob/5229a254b7b9573c053d6dc91b133d80ff72a458/kokoro.js/src/splitter.js
 * 
 * Licensed under the Apache License, Version 2.0
 * Original copyright holder: hexgrad/kokoro Contributors
 * 
 */
import 'dart:math' as math;

/// Gets the next sentence. If the sentence is incomplete it returns the remaining text.
({String sentence, bool isComplete, int boundaryEnd}) findFirstSentence(
  String text,
) {
  final buffer = text;
  int i = 0;
  final len = buffer.length;
  List<String> stack = [];

  // Helper to scan from the current index over trailing terminators and punctuation.
  ({int end, int nextNonSpace}) scanBoundary(int idx) {
    int end = idx;
    // Consume contiguous sentence terminators (excluding newlines).
    while (end + 1 < len && isSentenceTerminator(buffer[end + 1], false)) {
      ++end;
    }
    // Consume trailing characters (e.g., closing quotes/brackets).
    while (end + 1 < len && isTrailingChar(buffer[end + 1])) {
      ++end;
    }
    int nextNonSpace = end + 1;
    while (nextNonSpace < len &&
        _whitespaceRegex.hasMatch(buffer[nextNonSpace])) {
      ++nextNonSpace;
    }
    return (end: end, nextNonSpace: nextNonSpace);
  }

  while (i < len) {
    final c = buffer[i];
    updateStack(c, stack, i, buffer);

    // Only consider splitting if we're not inside any nested structure.
    if (stack.isEmpty && isSentenceTerminator(c)) {
      final currentSegment = buffer.substring(0, i);
      // Skip splitting for likely numbered lists (e.g., "1." or "\n2.").
      if (_numberedListRegex.hasMatch(currentSegment)) {
        ++i;
        continue;
      }

      final boundary = scanBoundary(i);
      final boundaryEnd = boundary.end;
      final nextNonSpace = boundary.nextNonSpace;

      // If the terminator is not a newline and there's no extra whitespace,
      // we might be in the middle of a token (e.g., "$9.99"), so skip splitting.
      if (i == nextNonSpace - 1 && c != '\n') {
        ++i;
        continue;
      }

      // Wait for more text if there's no non-whitespace character yet.
      if (nextNonSpace == len) {
        break;
      }

      // Determine the token immediately preceding the terminator.
      int tokenStart = i - 1;
      while (tokenStart >= 0 &&
          _nonWhitespaceRegex.hasMatch(buffer[tokenStart])) {
        tokenStart--;
      }
      tokenStart = math.max(0, tokenStart + 1);
      final token = getTokenFromBuffer(buffer, tokenStart);
      if (token.isEmpty) {
        ++i;
        continue;
      }

      // --- URL/email protection ---
      // If the token appears to be a URL or email (contains "://" or "@")
      // and does not already end with a terminator, skip splitting.
      if ((_urlRegex.hasMatch(token) || token.contains('@')) &&
          !isSentenceTerminator(
            token.isNotEmpty ? token[token.length - 1] : '',
          )) {
        i = tokenStart + token.length;
        continue;
      }

      // --- Abbreviation protection ---
      if (isAbbreviation(token)) {
        ++i;
        continue;
      }

      // --- Middle initials heuristic ---
      // If the token is a series of single-letter initials (each ending in a period)
      // and is followed by a capitalized word, assume it's part of a name.
      if (_initialsRegex.hasMatch(token) &&
          nextNonSpace < len &&
          _uppercaseRegex.hasMatch(buffer[nextNonSpace])) {
        ++i;
        continue;
      }

      // --- Lookahead heuristic ---
      // If the terminator is a period and the next non–whitespace character is lowercase,
      // assume it is not the end of a sentence.
      if (c == '.' &&
          nextNonSpace < len &&
          _lowercaseRegex.hasMatch(buffer[nextNonSpace])) {
        ++i;
        continue;
      }

      // Special case: ellipsis that stands alone should be merged with the following sentence.
      final sentence = buffer.substring(0, boundaryEnd + 1).trim();
      if (sentence == '...' || sentence == '…') {
        ++i;
        continue;
      }

      // Accept the sentence boundary.
      if (sentence.isNotEmpty) {
        return (sentence: sentence, isComplete: true, boundaryEnd: boundaryEnd);
      }
    }
    ++i;
  }

  return (sentence: text, isComplete: false, boundaryEnd: len - 1);
}

final _whitespaceRegex = RegExp(r'\s');
final _possessiveRegex = RegExp(r"[\'']s$", caseSensitive: false);
final _trailingPeriodRegex = RegExp(r'\.+$');
final _letterRegex = RegExp(r'[A-Za-z]');
final _nonWhitespaceRegex = RegExp(r'\S');
final _urlRegex = RegExp(r'https?[,:]//');
final _numberedListRegex = RegExp(r'(^|\n)\d+$');
final _initialsRegex = RegExp(r'^([A-Za-z]\.)+$');
final _uppercaseRegex = RegExp(r'[A-Z]');
final _lowercaseRegex = RegExp(r'[a-z]');

/// Returns true if the character is considered a sentence terminator.
/// This includes ASCII (".", "!", "?") and common Unicode terminators.
/// NOTE: We also include newlines here, as this is favourable for text-to-speech systems.
bool isSentenceTerminator(String c, [bool includeNewlines = true]) {
  return '.!?…。？！'.contains(c) || (includeNewlines && c == '\n');
}

/// Returns true if the character should be attached to the sentence terminator,
/// such as closing quotes or brackets.
bool isTrailingChar(String c) {
  return '"\')}]」』'.contains(c);
}

/// Extracts a token (a contiguous sequence of non–whitespace characters)
/// from the buffer starting at the given index.
String getTokenFromBuffer(String buffer, int start) {
  int end = start;
  while (end < buffer.length && !_whitespaceRegex.hasMatch(buffer[end])) {
    ++end;
  }
  return buffer.substring(start, end);
}

// List of common abbreviations. Note that strings with single letters joined by periods
// (e.g., "i.e", "e.g", "u.s.a", "u.s") are handled separately.
const Set<String> _abbreviations = {
  'mr',
  'mrs',
  'ms',
  'dr',
  'prof',
  'sr',
  'jr',
  'sgt',
  'col',
  'gen',
  'rep',
  'sen',
  'gov',
  'lt',
  'maj',
  'capt',
  'st',
  'mt',
  'etc',
  'co',
  'inc',
  'ltd',
  'dept',
  'vs',
  'p',
  'pg',
  'jan',
  'feb',
  'mar',
  'apr',
  'jun',
  'jul',
  'aug',
  'sep',
  'sept',
  'oct',
  'nov',
  'dec',
  'sun',
  'mon',
  'tu',
  'tue',
  'tues',
  'wed',
  'th',
  'thu',
  'thur',
  'thurs',
  'fri',
  'sat',
};

/// Determines if the given token (or series of initials) is a known abbreviation.
bool isAbbreviation(String token) {
  // Remove possessive endings and trailing periods.
  token = token
      .replaceAll(_possessiveRegex, '')
      .replaceAll(_trailingPeriodRegex, '');
  return _abbreviations.contains(token.toLowerCase());
}

// Map of closing punctuation to their corresponding opening punctuation.
const Map<String, String> _matching = {
  ")": "(",
  "]": "[",
  "}": "{",
  "》": "《",
  "〉": "〈",
  "›": "‹",
  "»": "«",
  "」": "「",
  "』": "『",
  "〕": "〔",
  "】": "【",
};

// Set of opening punctuation characters.
final Set<String> _opening = _matching.values.toSet();

/// Updates the nesting stack to track quotes and paired punctuation.
/// This supports both standard (", ', (), [], {}) and Japanese quotes (「」「』『』).
/// (An apostrophe between letters is ignored so that contractions remain intact.)
void updateStack(String c, List<String> stack, int i, String buffer) {
  // Handle standard quotes.
  if (c == '"' || c == "'") {
    // Ignore an apostrophe if it's between letters (e.g., in contractions).
    if (c == "'" &&
        i > 0 &&
        i < buffer.length - 1 &&
        _letterRegex.hasMatch(buffer[i - 1]) &&
        _letterRegex.hasMatch(buffer[i + 1])) {
      return;
    }
    if (stack.isNotEmpty && stack.last == c) {
      stack.removeLast();
    } else {
      stack.add(c);
    }
    return;
  }

  // Handle opening punctuation.
  if (_opening.contains(c)) {
    stack.add(c);
    return;
  }

  // Handle closing punctuation.
  final expectedOpening = _matching[c];
  if (expectedOpening != null &&
      stack.isNotEmpty &&
      stack.last == expectedOpening) {
    stack.removeLast();
  }
}
