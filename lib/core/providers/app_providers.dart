import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:urbanogo/core/network/api_client.dart';
import 'package:urbanogo/core/network/socket_service.dart';
import 'package:urbanogo/core/repositories/auth_repository.dart';
import 'package:urbanogo/core/repositories/driver_repository.dart';
import 'package:urbanogo/core/repositories/ride_repository.dart';
import 'package:urbanogo/core/repositories/user_repository.dart';
import 'package:urbanogo/core/repositories/health_repository.dart';
import 'package:urbanogo/features/pages/auth/cubit/auth_cubit.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>(create: (_) => ApiClient()),
        RepositoryProvider<SocketService>(create: (_) => SocketService()),
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>(
            create: (context) => AuthRepository(context.read<ApiClient>()),
          ),
          RepositoryProvider<DriverRepository>(
            create: (context) => DriverRepository(context.read<ApiClient>()),
          ),
          RepositoryProvider<RideRepository>(
            create: (context) => RideRepository(context.read<ApiClient>()),
          ),
          RepositoryProvider<OfferRepository>(
            create: (context) => OfferRepository(context.read<ApiClient>()),
          ),
          RepositoryProvider<UserRepository>(
            create: (context) => UserRepository(context.read<ApiClient>()),
          ),
          RepositoryProvider<HealthRepository>(
            create: (context) => HealthRepository(context.read<ApiClient>()),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>(
              create: (context) => AuthCubit(
                context.read<AuthRepository>(),
                context.read<DriverRepository>(),
              ),
            ),
          ],
          child: child,
        ),
      ),
    );
  }
}
