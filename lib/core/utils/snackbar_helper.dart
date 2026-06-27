import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(_buildSnackBar(
      message: message,
      color: AppColors.error,
      icon: Icons.error_outline_rounded,
    ));
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(_buildSnackBar(
      message: message,
      color: AppColors.onTertiaryContainer,
      icon: Icons.check_circle_outline_rounded,
    ));
}

void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(_buildSnackBar(
      message: message,
      color: AppColors.secondary,
      icon: Icons.info_outline_rounded,
    ));
}

SnackBar _buildSnackBar({
  required String message,
  required Color color,
  required IconData icon,
}) {
  return SnackBar(
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 5),
    content: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.labelBold.copyWith(
              color: Colors.white,
              height: 1.4,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
