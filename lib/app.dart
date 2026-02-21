import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/audio_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/game_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';

class AkuruDropApp extends StatelessWidget {
  const AkuruDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akuru Drop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const AppNavigator(),
    );
  }
}

enum AppScreen {
  splash,
  home,
  levelSelect,
  game,
  settings,
  shop,
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> with WidgetsBindingObserver {
  AppScreen _currentScreen = AppScreen.splash;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = context.read<AudioService>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      audio.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      audio.resumeMusic();
    }
  }

  void _navigate(AppScreen screen, {int? level}) {
    setState(() {
      _currentScreen = screen;
      if (level != null) _currentLevel = level;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentScreen == AppScreen.splash || _currentScreen == AppScreen.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildScreen(),
      ),
    );
  }

  void _handleBack() {
    switch (_currentScreen) {
      case AppScreen.splash:
      case AppScreen.home:
        break;
      case AppScreen.levelSelect:
      case AppScreen.settings:
      case AppScreen.shop:
        _navigate(AppScreen.home);
        break;
      case AppScreen.game:
        _navigate(AppScreen.levelSelect);
        break;
    }
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case AppScreen.splash:
        return SplashScreen(
          key: const ValueKey('splash'),
          onComplete: () => _navigate(AppScreen.home),
        );

      case AppScreen.home:
        return HomeScreen(
          key: const ValueKey('home'),
          onPlay: () => _navigate(AppScreen.levelSelect),
          onSettings: () => _navigate(AppScreen.settings),
          onShop: () => _navigate(AppScreen.shop),
        );

      case AppScreen.levelSelect:
        return LevelSelectScreen(
          key: const ValueKey('levelSelect'),
          onLevelSelected: (level) => _navigate(AppScreen.game, level: level),
          onBack: () => _navigate(AppScreen.home),
        );

      case AppScreen.game:
        return GameScreen(
          key: ValueKey('game_$_currentLevel'),
          levelNumber: _currentLevel,
          onBack: () => _navigate(AppScreen.levelSelect),
          onNextLevel: () => _navigate(AppScreen.game, level: _currentLevel + 1),
        );

      case AppScreen.settings:
        return SettingsScreen(
          key: const ValueKey('settings'),
          onBack: () => _navigate(AppScreen.home),
        );

      case AppScreen.shop:
        return ShopScreen(
          key: const ValueKey('shop'),
          onBack: () => _navigate(AppScreen.home),
        );
    }
  }
}
