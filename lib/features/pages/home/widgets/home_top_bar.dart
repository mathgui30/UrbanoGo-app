import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:urbanogo/core/models/user_model.dart';
import 'package:urbanogo/core/theme/app_colors.dart';
import 'package:urbanogo/core/util/initials.dart';
import 'package:urbanogo/features/pages/auth/cubit/auth_cubit.dart';
import 'package:urbanogo/features/pages/auth/login_page.dart';
import 'package:urbanogo/features/pages/home/widgets/profile_sheet.dart';
import 'package:urbanogo/shared_widgets/urbanogo_wordmark.dart';

class HomeTopBar extends StatelessWidget {
  final String flavor;

  const HomeTopBar({super.key, required this.flavor});

  void _openProfile(BuildContext context, UserModel user) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.slate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProfileSheet(
        user: user,
        flavor: flavor,
        onLogout: () {
          context.read<AuthCubit>().logout();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginPage(flavor: flavor)),
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.slate.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.line),
              ),
              child: const UrbanogoWordmark(fontSize: 17),
            ),
            GestureDetector(
              onTap: user == null ? null : () => _openProfile(context, user),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.slate.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sol, width: 2),
                ),
                child: Text(
                  user == null ? '' : initialsFrom(user.name),
                  style: const TextStyle(
                    color: AppColors.cloud,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
