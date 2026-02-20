import '../../services/storage_service.dart';
import '../../config/constants.dart';

enum PowerUpType {
  extraMoves,
  shuffle,
  singleRemove,
}

class PowerUpManager {
  final StorageService _storage;

  bool _extraMovesUsed = false;
  bool _shuffleUsed = false;
  bool _singleRemoveUsed = false;
  bool _singleRemoveActive = false;

  PowerUpManager(this._storage);

  bool get extraMovesUsed => _extraMovesUsed;
  bool get shuffleUsed => _shuffleUsed;
  bool get singleRemoveUsed => _singleRemoveUsed;
  bool get singleRemoveActive => _singleRemoveActive;

  void resetForLevel() {
    _extraMovesUsed = false;
    _shuffleUsed = false;
    _singleRemoveUsed = false;
    _singleRemoveActive = false;
  }

  bool canUse(PowerUpType type) {
    switch (type) {
      case PowerUpType.extraMoves:
        return !_extraMovesUsed && _storage.coins >= kExtraMoveCost;
      case PowerUpType.shuffle:
        return !_shuffleUsed && _storage.coins >= kShuffleCost;
      case PowerUpType.singleRemove:
        return !_singleRemoveUsed && _storage.coins >= kSingleRemoveCost;
    }
  }

  int costFor(PowerUpType type) {
    switch (type) {
      case PowerUpType.extraMoves:
        return kExtraMoveCost;
      case PowerUpType.shuffle:
        return kShuffleCost;
      case PowerUpType.singleRemove:
        return kSingleRemoveCost;
    }
  }

  String nameFor(PowerUpType type, {bool dhivehi = false}) {
    if (dhivehi) {
      switch (type) {
        case PowerUpType.extraMoves:
          return 'އިތުރު މޫވްސް';
        case PowerUpType.shuffle:
          return 'އެއްކޮށްލާ';
        case PowerUpType.singleRemove:
          return 'ޓައިލް ނަގާ';
      }
    }
    switch (type) {
      case PowerUpType.extraMoves:
        return 'Extra Moves (+$kExtraMoveCount)';
      case PowerUpType.shuffle:
        return 'Shuffle';
      case PowerUpType.singleRemove:
        return 'Remove Tile';
    }
  }

  String iconFor(PowerUpType type) {
    switch (type) {
      case PowerUpType.extraMoves:
        return '+5';
      case PowerUpType.shuffle:
        return '⟳';
      case PowerUpType.singleRemove:
        return '✕';
    }
  }

  Future<bool> useExtraMoves() async {
    if (_extraMovesUsed) return false;
    final spent = await _storage.spendCoins(kExtraMoveCost);
    if (spent) {
      _extraMovesUsed = true;
      return true;
    }
    return false;
  }

  Future<bool> useShuffle() async {
    if (_shuffleUsed) return false;
    final spent = await _storage.spendCoins(kShuffleCost);
    if (spent) {
      _shuffleUsed = true;
      return true;
    }
    return false;
  }

  Future<bool> activateSingleRemove() async {
    if (_singleRemoveUsed) return false;
    final spent = await _storage.spendCoins(kSingleRemoveCost);
    if (spent) {
      _singleRemoveUsed = true;
      _singleRemoveActive = true;
      return true;
    }
    return false;
  }

  void deactivateSingleRemove() {
    _singleRemoveActive = false;
  }
}
