import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:urbanogo/core/models/user_model.dart';
import 'package:urbanogo/features/pages/auth/cubit/auth_cubit.dart';
import 'package:urbanogo/features/pages/home_map_page.dart';
import 'package:urbanogo/shared_widgets/mapa_base.dart';
import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/network/socket_service.dart';
import 'package:urbanogo/core/repositories/ride_repository.dart';
import 'package:urbanogo/core/repositories/driver_repository.dart';
import 'package:urbanogo/core/models/socket_events_model.dart';
import 'package:urbanogo/core/models/matching_offer_model.dart';

class FakeApiClient extends Fake implements ApiClient {}

class FakeSocketService extends Fake implements SocketService {
  @override
  Stream<bool> get onConnectionChanged => const Stream.empty();

  @override
  Stream<DriverLocationModel> get onDriverLocation => const Stream.empty();

  @override
  Stream<RideStatusEventModel> get onRideStatus => const Stream.empty();

  @override
  Stream<MatchingOfferModel> get onMatchingOffer => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMatchingCancelled => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onError => const Stream.empty();

  @override
  void connect(String token) {}

  @override
  void disconnect() {}
}

class FakeRideRepository extends Fake implements RideRepository {}

class FakeDriverRepository extends Fake implements DriverRepository {}

class FakeOfferRepository extends Fake implements OfferRepository {}

class FakeAuthCubit extends Fake implements AuthCubit {
  @override
  final AuthState state = AuthState(
    status: AuthStatus.authenticated,
    user: UserModel.fromJson({
      'id': '123456',
      'name': 'João Testador',
      'email': 'joao@teste.com',
      'role': 'passenger',
      'created_at': '2026-09-06T22:00:00Z',
    }),
  );

  @override
  Stream<AuthState> get stream => const Stream.empty();

  @override
  bool get isClosed => false;
}

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isLocationServiceEnabled') return true;
            if (methodCall.method == 'checkPermission') return 3; // always
            if (methodCall.method == 'getCurrentPosition') {
              return {
                'latitude': -3.73,
                'longitude': -38.52,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'accuracy': 10.0,
                'altitude': 0.0,
                'heading': 0.0,
                'speed': 0.0,
                'speedAccuracy': 0.0,
              };
            }
            return null;
          },
        );
  });

  group('Testes do Mapa e Home', () {
    testWidgets('MapaBase deve renderizar o FlutterMap e o TileLayer', (
      tester,
    ) async {
      const initialCenter = LatLng(-3.73, -38.52);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MapaBase(initialCenter: initialCenter)),
        ),
      );

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets(
      'HomeMapPage deve injetar providers e construir a estrutura final',
      (tester) async {
        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ApiClient>(create: (_) => FakeApiClient()),
              RepositoryProvider<SocketService>(
                create: (_) => FakeSocketService(),
              ),
              RepositoryProvider<RideRepository>(
                create: (_) => FakeRideRepository(),
              ),
              RepositoryProvider<DriverRepository>(
                create: (_) => FakeDriverRepository(),
              ),
              RepositoryProvider<OfferRepository>(
                create: (_) => FakeOfferRepository(),
              ),
            ],
            child: BlocProvider<AuthCubit>.value(
              value: FakeAuthCubit(),
              child: const MaterialApp(home: HomeMapPage(flavor: 'passageiro')),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(MapaBase), findsOneWidget);
      },
    );
  });
}
