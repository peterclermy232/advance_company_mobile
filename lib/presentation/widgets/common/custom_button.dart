import 'package:flutter/material.dart';
import '../../../config/theme_config.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Renders the brand blue→indigo gradient instead of a flat fill —
  /// reserved for primary hero CTAs (auth submit buttons), mirroring the
  /// web app's `bg-gradient-to-r from-blue-600 to-indigo-600` submit button.
  final bool gradient;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : child,
      );
    }

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            gradient ? Colors.transparent : backgroundColor,
        foregroundColor: gradient ? Colors.white : foregroundColor,
        shadowColor: gradient ? Colors.transparent : null,
        elevation: gradient ? 0 : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: gradient ? Colors.white : null,
              ),
            )
          : child,
    );

    if (!gradient) return button;

    final isDisabled = isLoading || onPressed == null;
    return Container(
      decoration: BoxDecoration(
        gradient: isDisabled ? null : AppColors.brandGradient,
        color: isDisabled ? AppColors.border : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: button,
    );
  }
}
