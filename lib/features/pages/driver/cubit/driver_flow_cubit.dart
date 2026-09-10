import 'dart:async';

import 'package:flutter/foundation.dart';
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
      emit(
        state.copyWith(
          ride: ride,
          clearOffer: true,
          busy: false,
          arrived: false,
          ratingSubmitting: false,
          ratingSubmitted: false,
        ),
      );
    } catch (error) {
      debugPrint('accept() falhou: $error');
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

  Future<void> arrive() async {
    final ride = state.ride;
    if (ride == null || state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await _rideRepository.arrive(ride.id);
      emit(
        state.copyWith(
          busy: false,
          arrived: true,
          ride: await _rideRepository.getRide(ride.id),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          busy: false,
          errorMessage: 'Não foi possível confirmar a chegada. Tente de novo.',
        ),
      );
    }
  }

  Future<void> startTrip() async {
    final ride = state.ride;
    if (ride == null || state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await _rideRepository.start(ride.id);
      emit(
        state.copyWith(busy: false, ride: await _rideRepository.getRide(ride.id)),
      );
    } catch (_) {
      emit(
        state.copyWith(
          busy: false,
          errorMessage: 'Não foi possível iniciar a viagem. Tente de novo.',
        ),
      );
    }
  }

  Future<void> completeTrip() async {
    final ride = state.ride;
    if (ride == null || state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await _rideRepository.complete(ride.id);
      emit(
        state.copyWith(busy: false, ride: await _rideRepository.getRide(ride.id)),
      );
    } catch (_) {
      emit(
        state.copyWith(
          busy: false,
          errorMessage: 'Não foi possível concluir a corrida. Tente de novo.',
        ),
      );
    }
  }

  Future<void> rateRide(int score, String? comment) async {
    final ride = state.ride;
    if (ride == null || state.ratingSubmitting || state.ratingSubmitted) return;
    emit(state.copyWith(ratingSubmitting: true));
    try {
      await _rideRepository.rate(ride.id, score, comment: comment);
      emit(state.copyWith(ratingSubmitting: false, ratingSubmitted: true));
    } catch (_) {
      emit(
        state.copyWith(
          ratingSubmitting: false,
          errorMessage: 'Não foi possível enviar a avaliação. Tente de novo.',
        ),
      );
    }
  }

  void finishRide() {
    final ride = state.ride;
    if (ride != null) _socket.leaveRide(ride.id);
    emit(
      state.copyWith(
        clearRide: true,
        busy: false,
        arrived: false,
        ratingSubmitting: false,
        ratingSubmitted: false,
      ),
    );
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
