import '../managers/match_manager.dart';

class ScoreManager {
  int _score = 0;
  int _comboCount = 0;
  int _movesUsed = 0;
  final Map<String, int> _lettersCleared = {};
  int _itemsDropped = 0;

  int get score => _score;
  int get comboCount => _comboCount;
  int get movesUsed => _movesUsed;
  int get itemsDropped => _itemsDropped;
  Map<String, int> get lettersCleared => Map.unmodifiable(_lettersCleared);

  double get comboMultiplier => _comboCount > 0 ? _comboCount.toDouble() : 1.0;

  void reset() {
    _score = 0;
    _comboCount = 0;
    _movesUsed = 0;
    _lettersCleared.clear();
    _itemsDropped = 0;
  }

  void incrementMoves() {
    _movesUsed++;
  }

  void startChain() {
    _comboCount = 0;
  }

  void addChainStep() {
    _comboCount++;
  }

  int addMatchScore(List<MatchResult> matches) {
    int totalForStep = 0;
    for (final match in matches) {
      final baseScore = match.score;
      final multiplied = (baseScore * comboMultiplier).round();
      totalForStep += multiplied;
    }
    _score += totalForStep;
    return totalForStep;
  }

  void addBonusScore(int bonus) {
    _score += bonus;
  }

  void recordLetterCleared(String letter, int count) {
    _lettersCleared[letter] = (_lettersCleared[letter] ?? 0) + count;
  }

  void recordItemDropped(int count) {
    _itemsDropped += count;
  }

  int calculateRemainingMovesBonus(int movesLeft) {
    final bonus = movesLeft * 50;
    _score += bonus;
    return bonus;
  }

  int getLetterClearedCount(String letter) =>
      _lettersCleared[letter] ?? 0;
}
