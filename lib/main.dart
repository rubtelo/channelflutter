import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';

import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google TV App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TVHomeScreen(),
    );
  }
}

class TVHomeScreen extends StatefulWidget {
  const TVHomeScreen({super.key});

  @override
  State<TVHomeScreen> createState() => _TVHomeScreenState();
}

class _TVHomeScreenState extends State<TVHomeScreen> {
  final String apiUrl = 'https://coopava.com.co/api/getchannels.php'; 
  final Map<String, String> apiHeaders = {
    'x-api-key': 'Adm1n1str4',
  };


  List<dynamic> _channels = [];
  bool _isLoading = true;
  String? _error;
  String _selectedInfo = 'Seleccione un canal';
  String _lastUpdated = '';

  @override
  void initState() {
    super.initState();
    _fetchChannels();
  }

  Future<void> _fetchChannels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: apiHeaders,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        print('API Response: ${response.body}');
        final Map<String, dynamic> jsonData = json.decode(response.body);
        setState(() {
          _channels = jsonData['data'];
          _lastUpdated = jsonData['last_updated'] ?? '';
          _isLoading = false;
        });
        
        if (mounted && _lastUpdated.isNotEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos actualizados'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar canales. Verifique su conexión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // DETERMINAR SI ES MOVIL O TV
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800; // Umbral para dispositivos pequeños

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: isMobile 
        ? AppBar(
            title: const Text('DeporTV', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.black,
            actions: [
              IconButton(icon: const Icon(Icons.sync), onPressed: _fetchChannels),
            ],
          ) 
        : null,
      drawer: isMobile ? _buildSidebar(isMobile: true) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(isMobile: false),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20.0 : 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedInfo, style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    _lastUpdated.isNotEmpty ? 'Última actualización: $_lastUpdated' : 'Seleccionar canal.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: isMobile ? 20 : 40),
                  Expanded(child: _buildBody(screenWidth)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isMobile}) {
    final content = Container(
      width: isMobile ? null : 180,
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            const Text('DeporTV', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 40),
          ],
          _SidebarItem(
            icon: Icons.home, 
            label: 'Home', 
            isSelected: true,
            onTap: () { if(isMobile) Navigator.pop(context); },
          ),
          _SidebarItem(
            icon: Icons.sync, 
            label: 'Actualizar', 
            onTap: () {
              if(isMobile) Navigator.pop(context);
              _fetchChannels();
            },
          ),
          if (_error != null) 
            Padding(
              padding: const EdgeInsets.only(top: 20), 
              child: Text(_error!, style: const TextStyle(color: Colors.orange, fontSize: 11))
            ),
          const Spacer(),
          const Text('v1.0.1', style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );

    return isMobile ? Drawer(child: content) : content;
  }

  Widget _buildBody(double width) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    // CALCULAR COLUMNAS SEGÚN EL ANCHO
    int columns = 4;
    if (width < 600) columns = 2;
    else if (width < 1000) columns = 3;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      itemCount: _channels.length,
      itemBuilder: (context, index) {
        final channel = _channels[index];
        return _TVCard(
          title: channel['title'] ?? 'No Title',
          logoUrl: channel['logo'] ?? '',
          onFocus: () => setState(() => _selectedInfo = channel['title']),
          onTap: () {
            final sources = channel['sources'] ?? [];
            if (sources.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(title: channel['title'], url: sources[0]['link'])));
            }
          },
        );
      },
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String url;
  const VideoPlayerScreen({super.key, required this.title, required this.url});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller.play();
        _resetHideTimer();
      }
    });
  }

  void _resetHideTimer() {
    if (!mounted) return;
    setState(() => _showControls = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          _resetHideTimer();
          // Soporte para pausa/play con botón OK/Enter
          if (event is KeyDownEvent && 
              (event.logicalKey == LogicalKeyboardKey.enter || 
               event.logicalKey == LogicalKeyboardKey.select || 
               event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_controller.value.isInitialized)
              AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
            else
              const CircularProgressIndicator(),
            
            if (_showControls)
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]))),

            if (_showControls)
              Positioned(
                bottom: 80,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ControlBtn(
                      icon: _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                          _resetHideTimer();
                        });
                      },
                    ),
                  ],
                ),
              ),
            
            if (_showControls)
              Positioned(top: 40, left: 40, child: Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
            
            // BOTÓN DE CERRAR PARA MOVIL (Ya que no tienen botón Return físico a veces)
            Positioned(
              top: 40, 
              right: 40, 
              child: IconButton(
                icon: const Icon(Icons.close, size: 30, color: Colors.white), 
                onPressed: () => Navigator.pop(context)
              )
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});
  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn> {
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && 
            (event.logicalKey == LogicalKeyboardKey.enter || 
             event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.blueAccent : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: _isFocused ? Colors.white : Colors.transparent, width: 3),
          ),
          child: Icon(widget.icon, size: 40, color: Colors.white),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SidebarItem({required this.icon, required this.label, required this.onTap, this.isSelected = false});

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Focus(
        onFocusChange: (f) => setState(() => _isFocused = f),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && 
              (event.logicalKey == LogicalKeyboardKey.enter || 
               event.logicalKey == LogicalKeyboardKey.select)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected 
                  ? Colors.blueAccent.withOpacity(0.1) 
                  : (_isFocused ? Colors.white.withOpacity(0.1) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _isFocused ? Colors.blueAccent : Colors.transparent, width: 1),
            ),
            child: Row(children: [Icon(widget.icon, color: widget.isSelected || _isFocused ? Colors.blueAccent : Colors.white70), const SizedBox(width: 15), Text(widget.label, style: TextStyle(color: widget.isSelected || _isFocused ? Colors.blueAccent : Colors.white70, fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal))]),
          ),
        ),
      ),
    );
  }
}

class _TVCard extends StatefulWidget {
  final String title;
  final String logoUrl;
  final VoidCallback onFocus;
  final VoidCallback onTap;
  const _TVCard({required this.title, required this.logoUrl, required this.onFocus, required this.onTap});
  @override
  State<_TVCard> createState() => _TVCardState();
}

class _TVCardState extends State<_TVCard> {
  bool _isFocused = false;

  String get _localAssetPath {
    return 'assets/logos/${widget.logoUrl}';
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        if (focused) widget.onFocus();
      },
      onKeyEvent: (node, event) {
        // Detectar Enter o Select del control remoto
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _isFocused ? Colors.blueAccent : Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isFocused ? Colors.white : Colors.white10, width: _isFocused ? 4 : 1),
            boxShadow: _isFocused ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 2)] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: widget.logoUrl.isNotEmpty
                        ? Image.asset(
                            _localAssetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              if (widget.logoUrl.startsWith('http')) {
                                return Image.network(
                                  widget.logoUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(Icons.tv, size: 50, color: Colors.white24),
                                );
                              }
                              return const Icon(Icons.tv, size: 50, color: Colors.white24);
                            },
                          )
                        : const Icon(Icons.tv, size: 50, color: Colors.white24),
                  ),
                ),
                Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), color: Colors.black.withOpacity(0.6), child: Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
