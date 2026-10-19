import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final List<String> urls;
  const VideoPlayerScreen({super.key, required this.title, required this.urls});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _showControls = true;
  bool _hasError = false;
  bool _isBuffering = false;

  /// true mientras se prueba otra fuente porque la anterior falló sola.
  bool _autoSwitching = false;
  int _sourceIndex = 0;

  /// Fuentes que han fallado seguidas; evita dar vueltas infinitas si todas fallan.
  int _failedInRow = 0;

  /// Controller cuyo fallo ya se atendió (el error puede notificarse varias veces).
  VideoPlayerController? _failedController;

  Timer? _hideTimer;
  bool _wakelockOn = false;
  final FocusNode _rootFocus = FocusNode(debugLabel: 'player-root');
  final FocusNode _playFocus = FocusNode(debugLabel: 'player-play');
  final FocusNode _sourceFocus = FocusNode(debugLabel: 'player-source');

  bool get _isReady => _controller?.value.isInitialized ?? false;
  bool get _isPlaying => _controller?.value.isPlaying ?? false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadSource(0);
  }

  /// Carga el link en la posición [index] de `widget.urls` y lo reproduce.
  void _loadSource(int index) {
    final old = _controller;
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.urls[index]));
    controller.addListener(_onControllerUpdate);
    setState(() {
      _controller = controller;
      _sourceIndex = index;
      _hasError = false;
      _isBuffering = false;
    });
    old?.removeListener(_onControllerUpdate);
    old?.dispose();
    _syncWakelock();
    controller.initialize().then((_) {
      if (!mounted || controller != _controller) return;
      _failedInRow = 0;
      setState(() => _autoSwitching = false);
      controller.play();
      _resetHideTimer();
    }).catchError((_) {
      _onSourceFailed(controller);
    });
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null || !mounted) return;
    _syncWakelock();
    if (c.value.hasError) {
      // En microtask: no se puede liberar el controller mientras notifica.
      scheduleMicrotask(() => _onSourceFailed(c));
      return;
    }
    final buffering = c.value.isInitialized && c.value.isBuffering;
    if (buffering != _isBuffering) setState(() => _isBuffering = buffering);
  }

  /// Una fuente falló (al iniciar o durante la reproducción): prueba la
  /// siguiente automáticamente, y si ya se probaron todas muestra el error.
  void _onSourceFailed(VideoPlayerController failed) {
    if (!mounted || failed != _controller || failed == _failedController) {
      return;
    }
    _failedController = failed;
    _failedInRow++;
    if (_failedInRow < widget.urls.length) {
      setState(() => _autoSwitching = true);
      _loadSource((_sourceIndex + 1) % widget.urls.length);
    } else {
      setState(() {
        _autoSwitching = false;
        _hasError = true;
        _isBuffering = false;
      });
      _syncWakelock();
    }
  }

  /// Mantiene la pantalla encendida solo mientras el video se está reproduciendo.
  void _syncWakelock() {
    final shouldBeOn = !_hasError && _isPlaying;
    if (shouldBeOn == _wakelockOn) return;
    _wakelockOn = shouldBeOn;
    shouldBeOn ? WakelockPlus.enable() : WakelockPlus.disable();
  }

  void _nextSource() {
    if (widget.urls.length < 2) return;
    _failedInRow = 0;
    _autoSwitching = false;
    _loadSource((_sourceIndex + 1) % widget.urls.length);
    _resetHideTimer();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  void _play() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.play());
  }

  void _pause() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.pause());
  }

  void _resetHideTimer() {
    if (!mounted) return;
    setState(() => _showControls = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      // Los botones se quitan del árbol: devolver el foco a la raíz antes.
      _rootFocus.requestFocus();
      setState(() => _showControls = false);
    });
  }

  /// Pasa el foco a un botón de control una vez que están visibles.
  void _focusControl(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showControls) node.requestFocus();
    });
  }

  bool _isArrow(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight;

  KeyEventResult _onPlayerKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final controlsWereHidden = !_showControls;
    _resetHideTimer();

    // Teclas dedicadas de cambio de fuente (control con canal +/- o siguiente).
    if (key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.mediaTrackNext ||
        key == LogicalKeyboardKey.mediaTrackPrevious) {
      _nextSource();
      return KeyEventResult.handled;
    }

    // Teclas multimedia del control.
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlay();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPlay) {
      _play();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaPause) {
      _pause();
      return KeyEventResult.handled;
    }

    // Con el control genérico: una flecha lleva el foco a los botones.
    if (_isArrow(key) && node.hasPrimaryFocus) {
      _focusControl(
          widget.urls.length > 1 && key == LogicalKeyboardKey.arrowRight
              ? _sourceFocus
              : _playFocus);
      return KeyEventResult.handled;
    }
    // Si los controles estaban ocultos, esta pulsación solo los muestra.
    if (controlsWereHidden && _isArrow(key)) return KeyEventResult.handled;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA) {
      _togglePlay();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    _rootFocus.dispose();
    _playFocus.dispose();
    _sourceFocus.dispose();
    _hideTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    if (_wakelockOn) WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        focusNode: _rootFocus,
        onKeyEvent: _onPlayerKey,
        // SizedBox.expand: sin esto el Stack se encoge al tamaño del video
        // cuando se ocultan los controles y queda pegado arriba a la izquierda.
        child: SizedBox.expand(
            child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isReady)
              AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!))
            else if (_hasError)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.orange),
                  const SizedBox(height: 12),
                  Text(
                    widget.urls.length > 1
                        ? 'No se pudo reproducir ninguna fuente de este canal.'
                        : 'No se pudo reproducir el canal.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (_autoSwitching) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Fuente no disponible. Probando ${_sourceIndex + 1}/${widget.urls.length}…',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),

            // Se atascó el stream en medio de la reproducción.
            if (_isReady && _isBuffering) const CircularProgressIndicator(),

            if (_showControls)
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent
                  ]))),

            if (_showControls)
              Positioned(
                bottom: 80,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ControlBtn(
                      focusNode: _playFocus,
                      icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                      onTap: () {
                        _togglePlay();
                        _resetHideTimer();
                      },
                    ),
                    if (widget.urls.length > 1) ...[
                      const SizedBox(width: 20),
                      _ControlBtn(
                        focusNode: _sourceFocus,
                        icon: Icons.swap_horiz,
                        label:
                            'Fuente ${_sourceIndex + 1}/${widget.urls.length}',
                        onTap: _nextSource,
                      ),
                    ],
                  ],
                ),
              ),

            if (_showControls)
              Positioned(
                  top: 40,
                  left: 40,
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold))),

            // BOTÓN DE CERRAR PARA MOVIL (Ya que no tienen botón Return físico a veces)
            Positioned(
                top: 40,
                right: 40,
                child: IconButton(
                    icon:
                        const Icon(Icons.close, size: 30, color: Colors.white),
                    onPressed: () => Navigator.pop(context))),
          ],
        )),
      ),
    );
  }
}

class _ControlBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final FocusNode? focusNode;
  const _ControlBtn(
      {required this.icon, required this.onTap, this.label, this.focusNode});
  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn> {
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: widget.label == null
              ? const EdgeInsets.all(20)
              : const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
          decoration: BoxDecoration(
            color: _isFocused
                ? Colors.blueAccent
                : Colors.white.withValues(alpha: 0.1),
            shape: widget.label == null ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                widget.label == null ? null : BorderRadius.circular(40),
            border: Border.all(
                color: _isFocused ? Colors.white : Colors.transparent,
                width: 3),
          ),
          child: widget.label == null
              ? Icon(widget.icon, size: 40, color: Colors.white)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 40, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(widget.label!,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}
