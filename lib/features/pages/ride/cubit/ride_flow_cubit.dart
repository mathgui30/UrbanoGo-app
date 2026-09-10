import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:urbanogo/core/models/quote_model.dart';
import 'package:urbanogo/core/models/ride_model.dart';
import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/repositories/ride_repository.dart';

part 'ride_flow_state.dart';

const _connectionErrorMessage =
    'Não foi possível falar com o servidor. Verifique sua conexão e tente de novo.';

const _terminalStatuses = {'completed', 'cancelled', 'expired'};

class RideFlowCubit extends Cubit<RideFlowState> {
  final RideRepository _rideRepository;
  Timer? _pollTimer;

  RideFlowCubit(this._rideRepository) : super(const RideFlowState());

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
        state.copyWith(
          status: RideFlowStatus.failure,
          errorMessage: e.message,
        ),
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
      _startPolling(ride.id);
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: RideFlowStatus.failure,
          errorMessage: e.message,
        ),
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
        state.copyWith(
          status: RideFlowStatus.failure,
          errorMessage: e.message,
        ),
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
    _pollTimer?.cancel();
    emit(const RideFlowState());
  }

  void _startPolling(String rideId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
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
    return super.close();
  }
}
