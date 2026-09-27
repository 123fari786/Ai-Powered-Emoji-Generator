import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_image_makerr/utils/reesposive.dart';
import 'package:ai_image_makerr/utils/app_color.dart';
import 'package:ai_image_makerr/controller/premium_controller.dart';
import '../Home_Screen/bottombar/bottom_bar.dart';
import '../widgets/background_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PremiumController _controller = Get.find<PremiumController>();

  @override
  void initState() {
    super.initState();
    //  Sync controller with cache on screen open
    _controller.syncPremiumStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ResponsiveConfig.isInitialized) {
      ResponsiveConfig.init(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Get.offAll(() => CustomBottomBar());
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(gradient: BackgroundTheme.background),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 13.w),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildUI(),
                  ),
                ),
              ),
            ),
          ),

          // LOADER
          Obx(() {
            if (!_controller.purchasePending.value)
              return const SizedBox.shrink();
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'processing'.tr,
                        style: const TextStyle(
                          color: AppColors.fullwhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // UI
  Widget _buildUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// CLOSE BUTTON
        Row(
          children: [
            GestureDetector(
              onTap: () => Get.offAll(() => CustomBottomBar()),
              child: Container(
                height: 30.h,
                width: 30.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 20.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // BANNER IMAGE
        Image.asset("assets/images/pro_banner.png", height: 140.h),

        SizedBox(height: 10.h),
        Text(
          'upgradeToPremium'.tr,
          style: TextStyle(fontSize: 27.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5.h),
        Text(
          'enjoyUnlimitedEmojiCreationsAndExclusiveFeatures'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp, color: AppColors.grey),
        ),

        SizedBox(height: 12.h),

        /// FEATURES ROW
        Row(
          children: [
            Expanded(child: _feature('unlimitedEmojiGeneration'.tr)),
            SizedBox(width: 12.w),
            Expanded(child: _feature('highQualityConversions'.tr)),
          ],
        ),

        SizedBox(height: 6.h),
        _centeredFeature('noAdvertisements'.tr),

        SizedBox(height: 12.h),

        /// TOGGLE (Annual / Weekly)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(15.w),
          ),
          child: Row(
            children: [
              Text(
                'startFreeTrial'.tr,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp),
              ),
              const Spacer(),
              Obx(
                    () => _buildToggle(
                  value: _controller.selectedPlan.value == 'Annual',
                  onTap: () {
                    _controller.selectedPlan.value =
                    _controller.selectedPlan.value == 'Annual'
                        ? 'Weekly'
                        : 'Annual';
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10.h),

        /// WEEKLY PLAN
        Obx(
              () => _planCard(
            title: 'weekly'.tr,
            subtitle: 'bestValue'.tr,
            price: _controller.weeklyPrice.value.isEmpty
                ? '--'
                : _controller.weeklyPrice.value,
            isSelected: _controller.selectedPlan.value == 'Weekly',
            onTap: () => _controller.selectPlan('Weekly'),
          ),
        ),

        SizedBox(height: 6.h),

        /// ANNUAL PLAN
        Obx(
              () => _planCard(
            title: 'yearly'.tr,
            subtitle: 'bestValue'.tr,
            price: _controller.yearlyPrice.value.isEmpty
                ? '--'
                : _controller.yearlyPrice.value,
            isSelected: _controller.selectedPlan.value == 'Annual',
            showTrialBadge: true,
            onTap: () => _controller.selectPlan('Annual'),
          ),
        ),

        SizedBox(height: 10.h),

        /// FREE TRIAL INFO
        Obx(() {
          if (_controller.selectedPlan.value != 'Annual')
            return const SizedBox.shrink();
          return Text(
            '${'trial_info'.tr} ${_controller.yearlyPrice.value}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: Colors.black54),
          );
        }),

        SizedBox(height: 15.h),

        /// CONTINUE BUTTON
        Obx(() {
          return GestureDetector(
            onTap:
            _controller.purchasePending.value ||
                _controller.products.isEmpty
                ? () {}
                : () {
              //  SYNC FIRST
              _controller.syncPremiumStatus();

              // If already premium, go to home
              if (_controller.isPaidVersion.value) {
                Get.offAll(() => CustomBottomBar());
                return;
              }

              final plan = _controller.selectedPlan.value;
              final int subId = plan == 'Annual' ? 1 : 0;
              _controller.buySubID(subId);
            },
            child: Container(
              height: 50.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30.w),
              ),
              child: Center(
                child: Text(
                  _controller.purchasePending.value
                      ? 'Processing...'.tr
                      : 'continue'.tr,
                  style: TextStyle(
                    color: AppColors.fullwhite,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),

        SizedBox(height: 12.h),

        // FOOTER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(child: Text('privacy'.tr)),

            // Restore button - Manual restore only
            GestureDetector(
              onTap: _controller.purchasePending.value
                  ? null
                  : () {
                // MANUAL RESTORE
                _controller.iapHelperGetSubscriptionHistory();
              },
              child: Text(
                'restore'.tr,
                style: TextStyle(
                  color: _controller.purchasePending.value ? Colors.grey : null,
                ),
              ),
            ),

            GestureDetector(child: Text('terms'.tr)),
          ],
        ),

        SizedBox(height: 20.h),
      ],
    );
  }

  // ================= WIDGETS =================

  Widget _planCard({
    required String title,
    required String subtitle,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
    bool showTrialBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20.w),
              border: isSelected
                  ? Border.all(color: AppColors.fullwhite, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.fullwhite : AppColors.blackFull,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isSelected ? Colors.white70 : AppColors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.fullwhite : AppColors.blackFull,
                  ),
                ),
              ],
            ),
          ),
          if (showTrialBadge)
            Positioned(
              right: 14.w,
              top: -8.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.fullwhite,
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Text(
                  'threeDaysFreeTrial'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggle({required bool value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 65.w,
        height: 28.h,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20.w),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 35.w,
            height: 22.h,
            decoration: const BoxDecoration(
              color: AppColors.fullwhite,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _feature(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(28.w),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 20.sp),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centeredFeature(String text) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(28.w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 5.w),
            Text(
              text,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}