class Validators {
  static bool isPostcode(String s) => RegExp(r"^[A-Z]{1,2}[0-9][0-9A-Z]? ?[0-9][A-Z]{2}$", caseSensitive: false).hasMatch(s.trim());
  static bool isThreeWords(String s) => RegExp(r"^[a-zA-Z]+\.[a-zA-Z]+\.[a-zA-Z]+$").hasMatch(s.trim());
}