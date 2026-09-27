import 'dart:async';
import 'package:ai_image_makerr/utils/app_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controller/premium_controller.dart';
import '../Home_Screen/bottombar/bottom_bar.dart';
import '../onboarding/onboarding_screens.dart';
import '../premiumScree/Premium.dart';
import '../widgets/background_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startNavigation();

  }

  void _startNavigation() {
    Timer(const Duration(seconds: 3), () {
      final box = GetStorage();
      final premiumController = Get.find<PremiumController>();

      final bool hasSeenOnboarding = box.read('hasSeenOnboarding') ?? false;
      final bool isPremiumUser = premiumController.isPaidVersion.value;

      print("🚀 ==============APP OPEN → USER PREMIUM: $isPremiumUser");

      if (!hasSeenOnboarding) {
        box.write('hasSeenOnboarding', true);
        Get.offAll(() => OnboardingScreen());
      } else if (isPremiumUser) {
        Get.offAll(() => const CustomBottomBar());
      } else {
        Get.offAll(() => const PremiumScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: BackgroundTheme.background,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/splash_logo.png",
                height: 120,
                width: 120,
              ),
              const SizedBox(height: 20),
              Text(
                'aiEmojiMaker'.tr,
                style:  TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackFull,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}