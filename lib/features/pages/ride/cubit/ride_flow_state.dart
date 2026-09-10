part of 'ride_flow_cubit.dart';

enum RideFlowStatus {
  idle,
  ready,
  quoting,
  quoted,
  requesting,
  tracking,
  completed,
  cancelled,
  failure,
}

class RideFlowState {
  final RideFlowStatus status;
  final LatLng? destination;
  final String rideType;
  final QuoteModel? quote;
  final RideModel? ride;
  final String? errorMessage;

  const RideFlowState({
    this.status = RideFlowStatus.idle,
    this.destination,
    this.rideType = 'ride',
    this.quote,
    this.ride,
    this.errorMessage,
  });

  bool get isBusy =>
      status == RideFlowStatus.quoting ||
      status == RideFlowStatus.requesting;

  RideFlowState copyWith({
    RideFlowStatus? status,
    LatLng? destination,
    String? rideType,
    QuoteModel? quote,
    RideModel? ride,
    String? errorMessage,
    bool clearQuote = false,
    bool clearError = false,
  }) {
    return RideFlowState(
      status: status ?? this.status,
      destination: destination ?? this.destination,
      rideType: rideType ?? this.rideType,
      quote: clearQuote ? null : (quote ?? this.quote),
      ride: ride ?? this.ride,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
