import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:urbanogo/core/models/user_model.dart';
import 'package:urbanogo/core/models/driver_model.dart';
import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/repositories/auth_repository.dart';
import 'package:urbanogo/core/repositories/driver_repository.dart';
import 'package:urbanogo/core/storage/session_store.dart';
import 'package:urbanogo/features/pages/auth/cubit/auth_cubit.dart';
import 'package:urbanogo/features/pages/auth/login_page.dart';

class MockAuthRepository extends Fake implements AuthRepository {
  bool failWithApiException = false;
  bool failWithGenericException = false;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (failWithApiException) {
      throw ApiException(401, 'Credenciais inválidas');
    }
    if (failWithGenericException) {
      throw Exception('Falha de rede');
    }
    return {
      'token': 'jwt_fake_token',
      'user': UserModel.fromJson({
        'id': 'uuid-1234',
        'name': 'João Testador',
        'email': email,
        'phone': '+5585999990000',
        'role': 'passenger',
        'created_at': '2026-09-06T22:00:00Z',
      }),
    };
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return {
      'token': 'jwt_fake_token',
      'user': UserModel.fromJson({
        'id': 'uuid-1234',
        'name': data['name'],
        'email': data['email'],
        'phone': data['phone'] ?? '+5585999990000',
        'role': data['role'],
        'created_at': '2026-09-06T22:00:00Z',
      }),
    };
  }
}

class MockDriverRepository extends Fake implements DriverRepository {
  bool profileCreated = false;

  @override
  Future<DriverModel> createProfile(Map<String, dynamic> data) async {
    profileCreated = true;
    return DriverModel.fromJson({
      'id': 'driver-uuid',
      'user_id': 'uuid-1234',
      'service_preference': data['service_preference'] ?? 'rides',
      'is_online': false,
      'vehicle_model': 'Onix',
      'vehicle_plate': 'ABC1D23',
      'created_at': '2026-09-06T22:00:00Z',
    });
  }
}

class MockApiClient extends Fake implements ApiClient {
  String? currentToken;
  @override
  void setToken(String token) => currentToken = token;
  @override
  void clearToken() => currentToken = null;
}

class MockSessionStore extends Fake implements SessionStore {
  String? storedToken;
  UserModel? storedUser;

  @override
  Future<void> save(String token, UserModel user) async {
    storedToken = token;
    storedUser = user;
  }

  @override
  Future<String?> readToken() async => storedToken;
  @override
  Future<UserModel?> readUser() async => storedUser;
  @override
  Future<void> clear() async {
    storedToken = null;
    storedUser = null;
  }
}

void main() {
  group('AuthCubit Unit Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockDriverRepository mockDriverRepository;
    late MockApiClient mockApiClient;
    late MockSessionStore mockSessionStore;
    late AuthCubit authCubit;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockDriverRepository = MockDriverRepository();
      mockApiClient = MockApiClient();
      mockSessionStore = MockSessionStore();
      authCubit = AuthCubit(
        mockAuthRepository,
        mockDriverRepository,
        mockApiClient,
        mockSessionStore,
      );
    });

    tearDown(() {
      authCubit.close();
    });

    test('Estado inicial deve ser initial', () {
      expect(authCubit.state.status, AuthStatus.initial);
    });

    test(
      'Login com sucesso deve persistir dados e emitir authenticated',
      () async {
        await authCubit.login(email: 'teste@exemplo.com', password: 'secret');

        expect(authCubit.state.status, AuthStatus.authenticated);
        expect(authCubit.state.user?.email, 'teste@exemplo.com');
        expect(mockSessionStore.storedToken, 'jwt_fake_token');
      },
    );

    test(
      'Login com ApiException deve emitir failure com a mensagem da API',
      () async {
        mockAuthRepository.failWithApiException = true;

        await authCubit.login(email: 'teste@exemplo.com', password: 'wrong');

        expect(authCubit.state.status, AuthStatus.failure);
        expect(authCubit.state.errorMessage, 'Credenciais inválidas');
      },
    );

    test(
      'Registro de motorista deve acionar DriverRepository.createProfile',
      () async {
        await authCubit.register(
          name: 'Condutor',
          email: 'driver@exemplo.com',
          password: 'password',
          isDriver: true,
          vehicleModel: 'Corolla',
          vehiclePlate: 'ABC1D23',
        );

        expect(mockDriverRepository.profileCreated, isTrue);
        expect(authCubit.state.status, AuthStatus.authenticated);
      },
    );
  });

  group('LoginPage Widget Tests', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit(
        MockAuthRepository(),
        MockDriverRepository(),
        MockApiClient(),
        MockSessionStore(),
      );
    });

    tearDown(() {
      authCubit.close();
    });

    Widget createWidgetUnderTest(String flavor) {
      return MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: LoginPage(flavor: flavor),
        ),
      );
    }

    testWidgets('Exibe SnackBar se submeter com campos vazios', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest('passageiro'));

      final btnFinder = find.widgetWithText(ElevatedButton, 'Entrar');

      await tester.ensureVisible(btnFinder);
      await tester.tap(btnFinder);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Informe email e senha.'), findsOneWidget);
    });

    testWidgets('Submissão preenchida dispara login e exibe loading', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest('passageiro'));

      await tester.enterText(find.byType(TextField).at(0), 'user@teste.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');

      final btnFinder = find.widgetWithText(ElevatedButton, 'Entrar');

      await tester.ensureVisible(btnFinder);
      await tester.tap(btnFinder);

      await tester.pump();

      expect(authCubit.state.status, AuthStatus.submitting);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));

      await tester.pump();
    });
  });
}
