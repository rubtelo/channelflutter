import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
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
  final String apiUrl = 'https://channelapp-1.onrender.com/api/channels'; 
  final Map<String, String> apiHeaders = {
    'x-api-key': 'Adm1n1str4',
  };

  final String mockJson = '''
  {
    "last_updated": "2026-04-08T02:18:09.721Z",
    "data": [
    {
      "title": "DSPORTS",
      "logo": "dsports.png",
      "sources": [
        {
          "id": 1,
          "link": "https://qzv4jmsc.fubohd.com/dsports/mono.m3u8?token=ca0eb0e3f3d0c36126530066baf51bb5fc93931f-d9-1775721558-1775703558"
        },
        {
          "id": 2,
          "link": "https://doc1.streameasthd.net/global/dsports/index.m3u8?token=642d6297389c45d65d4a143a4bff6ff5550756b5-9d-1775749470-1775695470"
        }
      ]
    },
    {
      "title": "DSPORTS2",
      "logo": "dsports2.png",
      "sources": [
        {
          "id": 1,
          "link": "https://a2vlca.fubohd.com/dsports2/mono.m3u8?token=27d3c62f791f89c86b039f65b607e141ad9c6196-28-1775721582-1775703582"
        },
        {
          "id": 2,
          "link": "https://98ca2.streameasthd.net/global/dsports2/index.m3u8?token=880b5710348d1b662c6507523937196d374468de-d3-1775749494-1775695494"
        }
      ]
    },
    {
      "title": "DSPORTS+",
      "logo": "dsportsplus.png",
      "sources": [
        {
          "id": 1,
          "link": "https://wp9xqedt.fubohd.com/dsportsplus/mono.m3u8?token=2b6a1e096dd6cf81df1d647d76b27ad8660d119e-f5-1775721605-1775703605"
        },
        {
          "id": 2,
          "link": "https://98ca2.streameasthd.net/global/dsportsplus/index.m3u8?token=d9036c89cdaa2029c7e0d6972efa5952b30f41a3-d4-1775749517-1775695517"
        }
      ]
    },
    {
      "title": "ESPN",
      "logo": "espn.png",
      "sources": [
        {
          "id": 1,
          "link": "https://bgfuzq.fubohd.com/espn/mono.m3u8?token=e9fa2b88f384845a51e807ff18922295708879af-29-1775721628-1775703628"
        },
        {
          "id": 2,
          "link": "https://pecdl1.streameasthd.net/global/espn/index.m3u8?token=1e7df88facfb2ab2ea77682dc976f3cb26fcfbbc-c8-1775749540-1775695540"
        }
      ]
    },
    {
      "title": "ESPN2",
      "logo": "espn2.png",
      "sources": [
        {
          "id": 1,
          "link": "https://aw1wcm92zq.fubohd.com/espn2/mono.m3u8?token=877b9635a2d7ab66e266370f909d70ecb05d49b5-e4-1775721651-1775703651"
        },
        {
          "id": 2,
          "link": "https://24a1.streameasthd.net/global/espn2/index.m3u8?token=1ef4bc4fc5cb4891fcfe1a56df2bca4994de155d-ef-1775749563-1775695563"
        }
      ]
    },
    {
      "title": "ESPN3",
      "logo": "espn3.png",
      "sources": [
        {
          "id": 1,
          "link": "https://ym9yzq.fubohd.com/espn3/mono.m3u8?token=382083b929dbae06fdcc944a5969f73a16a5ed26-ec-1775721674-1775703674"
        },
        {
          "id": 2,
          "link": "https://doc1.streameasthd.net/global/espn3/index.m3u8?token=37d26828a0587fdfe0be30507286fe11dd3b382e-9c-1775749586-1775695586"
        }
      ]
    },
    {
      "title": "ESPN4",
      "logo": "espn4.png",
      "sources": [
        {
          "id": 1,
          "link": "https://dw5pdgvk.fubohd.com/espn4/mono.m3u8?token=d4b6ca4193c253334dbc60f35f0b97f0c24615fe-f1-1775721697-1775703697"
        },
        {
          "id": 2,
          "link": "https://24a1.streameasthd.net/global/espn4/index.m3u8?token=8c77a0fddf5192c78cc3aab4377c47c467d5e72a-6b-1775749609-1775695609"
        }
      ]
    },
    {
      "title": "ESPN5",
      "logo": "espn5.png",
      "sources": [
        {
          "id": 1,
          "link": "https://agvyby.fubohd.com/espn5/mono.m3u8?token=4ac3ce07033990d6663328c1b47c27d42210e686-30-1775721722-1775703722"
        },
        {
          "id": 2,
          "link": "https://24a1.streameasthd.net/global/espn5/index.m3u8?token=9ecf787f84fe4e5c607579914f6ff85976fd0932-0a-1775749634-1775695634"
        }
      ]
    },
    {
      "title": "ESPN6",
      "logo": "espn6.png",
      "sources": [
        {
          "id": 1,
          "link": "https://rm8zcvk3.fubohd.com/espn6/mono.m3u8?token=028b653a4f819c40c03e471f2cb0f4d463f7e9c9-57-1775721746-1775703746"
        },
        {
          "id": 2,
          "link": "https://24a1.streameasthd.net/global/espn6/index.m3u8?token=df937eb3df467ab71a6289b2b708735e04260289-be-1775749657-1775695657"
        }
      ]
    },
    {
      "title": "ESPN7",
      "logo": "espn7.png",
      "sources": [
        {
          "id": 1,
          "link": "https://c2nvdxq.fubohd.com/espn7/mono.m3u8?token=40ea5d75ae38e566a3e294073cb9dc2fe50e3d94-b0-1775721769-1775703769"
        },
        {
          "id": 2,
          "link": "https://24a1.streameasthd.net/global/espn7/index.m3u8?token=83360141890b55655294eb55ac5401780ce3c907-15-1775749680-1775695680"
        }
      ]
    },
    {
      "title": "TyC Sports",
      "logo": "tycsports.png",
      "sources": [
        {
          "id": 1,
          "link": "https://agvyby.fubohd.com/tycsports/mono.m3u8?token=a36b0113430942b6fb611851f30858347314c2a1-e1-1775721792-1775703792"
        },
        {
          "id": 2,
          "link": "https://doc1.streameasthd.net/global/tycsports/index.m3u8?token=2c60777222d063eaa8a0b32320b7b20c8e1cc3dc-e9-1775749704-1775695704"
        }
      ]
    },
    {
      "title": "TyC Sports Internacional",
      "logo": "tycsports.png",
      "sources": [
        {
          "id": 1,
          "link": "https://x4bnd7lq.fubohd.com/tycinternacional/mono.m3u8?token=0271941bdddbe0fdf7b1b4dd0df45ff93add202a-a-1775721816-1775703816"
        },
        {
          "id": 2,
          "link": "https://14c51.streameasthd.net/global/tycinternacional/index.m3u8?token=0e7655dac5f1ce44ab9fd4fcd8d232c3588a09b1-9b-1775749727-1775695727"
        }
      ]
    },
    {
      "title": "WIN SPORTS",
      "logo": "winsports.png",
      "sources": [
        {
          "id": 1,
          "link": "https://ym9yzq.fubohd.com/winsports/mono.m3u8?token=cea5a76aadb022a804a362688462e771fb468363-86-1775721839-1775703839"
        },
        {
          "id": 2,
          "link": "https://24a1.streameasthd.net/global/winsports/index.m3u8?token=06217ab31e1c6ddba3d3baf4edd3470e127d6543-41-1775749750-1775695750"
        }
      ]
    },
    {
      "title": "WIN SPORTS +",
      "logo": "winsportsplus.png",
      "sources": [
        {
          "id": 1,
          "link": "https://dw5pdgvk.fubohd.com/winsportsplus/mono.m3u8?token=8f12d97c794986ed54a2c856f9e6b43cb8cc47fc-66-1775721862-1775703862"
        },
        {
          "id": 2,
          "link": "https://98ca2.streameasthd.net/global/winplus/index.m3u8?token=64c03f30d18cd3bcd97922247da957b8392f5d72-d5-1775749773-1775695773"
        }
      ]
    },
    {
      "title": "WIN PLUS+",
      "logo": "winsportsplus.png",
      "sources": [
        {
          "id": 1,
          "link": "https://ym9yzq.fubohd.com/winsports2/mono.m3u8?token=bc1d1dbaff69c8507aa4ee189278ac5f87c3ad03-62-1775721885-1775703885"
        },
        {
          "id": 2,
          "link": "https://98ca2.streameasthd.net/global/winplus2/index.m3u8?token=2353362bb7cc3e706a929ba8d7ca26159c1865b0-0e-1775749796-1775695796"
        }
      ]
    }
  ]
  }
  ''';

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
      final Map<String, dynamic> jsonData = json.decode(mockJson);
      setState(() {
        _channels = jsonData['data'];
        _lastUpdated = jsonData['last_updated'] ?? 'Demo Mode';
        _isLoading = false;
        _error = 'Usando datos locales (API fuera de línea)';
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
            title: const Text('FLUTTER TV', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
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
      width: isMobile ? null : 250,
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            const Text('FLUTTER TV', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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
