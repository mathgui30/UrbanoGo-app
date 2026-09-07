import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaBase extends StatelessWidget {
  final LatLng initialCenter;
  final double zoom;

  MapaBase({required this.initialCenter, this.zoom = 13.0});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: initialCenter,
        zoom: zoom,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
      ],
    );
  }
}
