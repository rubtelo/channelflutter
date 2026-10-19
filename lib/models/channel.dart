/// Canal de TV tal como llega en `data` de la API.
class Channel {
  final String title;
  final String logo;

  /// Links de reproducción, en el orden en que vienen en `sources`.
  final List<String> links;

  const Channel({required this.title, required this.logo, required this.links});

  factory Channel.fromJson(Map<String, dynamic> json) {
    final links = <String>[];
    final sources = json['sources'];
    if (sources is List) {
      for (final source in sources) {
        final link = source is Map ? source['link'] : null;
        if (link is String && link.isNotEmpty) links.add(link);
      }
    }
    return Channel(
      title: json['title'] is String ? json['title'] as String : '',
      logo: json['logo'] is String ? json['logo'] as String : '',
      links: links,
    );
  }

  /// Convierte el campo `data` de la API en canales.
  /// Lanza [FormatException] si no es una lista.
  static List<Channel> parseList(dynamic data) {
    if (data is! List) {
      throw const FormatException('El campo "data" no es una lista');
    }
    return data
        .whereType<Map>()
        .map((item) => Channel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
