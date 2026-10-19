import 'package:flutter_test/flutter_test.dart';

import 'package:channelflutter/models/channel.dart';

void main() {
  group('Channel.fromJson', () {
    test('toma todos los links de sources en orden', () {
      final channel = Channel.fromJson({
        'title': 'DSPORTS',
        'logo': 'dsports.png',
        'sources': [
          {'link': 'https://a.example/1.m3u8'},
          {'link': 'http://b.example/2.m3u8'},
        ],
      });

      expect(channel.title, 'DSPORTS');
      expect(channel.logo, 'dsports.png');
      expect(channel.links,
          ['https://a.example/1.m3u8', 'http://b.example/2.m3u8']);
    });

    test('ignora sources sin link o con link vacío', () {
      final channel = Channel.fromJson({
        'title': 'X',
        'sources': [
          {'id': 1},
          {'link': ''},
          {'link': 'https://ok.example/x.m3u8'},
          'no es un mapa',
        ],
      });

      expect(channel.links, ['https://ok.example/x.m3u8']);
    });

    test('no falla si faltan title, logo o sources', () {
      final channel = Channel.fromJson({});

      expect(channel.title, '');
      expect(channel.logo, '');
      expect(channel.links, isEmpty);
    });
  });

  group('Channel.parseList', () {
    test('convierte una lista de canales', () {
      final channels = Channel.parseList([
        {'title': 'A', 'sources': []},
        {'title': 'B', 'sources': []},
      ]);

      expect(channels.map((c) => c.title), ['A', 'B']);
    });

    test('lanza FormatException si data no es una lista', () {
      expect(() => Channel.parseList(null), throwsFormatException);
      expect(() => Channel.parseList({'title': 'A'}), throwsFormatException);
    });
  });
}
