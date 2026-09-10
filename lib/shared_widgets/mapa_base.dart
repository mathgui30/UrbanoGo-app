import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaBase extends StatelessWidget {
  final LatLng initialCenter;
  final double zoom;
  final MapController? mapController;
  final List<Marker>? markers;
  final void Function(LatLng point)? onTap;
  final VoidCallback? onMapReady;

  const MapaBase({
    super.key,
    required this.initialCenter,
    this.zoom = 19.0,
    this.mapController,
    this.markers,
    this.onTap,
    this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: zoom,
        onTap: onTap == null ? null : (_, point) => onTap!(point),
        onMapReady: onMapReady,
      ),
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            -1,
            0,
            0,
            0,
            255,
            0,
            -1,
            0,
            0,
            255,
            0,
            0,
            -1,
            0,
            255,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'br.com.urbanogo',
          ),
        ),

        if (markers != null && markers!.isNotEmpty)
          MarkerLayer(markers: markers!),
      ],
    );
  }
}
