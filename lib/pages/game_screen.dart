import 'package:flutter/material.dart';
import 'package:ludo_flutter/audio.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/widgets/board_widget.dart';
import 'package:ludo_flutter/widgets/dice_widget.dart';
import 'package:ludo_flutter/widgets/pause_menu.dart';
import 'package:provider/provider.dart';

///The running match: HUD, board and dice
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  bool _navigatedToGameOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = context.read<LudoProvider>();
    if (provider.players.isEmpty) provider.startGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ///Persist the match whenever the app leaves the foreground so an
    ///OS kill mid-game never loses progress
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      context.read<LudoProvider>().flushSave();
    }
  }

  Future<void> _openPauseMenu() async {
    final provider = context.read<LudoProvider>();
    provider.setPaused(true);
    final action = await showPauseMenu(context);
    if (!mounted) return;
    if (action != null) Audio.hapticLight();

    switch (action) {
      case PauseAction.restart:
        provider.setPaused(false);
        provider.restartGame();
        setState(() => _navigatedToGameOver = false);
        break;
      case PauseAction.settings:
        await Navigator.of(context).pushNamed('/settings');
        if (!mounted) return;
        provider.setPaused(false);
        break;
      case PauseAction.quit:
        provider.quitMatch();
        Navigator.of(context).popUntil((route) => route.settings.name == '/home');
        break;
      case PauseAction.resume:
      case null:
        provider.setPaused(false);
        break;
    }
  }

  void _onFinished(LudoProvider value) {
    if (!value.isFinished || _navigatedToGameOver) return;
    _navigatedToGameOver = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/gameOver');
    });
  }

  String _hint(LudoProvider value, AppStrings s) {
    if (value.isFinished) return s.hintGameOver;
    if (value.isPaused) return s.hintPaused;
    switch (value.gameState) {
      case LudoGameState.throwDice:
        return value.isCpuTurn
            ? s.hintRolling(value.currentPlayer.name)
            : s.hintTapDice;
      case LudoGameState.pickPawn:
        return value.isCpuTurn
            ? s.hintThinking(value.currentPlayer.name)
            : s.hintTapPawn;
      case LudoGameState.moving:
        return s.hintPawnMoving;
      case LudoGameState.finish:
        return s.hintGameOver;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<LudoProvider>(
          builder: (context, value, child) {
            ///Match was torn down (quit) while this screen is popping
            if (value.players.isEmpty) return const SizedBox.shrink();
            final s = AppStrings.of(context);
            _onFinished(value);
            return Column(
              children: [
                _buildHud(context, value),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BoardWidget(),
                          const SizedBox(height: 8),
                          const SizedBox(width: 56, height: 56, child: DiceWidget()),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _hint(value, s),
                              key: ValueKey<String>(_hint(value, s)),
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String crownAsset(int rank) {
    final suffix = rank == 1 ? 'st' : rank == 2 ? 'nd' : 'rd';
    return 'assets/images/crown/$rank$suffix.png';
  }

  Widget _buildHud(BuildContext context, LudoProvider value) {
    final s = AppStrings.of(context);
    final currentPlayer = value.currentPlayer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _openPauseMenu,
                icon: const Icon(Icons.pause_circle_filled_rounded, size: 36),
                tooltip: s.pause,
              ),
              Expanded(
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: currentPlayer.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: currentPlayer.color, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: currentPlayer.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${currentPlayer.name} ${currentPlayer.isCpu ? s.cpuSeat : s.youSeat}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
              IconButton(
                onPressed: value.canUndo
                    ? () {
                        Audio.hapticLight();
                        value.undoLastMove();
                      }
                    : null,
                icon: const Icon(Icons.undo_rounded, size: 28),
                tooltip: s.undoLastMove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final player in value.players)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: player.type == currentPlayer.type
                              ? player.color
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: player.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(player.name, style: const TextStyle(fontSize: 12)),
                          if (value.winners.contains(player.type)) ...[
                            const SizedBox(width: 4),
                            Image.asset(
                              crownAsset(value.winners.indexOf(player.type) + 1),
                              width: 14,
                              height: 14,
                              errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events_rounded,
                                  size: 14, color: Colors.amber),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
