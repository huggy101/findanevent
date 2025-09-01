class Validators {
  static final RegExp _postcodeRegex =
      RegExp(r'^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$', caseSensitive: false);

  static final RegExp _threeWordsRegex =
      RegExp(r'^[a-z]+\.[a-z]+\.[a-z]+$', caseSensitive: false);

  // ✅ Plus Code regex: matches global (e.g., "9C4WQ9MQ+77")
  // and short forms (e.g., "CWC8+R9 London")
  static final RegExp _plusCodeRegex =
      RegExp(r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3}(?:\s.+)?$',
          caseSensitive: false);

  static bool isPostcode(String input) => _postcodeRegex.hasMatch(input.trim());

  static bool isThreeWords(String input) =>
      _threeWordsRegex.hasMatch(input.trim());

  static bool isPlusCode(String input) =>
      _plusCodeRegex.hasMatch(input.trim());
}
