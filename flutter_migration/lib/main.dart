import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/loading_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/map_screen.dart';
import 'screens/stage_mode_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'services/player_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to Portrait matching buildozer.spec orientation = portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Immersive edge-to-edge transparent system bars
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const WhackAWordHamApp());
}

class WhackAWordHamApp extends StatelessWidget {
  const WhackAWordHamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whack-A-Word-Ham',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF140D06),
        fontFamily: 'sans-serif',
      ),
      home: const GameCoordinator(),
    );
  }
}

enum AppRoute {
  loading,
  mainMenu,
  map,
  stageMode,
  wardrobe,
}

/// Central screen coordinator replicating MDScreenManager from the Kivy game.
class GameCoordinator extends StatefulWidget {
  const GameCoordinator({super.key});

  @override
  State<GameCoordinator> createState() => _GameCoordinatorState();
}

class _GameCoordinatorState extends State<GameCoordinator> {
  AppRoute _currentRoute = AppRoute.loading;
  int _selectedStage = 1;

  void _navigateTo(AppRoute route, {int? stage}) {
    setState(() {
      _currentRoute = route;
      if (stage != null) _selectedStage = stage;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentRoute) {
      case AppRoute.loading:
        return LoadingScreen(
          onLoaded: () => _navigateTo(AppRoute.mainMenu),
        );

      case AppRoute.mainMenu:
        return MainMenuScreen(
          onPlayStageMode: () => _navigateTo(AppRoute.map),
          onOpenWardrobe: () => _navigateTo(AppRoute.wardrobe),
        );

      case AppRoute.map:
        return MapScreen(
          onBackToMenu: () => _navigateTo(AppRoute.mainMenu),
          onLaunchStage: (stageNum) =>
              _navigateTo(AppRoute.stageMode, stage: stageNum),
        );

      case AppRoute.stageMode:
        return StageModeScreen(
          initialStage: _selectedStage > 0
              ? _selectedStage
              : PlayerDataService.instance.currentStage,
          onBackToMap: () => _navigateTo(AppRoute.map),
        );

      case AppRoute.wardrobe:
        return WardrobeScreen(
          onBackToMenu: () => _navigateTo(AppRoute.mainMenu),
        );
    }
  }
}
