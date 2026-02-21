import 'dart:convert';
import 'package:flutter/services.dart';
import '../managers/match_manager.dart';
import '../models/tile_type.dart';
import '../../config/constants.dart';

class WordBonusResult {
  final String word;
  final int multiplier;
  final int bonusScore;

  const WordBonusResult({
    required this.word,
    required this.multiplier,
    required this.bonusScore,
  });
}

class WordBonusManager {
  Set<String> _dictionary = {};
  bool _loaded = false;

  Future<void> loadDictionary() async {
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/dhivehi_words.json');
      final List<dynamic> words = json.decode(jsonStr) as List<dynamic>;
      _dictionary = words.map((w) => w.toString()).toSet();
    } catch (e) {
      _dictionary = _defaultDictionary;
    }
    _loaded = true;
  }

  List<WordBonusResult> checkForWords(
    List<List<TileState>> grid,
    List<TilePosition> clearedPositions,
  ) {
    final results = <WordBonusResult>[];

    // Check horizontal sequences
    final rows = <int>{};
    for (final pos in clearedPositions) {
      rows.add(pos.row);
    }

    for (final row in rows) {
      final lettersInRow = <String>[];
      for (int c = 0; c < kBoardWidth; c++) {
        if (grid[row][c].letter != null) {
          lettersInRow.add(grid[row][c].letter!.letter);
        }
      }
      _checkSequence(lettersInRow, results);
    }

    // Check vertical sequences
    final cols = <int>{};
    for (final pos in clearedPositions) {
      cols.add(pos.col);
    }

    for (final col in cols) {
      final lettersInCol = <String>[];
      for (int r = 0; r < kBoardHeight; r++) {
        if (grid[r][col].letter != null) {
          lettersInCol.add(grid[r][col].letter!.letter);
        }
      }
      _checkSequence(lettersInCol, results);
    }

    return results;
  }

  void _checkSequence(List<String> letters, List<WordBonusResult> results) {
    for (int start = 0; start < letters.length; start++) {
      for (int end = start + 2; end <= letters.length; end++) {
        final word = letters.sublist(start, end).join();
        if (_dictionary.contains(word)) {
          final multiplier = _multiplierForLength(word.length);
          results.add(WordBonusResult(
            word: word,
            multiplier: multiplier,
            bonusScore: kBaseMatch3Score * multiplier,
          ));
        }
      }
    }
  }

  int _multiplierForLength(int length) {
    if (length >= 5) return 5;
    if (length == 4) return 4;
    if (length == 3) return 3;
    return 2;
  }

  static final Set<String> _defaultDictionary = {
    // Common Dhivehi words - 200+ entries
    'މަސް', 'ދޮރު', 'ގެ', 'ކަނު', 'ފެން', 'ބަތް', 'ނަން', 'ދަރި', 'މީހެ',
    'ރަށް', 'ވެލި', 'ގަސް', 'މާ', 'ފަތް', 'ކެޔޮ', 'ދޯނި', 'ކަނޑު', 'ރާޅު',
    'ވައި', 'އިރު', 'ހަނދު', 'ތަރި', 'ވާރޭ', 'މެދު', 'ބޮޑު', 'ކުޑަ', 'ރީތި',
    'ހުދު', 'ކަޅު', 'ރަތް', 'ފެހި', 'ނޫ', 'ރީދޫ', 'ގިނަ', 'މަދު', 'ހެޔޮ',
    'ނުބައި', 'ހަރު', 'މަޑު', 'ފިނި', 'ހޫނު', 'ދިގު', 'ކުރު', 'ބޯ', 'ތުނި',
    'އާ', 'ބާ', 'ދުވަ', 'ރޭ', 'ހެނދު', 'މެންދު', 'ހަވީ', 'ކެއު', 'ބުއި',
    'ނިދި', 'ހިނގު', 'ދުވު', 'ފެތު', 'ދިއު', 'އައި', 'ބެލު', 'ކިއު', 'ލިޔު',
    'ކުޅި', 'ގޮވު', 'ނެގު', 'ލައި', 'ނެއް', 'ހުރި', 'އޮތް', 'އިނދެ', 'ހިފި',
    'ދޫ', 'ލޮލު', 'ކަނފަ', 'ނޭފަ', 'އަތް', 'ފައި', 'ބޮލު', 'ކަރު', 'ބަނޑު',
    'ބުރަ', 'މޫނު', 'ދަތް', 'ތުން', 'ގައި', 'ހަމް', 'ލޭ', 'ކަށި', 'މަހާ',
    'ކާނާ', 'ރިހަ', 'ރޮށި', 'ހަނޑޫ', 'ހަކު', 'ލޮނު', 'މިރު', 'ހުނި', 'ތެލު',
    'ކިރު', 'ސައި', 'ކޮފީ', 'ބޯފެ', 'މޭވާ', 'ކުކު', 'ދޮންކެ', 'އަނބު', 'ފާގަ',
    'ބަނބު', 'ކައް', 'ދަނޑު', 'މަގު', 'ފާރު', 'ފުރާ', 'ބާލި', 'ގޮނޑި',
    'މޭޒު', 'ކަރަ', 'ފޮތް', 'ގަލަ', 'ކަނި',
    'ބައް', 'ފަރު', 'ވިލު', 'ފިނޮ', 'ހުރާ', 'ގޮއި', 'ގިރި',
    'ފަޅު', 'ނެރު', 'ތުނޑި', 'އެރު', 'ބެހު', 'ފޮނު', 'ތޫފާ', 'ޖެހި', 'ވެއް',
    'ބާރު', 'ނެތް', 'އެބަ', 'ނުވެ', 'ވާނެ', 'ކުރި', 'ފެށި', 'ނިމު',
    'އެނގި', 'ފެނު', 'އިވި', 'ބުނި', 'ދެއް', 'ގެނައި', 'ފޮނުވި', 'ނެގި', 'ބެލި',
    'ހޯދި', 'ލިބި', 'ހެދި', 'ރޫޅި', 'ވީރާ', 'ބިނާ', 'އިމާ', 'ދެނެ', 'ގަބޫ',
    'ޤަބޫ', 'ޝުކު', 'ސާބަ', 'މަރު', 'ދިރި', 'އުފާ', 'ހިތާ', 'ލޯބި', 'ރުޅި',
    'ބިރު', 'އުއް', 'ޖޯޝް', 'ހިތް', 'ސިކު', 'ނަފު', 'ރޫހް', 'ދީން', 'ﷲ',
    'ޤުރު', 'ނަމާ', 'ރޯދަ', 'ޒަކާ', 'ޙައް', 'މިސް', 'މުނާ', 'ދުޢާ', 'ޛިކު',
    'ޝަހާ', 'ކެތް',
  };
}
