import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:urbanogo/core/repositories/ride_repository.dart';
import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/network/socket_service.dart';
import 'package:urbanogo/core/models/matching_offer_model.dart';
import 'package:urbanogo/core/repositories/driver_repository.dart';
import 'package:urbanogo/core/theme/app_colors.dart';
import 'package:urbanogo/features/pages/driver/cubit/driver_flow_cubit.dart';
import 'package:urbanogo/features/pages/home/widgets/home_top_bar.dart';
import 'package:urbanogo/features/pages/ride/cubit/ride_flow_cubit.dart';
import 'package:urbanogo/features/pages/ride/widgets/ride_request_sheet.dart';
import 'package:urbanogo/features/pages/ride/widgets/rating_form.dart';
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

  Widget _driverBottomPanel(BuildContext context, DriverFlowState driver) {
    final ride = driver.ride;
    final hasRide = ride != null &&
        ride.status != 'cancelled' &&
        ride.status != 'expired';
    if (hasRide) return _driverRideContent(context, driver);
    if (driver.offer != null) return _offerContent(context, driver.offer!);
    return const SizedBox.shrink();
  }

  Widget _offerContent(BuildContext context, MatchingOfferModel offer) {
    final cubit = context.read<DriverFlowCubit>();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nova corrida', style: TextStyle(color: AppColors.mist)),
            const SizedBox(height: 2),
            Text(
              offer.passenger.name,
              style: const TextStyle(
                color: AppColors.cloud,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(offer.distanceToPickupMeters / 1000).toStringAsFixed(1)} km até o embarque',
              style: const TextStyle(color: AppColors.mist),
            ),
            _OfferCountdown(expiresAt: offer.expiresAt),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: cubit.reject,
                  child: const Text('Recusar'),
                ),
                ElevatedButton(
                  onPressed: cubit.accept,
                  child: const Text('Aceitar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _driverRideContent(BuildContext context, DriverFlowState driver) {
    final ride = driver.ride!;
    final cubit = context.read<DriverFlowCubit>();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ride.status == 'completed'
            ? RatingForm(
                  key: const ValueKey('driver-rating'),
                  title: 'Como foi a corrida?',
                  subtitle: 'Avalie ${ride.passenger.name}',
                  submitting: driver.ratingSubmitting,
                  submitted: driver.ratingSubmitted,
                  errorMessage: driver.errorMessage,
                  onSubmit: cubit.rateRide,
                  onDone: cubit.finishRide,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _driverRideLabel(driver),
                      style: const TextStyle(
                        color: AppColors.cloud,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride.passenger.name,
                      style: const TextStyle(color: AppColors.mist),
                    ),
                    if (driver.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        driver.errorMessage!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _driverRideAction(driver, cubit),
                  ],
                ),
      ),
    );
  }

  String _driverRideLabel(DriverFlowState driver) {
    if (driver.ride?.status == 'in_progress') return 'Em viagem';
    if (driver.arrived) return 'No local de embarque';
    return 'A caminho do embarque';
  }

  Widget _driverRideAction(DriverFlowState driver, DriverFlowCubit cubit) {
    final String label;
    final VoidCallback? onPressed;
    if (driver.ride?.status == 'in_progress') {
      label = 'Concluir corrida';
      onPressed = driver.busy ? null : cubit.completeTrip;
    } else if (driver.arrived) {
      label = 'Iniciar viagem';
      onPressed = driver.busy ? null : cubit.startTrip;
    } else {
      label = 'Cheguei ao local';
      onPressed = driver.busy ? null : cubit.arrive;
    }
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        child: driver.busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.ink,
                ),
              )
            : Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: _currentPosition == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Buscando sua localização...',
                    style: TextStyle(color: AppColors.mist, fontSize: 16),
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
                            color: AppColors.pickup,
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
                              color: AppColors.destination,
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
                              color: AppColors.driver,
                              size: 34,
                            ),
                          ),
                      ],
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.ink.withValues(alpha: 0.88),
                                AppColors.ink.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: HomeTopBar(flavor: widget.flavor),
                    ),

                    if (!_isPassenger)
                      Positioned(
                        top: 96,
                        left: 16,
                        right: 16,
                        child: BlocBuilder<DriverFlowCubit, DriverFlowState>(
                          builder: (context, driver) => Container(
                            padding: const EdgeInsets.only(left: 18, right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.slate.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: driver.online
                                        ? AppColors.driver
                                        : AppColors.mist,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    driver.online
                                        ? 'Você está online'
                                        : 'Você está offline',
                                    style: const TextStyle(
                                      color: AppColors.cloud,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: driver.online,
                                  activeTrackColor: AppColors.sol,
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
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 30,
                        child: BlocBuilder<DriverFlowCubit, DriverFlowState>(
                          builder: (context, driver) =>
                              _driverBottomPanel(context, driver),
                        ),
                      ),
                    Positioned(
                      bottom: _isPassenger ? 312 : 30,
                      right: 16,
                      child: FloatingActionButton(
                        heroTag: 'recenter',
                        backgroundColor: AppColors.slate,
                        foregroundColor: AppColors.cloud,
                        elevation: 0,
                        shape: const CircleBorder(
                          side: BorderSide(color: AppColors.line),
                        ),
                        onPressed: _centerMapOnUser,
                        child: const Icon(Icons.gps_fixed),
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

class _OfferCountdown extends StatefulWidget {
  final DateTime expiresAt;

  const _OfferCountdown({required this.expiresAt});

  @override
  State<_OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<_OfferCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = widget.expiresAt
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Responda em ${seconds}s',
        style: const TextStyle(
          color: AppColors.sol,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
