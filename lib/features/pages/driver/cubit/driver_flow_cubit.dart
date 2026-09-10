import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:urbanogo/core/models/matching_offer_model.dart';
import 'package:urbanogo/core/models/ride_model.dart';
import 'package:urbanogo/core/models/socket_events_model.dart';
import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/network/socket_service.dart';
import 'package:urbanogo/core/repositories/driver_repository.dart';
import 'package:urbanogo/core/repositories/ride_repository.dart';

part 'driver_flow_state.dart';

class DriverFlowCubit extends Cubit<DriverFlowState> {
  DriverFlowCubit(
    this._driverRepository,
    this._offerRepository,
    this._rideRepository,
    this._socket,
    this._api,
  ) : super(const DriverFlowState()) {
    _offerSubscription = _socket.onMatchingOffer.listen(_showOffer);
    _statusSubscription = _socket.onRideStatus.listen(_onStatus);
    _connectionSubscription = _socket.onConnectionChanged.listen(
      _onConnectionChanged,
    );
  }

  final DriverRepository _driverRepository;
  final OfferRepository _offerRepository;
  final RideRepository _rideRepository;
  final SocketService _socket;
  final ApiClient _api;
  StreamSubscription<MatchingOfferModel>? _offerSubscription;
  StreamSubscription<RideStatusEventModel>? _statusSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _offerTimer;
  DriverLocationModel? _lastLocation;

  Future<void> setOnline(bool online) async {
    try {
      await _driverRepository.updateAvailability(online);
      if (online && _api.token != null) _socket.connect(_api.token!);
      if (!online) _socket.disconnect();
      emit(state.copyWith(online: online, clearOffer: !online));
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'Não foi possível atualizar sua disponibilidade.',
        ),
      );
    }
  }

  Future<void> accept() async {
    final offer = state.offer;
    if (offer == null) return;
    try {
      final ride = await _offerRepository.acceptOffer(offer.offerId);
      _offerTimer?.cancel();
      _socket.joinRide(ride.id);
      emit(state.copyWith(ride: ride, clearOffer: true));
    } catch (_) {
      emit(
        state.copyWith(
          clearOffer: true,
          errorMessage:
              'Não foi possível aceitar esta corrida. Tente novamente.',
        ),
      );
    }
  }

  Future<void> reject() async {
    final offer = state.offer;
    if (offer == null) return;
    try {
      await _offerRepository.rejectOffer(offer.offerId);
      _offerTimer?.cancel();
      emit(state.copyWith(clearOffer: true));
    } catch (_) {
      emit(
        state.copyWith(
          clearOffer: true,
          errorMessage:
              'Não foi possível recusar esta corrida. Tente novamente.',
        ),
      );
    }
  }

  void _showOffer(MatchingOfferModel offer) {
    _offerTimer?.cancel();
    emit(state.copyWith(offer: offer));
    final duration = offer.expiresAt.difference(DateTime.now());
    _offerTimer = Timer(duration.isNegative ? Duration.zero : duration, () {
      if (state.offer?.offerId == offer.offerId) {
        emit(state.copyWith(clearOffer: true));
      }
    });
  }

  void sendLocation(double lat, double lng) {
    if (!state.online) return;
    _lastLocation = DriverLocationModel(
      lat: lat,
      lng: lng,
      recordedAt: DateTime.now(),
    );
    _socket.sendDriverLocation(_lastLocation!);
  }

  void _onConnectionChanged(bool connected) {
    if (connected && state.online && _lastLocation != null) {
      _socket.sendDriverLocation(_lastLocation!);
    }
  }

  Future<void> _onStatus(RideStatusEventModel event) async {
    if (event.rideId != state.ride?.id) return;
    try {
      emit(state.copyWith(ride: await _rideRepository.getRide(event.rideId)));
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'Não foi possível atualizar o status da corrida.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _offerSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _offerTimer?.cancel();
    return super.close();
  }
}
