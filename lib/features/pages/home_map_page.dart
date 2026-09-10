import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:urbanogo/core/repositories/ride_repository.dart';
import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/network/socket_service.dart';
import 'package:urbanogo/core/repositories/driver_repository.dart';
import 'package:urbanogo/features/pages/driver/cubit/driver_flow_cubit.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<RideFlowCubit>(
          create: (context) => RideFlowCubit(
            context.read<RideRepository>(),
            context.read<SocketService>(),
            context.read<ApiClient>(),
          ),
        ),
        if (flavor == 'motorista')
          BlocProvider<DriverFlowCubit>(
            create: (context) => DriverFlowCubit(
              context.read<DriverRepository>(),
              context.read<OfferRepository>(),
              context.read<RideRepository>(),
              context.read<SocketService>(),
              context.read<ApiClient>(),
            ),
          ),
      ],
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

class _HomeMapViewState extends State<_HomeMapView>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _driverAnimation;
  LatLng? _currentPosition;
  LatLng? _driverPosition;
  LatLng? _driverTarget;
  LatLng? _driverStart;
  StreamSubscription<Position>? _positionStream;
  DateTime? _lastDriverLocationSent;
  LatLng? _lastDriverLocation;
  bool _mapReady = false;

  bool get _isPassenger => widget.flavor == 'passageiro';

  @override
  void initState() {
    super.initState();
    _driverAnimation =
        AnimationController(
          vsync: this,
          duration: const Duration(seconds: 5),
        )..addListener(() {
          final start = _driverStart;
          final target = _driverTarget;
          if (start == null || target == null || !mounted) return;
          setState(() {
            _driverPosition = LatLng(
              start.latitude +
                  (target.latitude - start.latitude) * _driverAnimation.value,
              start.longitude +
                  (target.longitude - start.longitude) * _driverAnimation.value,
            );
          });
        });
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

    _sendDriverLocation(initialPos);
    _moveMapToCurrentPosition();

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
          _sendDriverLocation(position);
        });
  }

  void _sendDriverLocation(Position position) {
    if (_isPassenger) return;

    final driverFlow = context.read<DriverFlowCubit>();
    if (!driverFlow.state.online) return;

    final current = LatLng(position.latitude, position.longitude);
    final elapsed = _lastDriverLocationSent == null
        ? null
        : DateTime.now().difference(_lastDriverLocationSent!);
    final movedMeters = _lastDriverLocation == null
        ? null
        : Geolocator.distanceBetween(
            _lastDriverLocation!.latitude,
            _lastDriverLocation!.longitude,
            current.latitude,
            current.longitude,
          );
    if (elapsed != null && elapsed.inSeconds < 5 && (movedMeters ?? 0) < 20) {
      return;
    }

    _lastDriverLocationSent = DateTime.now();
    _lastDriverLocation = current;
    driverFlow.sendLocation(current.latitude, current.longitude);
  }

  void _moveMapToCurrentPosition() {
    if (_mapReady && _currentPosition != null) {
      _mapController.move(_currentPosition!, 19.0);
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _driverAnimation.dispose();
    super.dispose();
  }

  void _animateDriverTo(LatLng target) {
    if (_driverTarget == target) return;
    _driverAnimation.stop();
    _driverStart = _driverPosition ?? target;
    _driverTarget = target;
    _driverPosition ??= target;
    _driverAnimation.forward(from: 0);
  }

  void _centerMapOnUser() {
    if (_currentPosition != null) {
      _moveMapToCurrentPosition();
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
                final driverLocation = ride.driverLocation;
                if (driverLocation != null) {
                  final target = LatLng(driverLocation.lat, driverLocation.lng);
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _animateDriverTo(target),
                  );
                }
                return Stack(
                  children: [
                    MapaBase(
                      initialCenter: _currentPosition!,
                      zoom: 19.0,
                      mapController: _mapController,
                      onMapReady: () {
                        _mapReady = true;
                        _moveMapToCurrentPosition();
                      },
                      onTap: _isPassenger
                          ? (point) => context
                                .read<RideFlowCubit>()
                                .chooseDestination(point)
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
                        if (ride.driverLocation != null)
                          Marker(
                            point:
                                _driverPosition ??
                                LatLng(
                                  ride.driverLocation!.lat,
                                  ride.driverLocation!.lng,
                                ),
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.amber,
                              size: 34,
                            ),
                          ),
                      ],
                    ),

                    if (!_isPassenger)
                      Positioned(
                        top: 50,
                        left: 16,
                        right: 16,
                        child: BlocBuilder<DriverFlowCubit, DriverFlowState>(
                          builder: (context, driver) => Container(
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
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    driver.online
                                        ? 'Você está online'
                                        : 'Você está offline',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Switch(
                                  value: driver.online,
                                  onChanged: (online) async {
                                    final driverFlow = context
                                        .read<DriverFlowCubit>();
                                    await driverFlow.setOnline(online);
                                    if (online &&
                                        driverFlow.state.online &&
                                        _currentPosition != null) {
                                      driverFlow.sendLocation(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (!_isPassenger)
                      BlocBuilder<DriverFlowCubit, DriverFlowState>(
                        builder: (context, driver) {
                          final offer = driver.offer;
                          if (offer == null) return const SizedBox.shrink();
                          return Positioned(
                            left: 16,
                            right: 16,
                            bottom: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Nova corrida',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      offer.passenger.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${(offer.distanceToPickupMeters / 1000).toStringAsFixed(1)} km até o embarque',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    StreamBuilder<int>(
                                      stream: Stream.periodic(
                                        const Duration(seconds: 1),
                                        (value) => value,
                                      ),
                                      builder: (context, snapshot) {
                                        final seconds = offer.expiresAt
                                            .difference(DateTime.now())
                                            .inSeconds
                                            .clamp(0, 15);
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Text(
                                            'Responda em ${seconds}s',
                                            style: const TextStyle(
                                              color: Colors.amber,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        OutlinedButton(
                                          onPressed: context
                                              .read<DriverFlowCubit>()
                                              .reject,
                                          child: const Text('Recusar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: context
                                              .read<DriverFlowCubit>()
                                              .accept,
                                          child: const Text('Aceitar'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
