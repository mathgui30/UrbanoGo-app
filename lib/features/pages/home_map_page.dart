import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:urbanogo/core/repositories/ride_repository.dart';
import 'package:urbanogo/features/pages/auth/cubit/auth_cubit.dart';
import 'package:urbanogo/features/pages/auth/login_page.dart';
import 'package:urbanogo/features/pages/ride/cubit/ride_flow_cubit.dart';
import 'package:urbanogo/features/pages/ride/widgets/ride_request_sheet.dart';
import 'package:urbanogo/shared_widgets/mapa_base.dart';

class HomeMapPage extends StatelessWidget {
  final String flavor;

  const HomeMapPage({super.key, this.flavor = 'passageiro'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RideFlowCubit>(
      create: (context) => RideFlowCubit(context.read<RideRepository>()),
      child: _HomeMapView(flavor: flavor),
    );
  }
}

class _HomeMapView extends StatefulWidget {
  final String flavor;

  const _HomeMapView({required this.flavor});

  @override
  State<_HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<_HomeMapView> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  bool get _isPassenger => widget.flavor == 'passageiro';

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
          : BlocBuilder<RideFlowCubit, RideFlowState>(
              builder: (context, ride) {
                return Stack(
                  children: [
                    MapaBase(
                      initialCenter: _currentPosition!,
                      zoom: 19.0,
                      mapController: _mapController,
                      onTap: _isPassenger
                          ? (point) =>
                                context.read<RideFlowCubit>().chooseDestination(
                                  point,
                                )
                          : null,
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
                        if (ride.destination != null)
                          Marker(
                            point: ride.destination!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 36,
                            ),
                          ),
                      ],
                    ),

                    if (!_isPassenger)
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
                      bottom: _isPassenger ? 300 : 30,
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

                    if (_isPassenger)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: RideRequestSheet(origin: _currentPosition),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
