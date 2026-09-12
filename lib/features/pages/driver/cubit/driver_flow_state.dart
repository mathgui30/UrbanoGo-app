part of 'driver_flow_cubit.dart';

class DriverFlowState {
  final bool online;
  final MatchingOfferModel? offer;
  final RideModel? ride;
  final bool busy;
  final bool arrived;
  final bool ratingSubmitting;
  final bool ratingSubmitted;
  final String? errorMessage;
  const DriverFlowState({
    this.online = false,
    this.offer,
    this.ride,
    this.busy = false,
    this.arrived = false,
    this.ratingSubmitting = false,
    this.ratingSubmitted = false,
    this.errorMessage,
  });

  DriverFlowState copyWith({
    bool? online,
    MatchingOfferModel? offer,
    RideModel? ride,
    bool? busy,
    bool? arrived,
    bool? ratingSubmitting,
    bool? ratingSubmitted,
    String? errorMessage,
    bool clearOffer = false,
    bool clearRide = false,
  }) => DriverFlowState(
    online: online ?? this.online,
    offer: clearOffer ? null : (offer ?? this.offer),
    ride: clearRide ? null : (ride ?? this.ride),
    busy: busy ?? this.busy,
    arrived: arrived ?? this.arrived,
    ratingSubmitting: ratingSubmitting ?? this.ratingSubmitting,
    ratingSubmitted: ratingSubmitted ?? this.ratingSubmitted,
    errorMessage: errorMessage,
  );
}
