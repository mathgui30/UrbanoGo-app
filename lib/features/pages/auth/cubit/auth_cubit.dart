import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:urbanogo/core/models/user_model.dart';
import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/repositories/auth_repository.dart';
import 'package:urbanogo/core/repositories/driver_repository.dart';

part 'auth_state.dart';

const _connectionErrorMessage =
    'Não foi possível falar com o servidor. Verifique sua conexão e tente de novo.';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final DriverRepository _driverRepository;

  AuthCubit(this._authRepository, this._driverRepository)
    : super(const AuthState());

  Future<void> login({required String email, required String password}) async {
    emit(const AuthState(status: AuthStatus.submitting));
    try {
      final result = await _authRepository.login(email, password);
      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: result['user'] as UserModel,
        ),
      );
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

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: result['user'] as UserModel,
        ),
      );
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

  void logout() => emit(const AuthState());
}
