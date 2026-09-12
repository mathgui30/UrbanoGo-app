import 'package:flutter/material.dart';

import 'package:urbanogo/core/theme/app_colors.dart';

class UrbanogoWordmark extends StatelessWidget {
  final double fontSize;
  final bool showDot;

  const UrbanogoWordmark({super.key, this.fontSize = 20, this.showDot = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot) ...[
          Container(
            width: fontSize * 0.42,
            height: fontSize * 0.42,
            decoration: const BoxDecoration(
              color: AppColors.sol,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: fontSize * 0.34),
        ],
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1,
            ),
            children: const [
              TextSpan(
                text: 'Urbano',
                style: TextStyle(color: AppColors.cloud),
              ),
              TextSpan(
                text: 'Go',
                style: TextStyle(color: AppColors.sol),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
