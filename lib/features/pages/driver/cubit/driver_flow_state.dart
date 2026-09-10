part of 'driver_flow_cubit.dart';

class DriverFlowState {
  final bool online;
  final MatchingOfferModel? offer;
  final RideModel? ride;
  final String? errorMessage;
  const DriverFlowState({
    this.online = false,
    this.offer,
    this.ride,
    this.errorMessage,
  });

  DriverFlowState copyWith({
    bool? online,
    MatchingOfferModel? offer,
    RideModel? ride,
    String? errorMessage,
    bool clearOffer = false,
  }) => DriverFlowState(
    online: online ?? this.online,
    offer: clearOffer ? null : (offer ?? this.offer),
    ride: ride ?? this.ride,
    errorMessage: errorMessage,
  );
}
