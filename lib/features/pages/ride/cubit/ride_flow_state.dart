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
  final DriverLocationModel? driverLocation;
  final DriverLocationModel? previousDriverLocation;
  final bool ratingSubmitting;
  final bool ratingSubmitted;
  final String? ratingError;

  const RideFlowState({
    this.status = RideFlowStatus.idle,
    this.destination,
    this.rideType = 'ride',
    this.quote,
    this.ride,
    this.errorMessage,
    this.driverLocation,
    this.previousDriverLocation,
    this.ratingSubmitting = false,
    this.ratingSubmitted = false,
    this.ratingError,
  });

  bool get isBusy =>
      status == RideFlowStatus.quoting || status == RideFlowStatus.requesting;

  RideFlowState copyWith({
    RideFlowStatus? status,
    LatLng? destination,
    String? rideType,
    QuoteModel? quote,
    RideModel? ride,
    String? errorMessage,
    DriverLocationModel? driverLocation,
    DriverLocationModel? previousDriverLocation,
    bool? ratingSubmitting,
    bool? ratingSubmitted,
    String? ratingError,
    bool clearQuote = false,
    bool clearError = false,
    bool clearRatingError = false,
  }) {
    return RideFlowState(
      status: status ?? this.status,
      destination: destination ?? this.destination,
      rideType: rideType ?? this.rideType,
      quote: clearQuote ? null : (quote ?? this.quote),
      ride: ride ?? this.ride,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      driverLocation: driverLocation ?? this.driverLocation,
      previousDriverLocation:
          previousDriverLocation ?? this.previousDriverLocation,
      ratingSubmitting: ratingSubmitting ?? this.ratingSubmitting,
      ratingSubmitted: ratingSubmitted ?? this.ratingSubmitted,
      ratingError: clearRatingError ? null : (ratingError ?? this.ratingError),
    );
  }
}
