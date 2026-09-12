import 'package:flutter/material.dart';

import 'package:urbanogo/core/models/user_model.dart';
import 'package:urbanogo/core/theme/app_colors.dart';
import 'package:urbanogo/core/util/initials.dart';

class ProfileSheet extends StatelessWidget {
  final UserModel user;
  final String flavor;
  final VoidCallback onLogout;

  const ProfileSheet({
    super.key,
    required this.user,
    required this.flavor,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.sol, width: 2),
                  ),
                  child: Text(
                    initialsFrom(user.name),
                    style: const TextStyle(
                      color: AppColors.cloud,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: AppColors.cloud,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(color: AppColors.mist),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    flavor == 'motorista'
                        ? Icons.directions_car_outlined
                        : Icons.person_outline,
                    size: 18,
                    color: AppColors.mist,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    flavor == 'motorista' ? 'Modo motorista' : 'Modo passageiro',
                    style: const TextStyle(color: AppColors.mist),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onLogout();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.line),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
