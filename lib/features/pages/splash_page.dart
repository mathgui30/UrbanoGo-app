import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:urbanogo/core/theme/app_colors.dart';
import 'package:urbanogo/features/pages/auth/cubit/auth_cubit.dart';
import 'package:urbanogo/features/pages/auth/login_page.dart';
import 'package:urbanogo/features/pages/home_map_page.dart';
import 'package:urbanogo/shared_widgets/urbanogo_wordmark.dart';

class SplashPage extends StatefulWidget {
  final String flavor;

  const SplashPage({super.key, required this.flavor});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _route(context.read<AuthCubit>().state);
    });
  }

  void _route(AuthState state) {
    if (_routed || !mounted) return;
    Widget? next;
    if (state.status == AuthStatus.authenticated) {
      next = HomeMapPage(flavor: widget.flavor);
    } else if (state.status == AuthStatus.unauthenticated ||
        state.status == AuthStatus.failure) {
      next = LoginPage(flavor: widget.flavor);
    }
    if (next == null) return;
    _routed = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (_, state) => _route(state),
      child: const Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UrbanogoWordmark(fontSize: 34),
              SizedBox(height: 28),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
