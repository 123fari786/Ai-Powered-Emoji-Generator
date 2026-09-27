import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ai_image_makerr/view/premiumScree/Premium.dart';
import 'package:ai_image_makerr/view/rating_andriod /rating_andriod.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../controller/premium_controller.dart';
import '../../utils/app_color.dart';
import '../../utils/reesposive.dart';
import '../Home_Screen/bottombar/bottom_bar.dart';
import '../widgets/background_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final GetStorage _storage = GetStorage();
  final InAppReview _inAppReview = InAppReview.instance;
  bool _isProcessing = false;
  bool _ratingDialogShown = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Create Emojis Instantly",
      description:
      "Turn text or images into custom emojis in\nseconds with AI.",
      centerImage: "assets/images/onboarding1.png",
      smallImage: "assets/images/onboarding111.png",
      showGeneratedBadge: true,
    ),
    OnboardingPage(
      title: "Choose Your Style",
      description:
      "Classic, 3D, cartoon, kawaii, pixel, sticker\npick any emoji style you love.",
      centerImage: "assets/images/emojis.png",
      smallImage: null,
      showGeneratedBadge: false,
    ),
    OnboardingPage(
      title: "Save & Share Easily",
      description:
      "Download your emojis or share them with\n friends instantly.",
      centerImage: "assets/images/onboarding3.png",
      smallImage: null,
      showGeneratedBadge: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ResponsiveConfig.isInitialized) {
      ResponsiveConfig.init(context);
    }
  }

  Future<void> _initApp() async {
    await GetStorage.init();

    //  Sync PremiumController with cache
    final premiumController = Get.find<PremiumController>();
    premiumController.syncPremiumStatus();

    //  Check cache for direct navigation
    _checkCacheForDirectNavigation();
  }

  Future<void> _checkCacheForDirectNavigation() async {
    try {
      //  Get PremiumController
      final premiumController = Get.find<PremiumController>();

      //  Ensure controller is synced
      premiumController.syncPremiumStatus();

      //  Check both cache AND controller
      final cachedPremium = _storage.read('isPremiumUser') ?? false;
      final hasSeenOnboarding = _storage.read('hasSeenOnboarding') ?? false;

      //  DEBUG PRINT
      print("🔍 Onboarding Cache Check:");
      print("- isPremiumUser (cache): $cachedPremium");
      print("- isPaidVersion (controller): ${premiumController.isPaidVersion.value}");
      print("- hasSeenOnboarding: $hasSeenOnboarding");

      //  Use controller value (which is synced with cache)
      if (premiumController.isPaidVersion.value && hasSeenOnboarding) {
        print(" Direct navigation to Home (Premium user)");
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Get.offAll(() => CustomBottomBar());
          }
        });
      } else {
        print("ℹ️ Showing Onboarding");
      }
    } catch (e) {
      print('❌ Error checking cache: $e');
    }
  }

  Future<void> _showRatingDialog() async {
    if (_isProcessing || _ratingDialogShown) return;

    _isProcessing = true;
    _ratingDialogShown = true;

    try {
      if (Platform.isIOS) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
        } else {
          await _inAppReview.openStoreListing(appStoreId: 'YOUR_IOS_APP_ID');
        }
      } else if (Platform.isAndroid) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const RatingDialog(),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _handleContinueAction() {
    if (_currentPage < _pages.length - 1) {
      // Continue to next page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      //  Last page
      _markOnboardingSeenAndNavigate();
    }
  }

  void _handleSkipAction() {
    //  Skip button
    _markOnboardingSeenAndNavigate();
  }

  void _markOnboardingSeenAndNavigate() {
    // Mark onboarding as seen
    _storage.write('hasSeenOnboarding', true);

    //  Sync controller first
    final premiumController = Get.find<PremiumController>();
    premiumController.syncPremiumStatus();

    //  Use controller value (synced with cache)
    if (premiumController.isPaidVersion.value) {
      //  User is already premium
      Get.offAll(() => CustomBottomBar());
    } else {
      //  User is not premium - go to purchase screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PremiumScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 17.w),
            child: GestureDetector(
              onTap: _handleSkipAction,
              child: Text(
                'skip'.tr,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: BackgroundTheme.background),
        child: Column(
          children: [
            // Main Content with PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });

                  if (index == _pages.length - 1 && !_ratingDialogShown) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showRatingDialog();
                    });
                  }
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildFirstPage(_pages[index]);
                  } else {
                    return _buildPage(_pages[index]);
                  }
                },
              ),
            ),

            // Dots Indicator
            Padding(
              padding: EdgeInsets.only(bottom: 70.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                      (index) => _dot(index == _currentPage),
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: EdgeInsets.only(
                left: 22.w,
                right: 22.w,
                bottom: 48.h,
              ),
              child: GestureDetector(
                onTap: _isProcessing ? null : _handleContinueAction,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50.w),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                    child: Container(
                      height: 55.h,
                      decoration: BoxDecoration(
                        color: _isProcessing
                            ? AppColors.primary.withOpacity(0.5)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(50.w),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.w,
                        ),
                      ),
                      child: Center(
                        child: _isProcessing
                            ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.fullwhite,
                            ),
                          ),
                        )
                            : Text(
                          _currentPage == _pages.length - 1
                              ? 'getStarted'.tr
                              : 'continue'.tr,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fullwhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstPage(OnboardingPage page) {
    final bool isTablet = ResponsiveConfig.screenWidth > 600;

    return Column(
      children: [
        SizedBox(height: 50.h),
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: isTablet ? 40.h : 20.h),
                  child: Image.asset(
                    page.centerImage,
                    fit: BoxFit.contain,
                    height: isTablet ? 300.h : 250.h,
                  ),
                ),
              ),

              Positioned(
                bottom: isTablet ? 70.h : 80.h,
                left: 10,
                right: 10,
                child: Center(
                  child: SizedBox(
                    width: isTablet ? 400.w : 350.w,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 25.h : 20.h,
                            horizontal: isTablet ? 25.w : 25.w,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.fullwhite,
                              width: 1.2.w,
                            ),
                            borderRadius: BorderRadius.circular(20.w),
                            color: Colors.transparent,
                          ),
                          child: Text(
                            'smilingFaceEmojiWithSmilingEyesFacingRight'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 18.sp : 16.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blackFull,
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: isTablet ? -30.h : -25.h,
                          left: 0,
                          right: 0,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isTablet ? 12.h : 10.h,
                                    horizontal: isTablet ? 45.w : 40.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20.w),
                                  ),
                                  child: Text(
                                    'generate'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet ? 18.sp : 16.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.fullwhite,
                                    ),
                                  ),
                                ),
                              ),

                              if (page.smallImage != null)
                                Positioned(
                                  top: isTablet ? -0.h : -10.h,
                                  right: isTablet ? 100.w : 65.w,
                                  child: Image.asset(
                                    page.smallImage!,
                                    width: isTablet ? 130.w : 60.w,
                                    height: isTablet ? 100.h : 90.h,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                page.title,
                style: TextStyle(
                  fontSize: isTablet ? 32.sp : 30.sp,
                  fontWeight: FontWeight.w600,
                  color:AppColors.blackFull,
                ),
              ),
              SizedBox(height: isTablet ? 8.h : 5.h),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 50.w : 40.w,
                ),
                child: Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 16.sp : 14.sp,
                    height: 1.2,
                    color: AppColors.black30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Column(
      children: [
        SizedBox(height: 70.h),
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(page.centerImage, fit: BoxFit.contain),
              ),
              if (page.showGeneratedBadge)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 40.w),
                        padding: EdgeInsets.symmetric(
                          vertical: 20.h,
                          horizontal: 20.w,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.fullwhite,
                            width: 1.w,
                          ),
                          borderRadius: BorderRadius.circular(20.w),
                          color: Colors.transparent,
                        ),
                        child: Text(
                          'smilingFaceEmojiWithSmilingEyesFacingRight'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color:AppColors.blackFull,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -25.h,
                        left: 0,
                        right: 0,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                  horizontal: 40.w,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20.w),
                                ),
                                child: Text(
                                  'generated'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.fullwhite,
                                  ),
                                ),
                              ),
                            ),
                            if (page.smallImage != null)
                              Positioned(
                                top: 0,
                                right: 55.w,
                                child: Image.asset(
                                  page.smallImage!,
                                  width: 90.w,
                                  height: 90.h,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                page.title,
                style: TextStyle(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackFull,
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.4,
                    color: AppColors.black30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      width: active ? 22.w : 7.w,
      height: 6.h,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.primary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30.w),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String centerImage;
  final String? smallImage;
  final bool showGeneratedBadge;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.centerImage,
    this.smallImage,
    required this.showGeneratedBadge,
  });
}