import 'tile_type.dart';

enum ObjectiveType {
  score,
  clearLetters,
  dropItems,
  timed,
}

class LevelObjective {
  final ObjectiveType type;
  final int targetScore;
  final Map<ThaanaLetter, int> letterTargets;
  final int dropItemCount;
  final int moveLimit;
  final int timeLimit;

  const LevelObjective({
    required this.type,
    this.targetScore = 0,
    this.letterTargets = const {},
    this.dropItemCount = 0,
    this.moveLimit = 25,
    this.timeLimit = 0,
  });

  factory LevelObjective.score({
    required int target,
    required int moves,
  }) =>
      LevelObjective(
        type: ObjectiveType.score,
        targetScore: target,
        moveLimit: moves,
      );

  factory LevelObjective.clearLetters({
    required Map<ThaanaLetter, int> targets,
    required int moves,
  }) =>
      LevelObjective(
        type: ObjectiveType.clearLetters,
        letterTargets: targets,
        moveLimit: moves,
      );

  factory LevelObjective.dropItems({
    required int count,
    required int moves,
  }) =>
      LevelObjective(
        type: ObjectiveType.dropItems,
        dropItemCount: count,
        moveLimit: moves,
      );

  factory LevelObjective.timed({
    required int target,
    required int seconds,
  }) =>
      LevelObjective(
        type: ObjectiveType.timed,
        targetScore: target,
        timeLimit: seconds,
      );

  String get description {
    switch (type) {
      case ObjectiveType.score:
        return 'Score $targetScore points';
      case ObjectiveType.clearLetters:
        final parts = letterTargets.entries
            .map((e) => '${e.value}x ${e.key.letter}')
            .join(', ');
        return 'Clear $parts';
      case ObjectiveType.dropItems:
        return 'Drop $dropItemCount items';
      case ObjectiveType.timed:
        return 'Score $targetScore in ${timeLimit}s';
    }
  }

  String get descriptionDv {
    switch (type) {
      case ObjectiveType.score:
        return '$targetScore ޕޮއިންޓް ހޯދާ';
      case ObjectiveType.clearLetters:
        final parts = letterTargets.entries
            .map((e) => '${e.key.letter} ${e.value}')
            .join('، ');
        return '$parts ފޮހެލާ';
      case ObjectiveType.dropItems:
        return '$dropItemCount ތަކެތި ތިރިއަށް ވައްޓާލާ';
      case ObjectiveType.timed:
        return '$timeLimitސ ތެރޭ $targetScore ޕޮއިންޓް';
    }
  }
}
