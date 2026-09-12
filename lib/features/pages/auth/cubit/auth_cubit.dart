import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:urbanogo/core/models/user_model.dart';
import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/repositories/auth_repository.dart';
import 'package:urbanogo/core/repositories/driver_repository.dart';
import 'package:urbanogo/core/storage/session_store.dart';

part 'auth_state.dart';

const _connectionErrorMessage =
    'Não foi possível falar com o servidor. Verifique sua conexão e tente de novo.';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final DriverRepository _driverRepository;
  final ApiClient _apiClient;
  final SessionStore _sessionStore;

  AuthCubit(
    this._authRepository,
    this._driverRepository,
    this._apiClient,
    this._sessionStore,
  ) : super(const AuthState());

  Future<void> restore() async {
    final token = await _sessionStore.readToken();
    if (token == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }

    _apiClient.setToken(token);
    final cached = await _sessionStore.readUser();
    if (cached != null) {
      emit(AuthState(status: AuthStatus.authenticated, user: cached));
    }

    try {
      final user = await _authRepository.getMe();
      await _sessionStore.save(token, user);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException {
      await _sessionStore.clear();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (_) {
      if (cached == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthState(status: AuthStatus.submitting));
    try {
      final result = await _authRepository.login(email, password);
      final user = result['user'] as UserModel;
      await _sessionStore.save(result['token'] as String, user);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (e) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          errorMessage: _connectionErrorMessage,
        ),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required bool isDriver,
    String? vehicleModel,
    String? vehiclePlate,
  }) async {
    emit(const AuthState(status: AuthStatus.submitting));
    try {
      final payload = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'role': isDriver ? 'driver' : 'passenger',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };
      final result = await _authRepository.register(payload);

      if (isDriver) {
        await _driverRepository.createProfile({
          'service_preference': 'rides',
          if (vehicleModel != null && vehicleModel.isNotEmpty)
            'vehicle_model': vehicleModel,
          if (vehiclePlate != null && vehiclePlate.isNotEmpty)
            'vehicle_plate': vehiclePlate,
        });
      }

      final user = result['user'] as UserModel;
      await _sessionStore.save(result['token'] as String, user);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (e) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          errorMessage: _connectionErrorMessage,
        ),
      );
    }
  }

  Future<void> logout() async {
    await _sessionStore.clear();
    _apiClient.clearToken();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
