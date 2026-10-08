import 'package:flutter/material.dart';
import 'package:provider/single_child_widget.dart';

///A saved match the launcher can offer to continue
class ResumableMatch {
  ///Short description, e.g. "4 players · vs Computer"
  final String summary;
  const ResumableMatch(this.summary);
}

///How a game plugs into the app. Deliberately small: it describes the game
///for the launcher and wires its screens and state into the app. All game
///logic stays inside the game's own folder.
///
///Adding a game = a new `games/<name>/` folder exporting one
///[GameDefinition], plus one entry in `game_catalog.dart`.
class GameDefinition {
  final String id;
  final String title;
  final String tagline;
  final IconData icon;
  final Color accent;

  ///Large artwork for the launcher card, drawn within [size] x [size]
  final Widget Function(BuildContext context, double size)? artwork;

  ///Route that starts a new match (usually the setup screen).
  ///Null while the game is only announced as "coming soon".
  final String? playRoute;
  final String? howToPlayRoute;
  final String? recordsRoute;

  ///Named routes owned by the game
  final Map<String, WidgetBuilder> routes;

  ///App-lifetime providers the game needs (controllers, stores)
  final List<SingleChildWidget> providers;

  ///Optional section the settings screen shows for this game
  final WidgetBuilder? settingsSection;

  ///Resets the game's own settings (called by "Reset settings")
  final Future<void> Function(BuildContext context)? resetSettings;

  ///Returns the saved match the player can continue, if any
  final Future<ResumableMatch?> Function(BuildContext context)? findResumable;

  ///Restores the saved match and opens it. Returns false when it failed.
  final Future<bool> Function(BuildContext context)? resume;

  const GameDefinition({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.accent,
    this.artwork,
    this.playRoute,
    this.howToPlayRoute,
    this.recordsRoute,
    this.routes = const {},
    this.providers = const [],
    this.settingsSection,
    this.resetSettings,
    this.findResumable,
    this.resume,
  });

  ///A launcher placeholder for a game that is not built yet
  const GameDefinition.comingSoon({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.accent,
  })  : artwork = null,
        playRoute = null,
        howToPlayRoute = null,
        recordsRoute = null,
        routes = const {},
        providers = const [],
        settingsSection = null,
        resetSettings = null,
        findResumable = null,
        resume = null;

  bool get isAvailable => playRoute != null;
}
