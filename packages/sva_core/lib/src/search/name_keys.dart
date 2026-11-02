/// Search and sort keys for place and route names, the way Norwegian
/// climbers expect them to work. The server computes the same keys
/// (`shared/test_cases/name_keys.json`), so results match offline and
/// online.
library;

/// Letters folded before anything else: Swedish, Danish and German
/// spellings of æ and ø, and accents Norwegian names do not use.
const _fold = {
  'ä': 'æ', 'ö': 'ø', 'ǿ': 'ø', //
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ā': 'a', 'ą': 'a', //
  'ç': 'c', 'ć': 'c', 'č': 'c', //
  'ď': 'd', 'đ': 'd', 'ð': 'd', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e', //
  'ě': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', //
  'ł': 'l', 'ñ': 'n', 'ń': 'n', 'ň': 'n', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ō': 'o', 'ő': 'o', //
  'ř': 'r', 'ś': 's', 'š': 's', 'ș': 's', 'ť': 't', 'ț': 't', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u', 'ű': 'u', //
  'ý': 'y', 'ÿ': 'y', 'ź': 'z', 'ż': 'z', 'ž': 'z', //
  'ß': 'ss', 'þ': 'th', 'œ': 'oe',
};

/// Whether every code unit of [chars] is a letter or digit Sva keeps.
bool _isLetterOrDigit(String chars) =>
    chars.isNotEmpty && chars.codeUnits.every(_keeps);

bool _keeps(int c) =>
    (c >= 0x61 && c <= 0x7a) || // a-z
    (c >= 0x30 && c <= 0x39) || // 0-9
    c == 0xe6 || // æ
    c == 0xf8 || // ø
    c == 0xe5; // å

/// The key a name is searched by: lower case, with æ, ø and å kept as their
/// own letters. "Aa" counts as "å" (the old spelling, as in "Aaland"), "ä"
/// and "ö" count as "æ" and "ø", other accents are dropped, and anything
/// that is not a letter or digit becomes a single space.
String searchKey(String name) {
  final out = StringBuffer();
  var space = false;
  for (final rune in name.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final folded = _fold[char] ?? char;
    if (_isLetterOrDigit(folded)) {
      if (space && out.isNotEmpty) out.write(' ');
      space = false;
      out.write(folded);
    } else {
      space = true;
    }
  }
  return out.toString().replaceAll('aa', 'å');
}

/// [searchKey] written without æ, ø and å (as "ae", "o" and "a"), so a
/// search typed on a keyboard without them, such as "floyen", still finds
/// "Fløyen".
String asciiKey(String name) =>
    searchKey(name)
        .replaceAll('æ', 'ae')
        .replaceAll('ø', 'o')
        .replaceAll('å', 'a');

/// Orders names as a Norwegian reader expects: case and accents ignored,
/// and æ, ø, å last, after z. Names with the same key keep a stable order.
/// For long lists, sort by [nameSortKey] computed once per name instead.
int compareNames(String a, String b) {
  final byKey = nameSortKey(a).compareTo(nameSortKey(b));
  return byKey != 0 ? byKey : a.compareTo(b);
}

/// A key whose plain string order is the order of [compareNames]: æ, ø
/// and å become '{', '|' and '}', which follow 'z' in ASCII.
String nameSortKey(String name) =>
    searchKey(name)
        .replaceAll('æ', '{')
        .replaceAll('ø', '|')
        .replaceAll('å', '}');
