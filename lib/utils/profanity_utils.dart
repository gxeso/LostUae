// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:profanity_filter/profanity_filter.dart';

class ProfanityUtils {
  static final ProfanityFilter _filter = ProfanityFilter();

  /// Checks if text contains profanity
  static bool hasProfanity(String text) {
    return _filter.hasProfanity(text);
  }

  /// Checks if text contains URLs/links
  static bool hasLinks(String text) {
    // Regular expression to detect URLs
    final urlPattern = RegExp(
      r'(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(text);
  }

  /// Validates text - returns null if valid, error message if invalid
  static String? validateText(String text) {
    if (text.trim().isEmpty) {
      return 'Description cannot be empty';
    }
    if (text.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (hasProfanity(text)) {
      return 'Description contains inappropriate language';
    }
    if (hasLinks(text)) {
      return 'Links are not allowed';
    }
    return null;
  }

  /// Gets the profanity-free version of text (censored)
  static String getCleanText(String text) {
    return _filter.censor(text);
  }
}
