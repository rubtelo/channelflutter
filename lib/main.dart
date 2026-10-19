import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';

import 'models/channel.dart';
import 'player_screen.dart';

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

  List<Channel> _channels = [];
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
      final response = await http
          .get(
            Uri.parse(apiUrl),
            headers: apiHeaders,
          )
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;

      if (response.statusCode != 200) throw Exception();

      final jsonData = json.decode(response.body);
      if (jsonData is! Map<String, dynamic>) {
        throw const FormatException('Respuesta inesperada');
      }
      final channels = Channel.parseList(jsonData['data']);
      final lastUpdated = jsonData['last_updated'];
      setState(() {
        _channels = channels;
        _lastUpdated = lastUpdated is String ? lastUpdated : '';
        _isLoading = false;
      });

      if (_lastUpdated.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Datos actualizados'),
              duration: Duration(seconds: 1)),
        );
      }
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'El servidor devolvió una respuesta inválida.';
      });
    } catch (e) {
      if (!mounted) return;
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
    final bool isMobile =
        screenWidth < 800; // Umbral para dispositivos pequeños

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: isMobile
          ? AppBar(
              title: const Text('Deportes',
                  style: TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.black,
              actions: [
                IconButton(
                    icon: const Icon(Icons.sync), onPressed: _fetchChannels),
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
                  Text(_selectedInfo,
                      style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    _lastUpdated.isNotEmpty
                        ? 'Última actualización: $_lastUpdated'
                        : 'Seleccionar canal.',
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
      color: Colors.black.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            const Text('Deportes',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent)),
            const SizedBox(height: 40),
          ],
          _SidebarItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: true,
            onTap: () {
              if (isMobile) Navigator.pop(context);
            },
          ),
          _SidebarItem(
            icon: Icons.sync,
            label: 'Actualizar',
            onTap: () {
              if (isMobile) Navigator.pop(context);
              _fetchChannels();
            },
          ),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(_error!,
                    style:
                        const TextStyle(color: Colors.orange, fontSize: 11))),
          const Spacer(),
          const Text('v1.2.0 - By RS',
              style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );

    return isMobile ? Drawer(child: content) : content;
  }

  Widget _buildBody(double width) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // CALCULAR COLUMNAS SEGÚN EL ANCHO
    int columns = 4;
    if (width < 600) {
      columns = 2;
    } else if (width < 1000) {
      columns = 3;
    }

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
        final title = channel.title.isNotEmpty ? channel.title : 'No Title';
        return _TVCard(
          title: title,
          logoUrl: channel.logo,
          onFocus: () => setState(() => _selectedInfo = title),
          onTap: () {
            if (channel.links.isNotEmpty) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                          title: channel.title, urls: channel.links)));
            }
          },
        );
      },
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SidebarItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.isSelected = false});

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
                  ? Colors.blueAccent.withValues(alpha: 0.1)
                  : (_isFocused
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _isFocused ? Colors.blueAccent : Colors.transparent,
                  width: 1),
            ),
            child: Row(children: [
              Icon(widget.icon,
                  color: widget.isSelected || _isFocused
                      ? Colors.blueAccent
                      : Colors.white70),
              const SizedBox(width: 15),
              Text(widget.label,
                  style: TextStyle(
                      color: widget.isSelected || _isFocused
                          ? Colors.blueAccent
                          : Colors.white70,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.normal))
            ]),
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
  const _TVCard(
      {required this.title,
      required this.logoUrl,
      required this.onFocus,
      required this.onTap});
  @override
  State<_TVCard> createState() => _TVCardState();
}

class _TVCardState extends State<_TVCard> {
  bool _isFocused = false;

  bool get _isNetworkLogo =>
      widget.logoUrl.startsWith('http://') ||
      widget.logoUrl.startsWith('https://');

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
            border: Border.all(
                color: _isFocused ? Colors.white : Colors.white10,
                width: _isFocused ? 4 : 1),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: widget.logoUrl.isEmpty
                        ? const Icon(Icons.tv, size: 50, color: Colors.white24)
                        : _isNetworkLogo
                            ? Image.network(
                                widget.logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(Icons.tv,
                                    size: 50, color: Colors.white24),
                              )
                            : Image.asset(
                                _localAssetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(Icons.tv,
                                    size: 50, color: Colors.white24),
                              ),
                  ),
                ),
                Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 10),
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Text(widget.title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
