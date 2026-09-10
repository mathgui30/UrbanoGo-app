import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:urbanogo/core/models/quote_model.dart';
import 'package:urbanogo/core/models/ride_model.dart';
import 'package:urbanogo/core/models/socket_events_model.dart';
import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/network/socket_service.dart';
import 'package:urbanogo/core/repositories/ride_repository.dart';

part 'ride_flow_state.dart';

const _connectionErrorMessage =
    'Não foi possível falar com o servidor. Verifique sua conexão e tente de novo.';

const _terminalStatuses = {'completed', 'cancelled', 'expired'};

class RideFlowCubit extends Cubit<RideFlowState> {
  final RideRepository _rideRepository;
  final SocketService _socketService;
  final ApiClient _apiClient;
  Timer? _pollTimer;
  StreamSubscription<DriverLocationModel>? _locationSubscription;
  StreamSubscription<RideStatusEventModel>? _statusSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  RideFlowCubit(this._rideRepository, this._socketService, this._apiClient)
    : super(const RideFlowState()) {
    _locationSubscription = _socketService.onDriverLocation.listen(
      _onDriverLocation,
    );
    _statusSubscription = _socketService.onRideStatus.listen(_onRideStatus);
    _connectionSubscription = _socketService.onConnectionChanged.listen(
      _onConnectionChanged,
    );
  }

  bool get _locked =>
      state.status == RideFlowStatus.requesting ||
      state.status == RideFlowStatus.tracking;

  void chooseDestination(LatLng destination) {
    if (_locked) return;
    emit(
      state.copyWith(
        status: RideFlowStatus.ready,
        destination: destination,
        clearQuote: true,
        clearError: true,
      ),
    );
  }

  void setType(String type) {
    if (_locked) return;
    emit(
      state.copyWith(
        rideType: type,
        clearQuote: true,
        clearError: true,
        status: state.destination == null
            ? RideFlowStatus.idle
            : RideFlowStatus.ready,
      ),
    );
  }

  Future<void> getQuote(LatLng origin) async {
    final destination = state.destination;
    if (destination == null || _locked) return;

    emit(state.copyWith(status: RideFlowStatus.quoting, clearError: true));
    try {
      final data = await _rideRepository.getQuote({
        'type': state.rideType,
        'origin': {'lat': origin.latitude, 'lng': origin.longitude},
        'destination': {
          'lat': destination.latitude,
          'lng': destination.longitude,
        },
      });
      emit(
        state.copyWith(
          status: RideFlowStatus.quoted,
          quote: QuoteModel.fromJson(data),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: RideFlowStatus.failure, errorMessage: e.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RideFlowStatus.failure,
          errorMessage: _connectionErrorMessage,
        ),
      );
    }
  }

  Future<void> requestRide(LatLng origin) async {
    final destination = state.destination;
    if (destination == null || _locked) return;

    emit(state.copyWith(status: RideFlowStatus.requesting, clearError: true));
    try {
      final ride = await _rideRepository.createRide({
        'type': state.rideType,
        'origin': {'lat': origin.latitude, 'lng': origin.longitude},
        'destination': {
          'lat': destination.latitude,
          'lng': destination.longitude,
        },
      });
      emit(state.copyWith(status: RideFlowStatus.tracking, ride: ride));
      _connectToRide(ride.id);
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: RideFlowStatus.failure, errorMessage: e.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RideFlowStatus.failure,
          errorMessage: _connectionErrorMessage,
        ),
      );
    }
  }

  Future<void> cancelRide() async {
    final ride = state.ride;
    if (ride == null) return;
    _pollTimer?.cancel();
    try {
      final cancelled = await _rideRepository.cancelRide(
        ride.id,
        reason: 'Cancelada pelo passageiro',
      );
      emit(state.copyWith(status: RideFlowStatus.cancelled, ride: cancelled));
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: RideFlowStatus.failure, errorMessage: e.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RideFlowStatus.failure,
          errorMessage: _connectionErrorMessage,
        ),
      );
    }
  }

  void reset() {
    if (state.ride != null) _socketService.leaveRide(state.ride!.id);
    _pollTimer?.cancel();
    emit(const RideFlowState());
  }

  void _connectToRide(String rideId) {
    final token = _apiClient.token;
    if (token == null) {
      _startPolling(rideId);
      return;
    }
    _socketService.connect(token);
    _startPolling(rideId);
  }

  void _onConnectionChanged(bool connected) {
    final ride = state.ride;
    if (ride == null) return;
    if (connected) {
      _socketService.joinRide(ride.id);
      _pollTimer?.cancel();
      _poll(ride.id);
    } else {
      _startPolling(ride.id);
    }
  }

  void _onDriverLocation(DriverLocationModel location) {
    if (location.rideId != state.ride?.id) return;
    emit(
      state.copyWith(
        previousDriverLocation: state.driverLocation,
        driverLocation: location,
      ),
    );
  }

  void _onRideStatus(RideStatusEventModel event) {
    if (event.rideId != state.ride?.id) return;
    _poll(event.rideId);
  }

  void _startPolling(String rideId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _poll(rideId),
    );
  }

  Future<void> _poll(String rideId) async {
    try {
      final ride = await _rideRepository.getRide(rideId);
      if (_terminalStatuses.contains(ride.status)) {
        _pollTimer?.cancel();
        emit(
          state.copyWith(
            status: ride.status == 'completed'
                ? RideFlowStatus.completed
                : RideFlowStatus.cancelled,
            ride: ride,
          ),
        );
      } else {
        emit(state.copyWith(status: RideFlowStatus.tracking, ride: ride));
      }
    } catch (_) {
      return;
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    _connectionSubscription?.cancel();
    return super.close();
  }
}
