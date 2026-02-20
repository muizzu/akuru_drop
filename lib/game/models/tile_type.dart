import 'package:flutter/material.dart';
import '../../config/theme.dart';

enum ThaanaLetter {
  haa('ހ', 0),
  shaviyani('ށ', 1),
  noonu('ނ', 2),
  raa('ރ', 3),
  baa('ބ', 4),
  lhaviyani('ޅ', 5),
  kaafu('ކ', 6),
  alifu('އ', 7),
  vaavu('ވ', 8),
  meemu('މ', 9),
  faafu('ފ', 10),
  dhaalu('ދ', 11),
  thaa('ތ', 12),
  laamu('ލ', 13),
  gaafu('ގ', 14),
  gnaviyani('ޏ', 15),
  seenu('ސ', 16),
  daviyani('ޑ', 17),
  zaviyani('ޒ', 18),
  taviyani('ޓ', 19),
  yaa('ޔ', 20),
  paviyani('ޕ', 21),
  javiyani('ޖ', 22),
  chaviyani('ޗ', 23);

  final String letter;
  final int colorIndex;

  const ThaanaLetter(this.letter, this.colorIndex);

  Color get color => AppTheme.tileColors[colorIndex % AppTheme.tileColors.length];

  static List<ThaanaLetter> forLevel(int level) {
    if (level <= 5) return values.sublist(0, 6);
    if (level <= 15) return values.sublist(0, 8);
    if (level <= 30) return values.sublist(0, 10);
    if (level <= 60) return values.sublist(0, 12);
    if (level <= 100) return values.sublist(0, 16);
    return values;
  }
}

enum SpecialTileType {
  none,
  lineHorizontal,
  lineVertical,
  bomb,
  star,
}

enum BlockerType {
  none,
  ice,
  coral,
  chain,
}

class TileState {
  ThaanaLetter? letter;
  SpecialTileType special;
  BlockerType blocker;
  int iceHealth;
  bool hasDropItem;
  bool isEmpty;

  TileState({
    this.letter,
    this.special = SpecialTileType.none,
    this.blocker = BlockerType.none,
    this.iceHealth = 0,
    this.hasDropItem = false,
    this.isEmpty = false,
  });

  TileState copy() => TileState(
        letter: letter,
        special: special,
        blocker: blocker,
        iceHealth: iceHealth,
        hasDropItem: hasDropItem,
        isEmpty: isEmpty,
      );

  bool get isSwappable => blocker != BlockerType.chain && !isEmpty;
  bool get isMatchable => letter != null && !isEmpty;

  @override
  String toString() =>
      'TileState(${letter?.letter ?? "empty"}, special=$special, blocker=$blocker)';
}
