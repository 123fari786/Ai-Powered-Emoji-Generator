import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../controller/premium_controller.dart';
import '../../utils/app_color.dart';
import '../../utils/reesposive.dart';
import '../premiumScree/Premium.dart';

class PremiumCheckWidget extends StatelessWidget {
  PremiumCheckWidget({
    super.key,
    this.proButton,
    this.onProButtonTap,
    this.iconSize,
    this.fontSize,
    this.padding,
  });

  final Widget? proButton;
  final VoidCallback? onProButtonTap;
  final double? iconSize;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  final PremiumController _controller = Get.find<PremiumController>();
  final GetStorage _storage = GetStorage();

  @override
  Widget build(BuildContext context) {
    // ✅ Get current premium status from CACHE (most reliable)
    final cachePremium = _storage.read('isPremiumUser') ?? false;

    // ✅ Sync controller with cache
    if (cachePremium != _controller.isPaidVersion.value) {
      _controller.isPaidVersion.value = cachePremium;
      _controller.update();
    }

    print("🔍 PremiumCheckWidget Status:");
    print("- Cache Premium: $cachePremium");
    print("- Controller Premium: ${_controller.isPaidVersion.value}");

    // ✅ If premium, hide the widget
    if (cachePremium) {
      print("✅ Hiding Pro button (User is premium)");
      return const SizedBox.shrink();
    }

    print("✅ Showing Pro button (User is not premium)");
    return GestureDetector(
      onTap: onProButtonTap ?? () => Get.to(() => const PremiumScreen()),
      child: proButton ?? _defaultProButton(),
    );
  }

  Widget _defaultProButton() {
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: 4.h,
          ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/pro.png',
            width: iconSize ?? 22.w,
            height: iconSize ?? 22.h,
          ),
          SizedBox(width: 6.w),
          Text(
            'Pro',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize ?? 16.sp,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}