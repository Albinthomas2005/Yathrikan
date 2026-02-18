import 'dart:math';

class StringUtils {
  /// Calculates the Levenshtein distance between two strings.
  /// Lower distance means strings are more similar.
  static int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i].toLowerCase() == t[j].toLowerCase()) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }

  /// Finds the closest match for [query] in [candidates].
  /// Returns the matched string if the distance is within [threshold].
  /// Otherwise, returns null.
  static String? findClosestMatch(String query, List<String> candidates, {int threshold = 3}) {
    if (query.isEmpty) return null;
    if (candidates.isEmpty) return null;

    String? bestMatch;
    int bestDistance = 999;

    for (var candidate in candidates) {
      int distance = levenshtein(query, candidate);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = candidate;
      }
    }

    if (bestDistance <= threshold) {
      return bestMatch;
    }

    return null;
  }

  static String formatTime(DateTime dt) {
    int h = dt.hour;
    String ampm = h >= 12 ? 'PM' : 'AM';
    int dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return "$dh:${dt.minute.toString().padLeft(2, '0')} $ampm";
  }
}
