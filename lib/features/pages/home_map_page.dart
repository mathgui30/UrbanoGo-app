import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:urbanogo/features/pages/auth/cubit/auth_cubit.dart';
import 'package:urbanogo/features/pages/auth/login_page.dart';
import 'package:urbanogo/shared_widgets/mapa_base.dart';

class HomeMapPage extends StatefulWidget {
  final String flavor;

  const HomeMapPage({super.key, this.flavor = 'passageiro'});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position initialPos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _currentPosition = LatLng(initialPos.latitude, initialPos.longitude);
    });

    _mapController.move(_currentPosition!, 19.0);

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
        });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _centerMapOnUser() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 19.0);
    }
  }

  void _logout() {
    context.read<AuthCubit>().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(flavor: widget.flavor)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _currentPosition == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Buscando sua localização...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                MapaBase(
                  initialCenter: _currentPosition!,
                  zoom: 19.0,
                  mapController: _mapController,
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blueAccent,
                        size: 30,
                      ),
                    ),
                  ],
                ),

                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Para onde vamos?',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        suffixIcon: Icon(Icons.mic, color: Colors.white),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 30,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'logout',
                        mini: true,
                        backgroundColor: Colors.grey[900],
                        foregroundColor: Colors.white,
                        onPressed: _logout,
                        child: const Icon(Icons.logout),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'recenter',
                        backgroundColor: Colors.grey[900],
                        foregroundColor: Colors.white,
                        onPressed: _centerMapOnUser,
                        child: const Icon(Icons.gps_fixed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
