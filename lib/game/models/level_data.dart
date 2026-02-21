import 'tile_type.dart';
import 'objective.dart';
import '../../config/constants.dart';

class AtollInfo {
  final String id;
  final String nameEn;
  final String nameDv;
  final int startLevel;
  final int endLevel;

  const AtollInfo({
    required this.id,
    required this.nameEn,
    required this.nameDv,
    required this.startLevel,
    required this.endLevel,
  });
}

const List<AtollInfo> atolls = [
  AtollInfo(id: 'haa_alifu', nameEn: 'Haa Alifu', nameDv: 'ހއ', startLevel: 1, endLevel: 20),
  AtollInfo(id: 'haa_dhaalu', nameEn: 'Haa Dhaalu', nameDv: 'ހދ', startLevel: 21, endLevel: 40),
  AtollInfo(id: 'shaviyani', nameEn: 'Shaviyani', nameDv: 'ށ', startLevel: 41, endLevel: 60),
  AtollInfo(id: 'noonu', nameEn: 'Noonu', nameDv: 'ނ', startLevel: 61, endLevel: 80),
  AtollInfo(id: 'raa', nameEn: 'Raa', nameDv: 'ރ', startLevel: 81, endLevel: 100),
  AtollInfo(id: 'baa', nameEn: 'Baa', nameDv: 'ބ', startLevel: 101, endLevel: 120),
  AtollInfo(id: 'lhaviyani', nameEn: 'Lhaviyani', nameDv: 'ޅ', startLevel: 121, endLevel: 140),
  AtollInfo(id: 'kaafu', nameEn: 'Kaafu', nameDv: 'ކ', startLevel: 141, endLevel: 160),
];

class LevelData {
  final int levelNumber;
  final LevelObjective objective;
  final List<ThaanaLetter> availableLetters;
  final int star1Score;
  final int star2Score;
  final int star3Score;
  final List<BlockerPosition> blockers;
  final List<DropItemPosition> dropItems;

  const LevelData({
    required this.levelNumber,
    required this.objective,
    required this.availableLetters,
    required this.star1Score,
    this.star2Score = 0,
    this.star3Score = 0,
    this.blockers = const [],
    this.dropItems = const [],
  });

  int get computedStar2 => star2Score > 0 ? star2Score : (star1Score * kStar2Threshold).round();
  int get computedStar3 => star3Score > 0 ? star3Score : (star1Score * kStar3Threshold).round();

  int starsForScore(int score) {
    if (score >= computedStar3) return 3;
    if (score >= computedStar2) return 2;
    if (score >= star1Score) return 1;
    return 0;
  }

  AtollInfo get atoll {
    for (final a in atolls) {
      if (levelNumber >= a.startLevel && levelNumber <= a.endLevel) return a;
    }
    return atolls.last;
  }

  factory LevelData.fromJson(Map<String, dynamic> json) {
    final objectiveType = ObjectiveType.values.firstWhere(
      (e) => e.name == json['objectiveType'],
    );

    final availableLetterNames = (json['availableLetters'] as List<dynamic>)
        .map((e) => ThaanaLetter.values.firstWhere((l) => l.name == e))
        .toList();

    LevelObjective objective;
    switch (objectiveType) {
      case ObjectiveType.score:
        objective = LevelObjective.score(
          target: json['targetScore'] as int,
          moves: json['moveLimit'] as int,
        );
        break;
      case ObjectiveType.clearLetters:
        final targets = (json['letterTargets'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            ThaanaLetter.values.firstWhere((l) => l.name == key),
            value as int,
          ),
        );
        objective = LevelObjective.clearLetters(
          targets: targets,
          moves: json['moveLimit'] as int,
        );
        break;
      case ObjectiveType.dropItems:
        objective = LevelObjective.dropItems(
          count: json['dropItemCount'] as int,
          moves: json['moveLimit'] as int,
        );
        break;
      case ObjectiveType.timed:
        objective = LevelObjective.timed(
          target: json['targetScore'] as int,
          seconds: json['timeLimit'] as int,
        );
        break;
    }

    final blockers = (json['blockers'] as List<dynamic>?)
            ?.map((b) => BlockerPosition.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [];

    final drops = (json['dropItems'] as List<dynamic>?)
            ?.map((d) => DropItemPosition.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [];

    return LevelData(
      levelNumber: json['levelNumber'] as int,
      objective: objective,
      availableLetters: availableLetterNames,
      star1Score: json['star1Score'] as int,
      star2Score: (json['star2Score'] as int?) ?? 0,
      star3Score: (json['star3Score'] as int?) ?? 0,
      blockers: blockers,
      dropItems: drops,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'objectiveType': objective.type.name,
        'targetScore': objective.targetScore,
        'moveLimit': objective.moveLimit,
        'timeLimit': objective.timeLimit,
        'dropItemCount': objective.dropItemCount,
        'letterTargets': objective.letterTargets.map((k, v) => MapEntry(k.name, v)),
        'availableLetters': availableLetters.map((l) => l.name).toList(),
        'star1Score': star1Score,
        'star2Score': star2Score,
        'star3Score': star3Score,
        'blockers': blockers.map((b) => b.toJson()).toList(),
        'dropItems': dropItems.map((d) => d.toJson()).toList(),
      };
}

class BlockerPosition {
  final int row;
  final int col;
  final BlockerType type;

  const BlockerPosition({
    required this.row,
    required this.col,
    required this.type,
  });

  factory BlockerPosition.fromJson(Map<String, dynamic> json) => BlockerPosition(
        row: json['row'] as int,
        col: json['col'] as int,
        type: BlockerType.values.firstWhere((e) => e.name == json['type']),
      );

  Map<String, dynamic> toJson() => {
        'row': row,
        'col': col,
        'type': type.name,
      };
}

class DropItemPosition {
  final int row;
  final int col;

  const DropItemPosition({required this.row, required this.col});

  factory DropItemPosition.fromJson(Map<String, dynamic> json) => DropItemPosition(
        row: json['row'] as int,
        col: json['col'] as int,
      );

  Map<String, dynamic> toJson() => {'row': row, 'col': col};
}
