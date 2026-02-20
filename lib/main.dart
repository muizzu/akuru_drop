import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'services/ad_service.dart';
import 'game/managers/level_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Immersive mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final audioService = AudioService(storageService);
  await audioService.init();

  final adService = AdService(storageService);
  // Initialize ads without blocking app start
  adService.init();

  final levelManager = LevelManager();
  await levelManager.loadLevels();

  // Start music
  audioService.startMusic();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<AudioService>.value(value: audioService),
        Provider<AdService>.value(value: adService),
        Provider<LevelManager>.value(value: levelManager),
      ],
      child: const AkuruDropApp(),
    ),
  );
}
