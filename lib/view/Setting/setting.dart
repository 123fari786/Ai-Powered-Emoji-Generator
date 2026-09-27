import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/reesposive.dart';
import '../premiumScree/Premium.dart';
import '../rating_andriod /rating_andriod.dart';
import '../widgets/background_theme.dart';
import '../widgets/premium_check_widget.dart' hide PremiumScreen;
import 'laguages.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // RATE APP
  Future<void> rateApp(BuildContext context) async {
    final InAppReview inAppReview = InAppReview.instance;

    if (Platform.isIOS) {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing(appStoreId: 'YOUR_APP_STORE_ID');
      }
    } else if (Platform.isAndroid) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const RatingDialog(),
      ).then((rating) async {
        if (rating != null && rating >= 3) {
          await inAppReview.openStoreListing();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveConfig.init(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: BackgroundTheme.background),
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 15.w,

              right: 15.w,
              bottom: 120.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'settings'.tr,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    PremiumCheckWidget(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 3.h,
                      ),
                      iconSize: 24.w,
                      fontSize: 18.sp,
                      onProButtonTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PremiumScreen()),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // PREFERENCES
                sectionTitle('preferences'.tr),
                buildTile(
                  iconPath: 'assets/icons/language_icon.png',
                  title: 'language'.tr,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Language()),
                    );
                  },
                ),

                SizedBox(height: 10.h),

                // HELP
                sectionTitle('helpAndSupport'.tr),
                buildTile(
                  iconPath: 'assets/icons/contact_support.png',
                  title: 'contactus'.tr,
                  onPressed: () {},
                ),

                SizedBox(height: 12.h),

                buildTile(
                  iconPath: 'assets/icons/thumbs-up.png',
                  title: 'rateTheApp'.tr,
                  onPressed: () => rateApp(context),
                ),

                SizedBox(height: 10.h),

                // LEGAL
                sectionTitle('legal'.tr),
                buildTile(
                  iconPath: 'assets/icons/privacy_policy.png',
                  title: 'privacyPolicy'.tr,
                  onPressed: () {},
                ),

                SizedBox(height: 12.h),

                buildTile(
                  iconPath: 'assets/icons/term&condidition.png',
                  title: 'termsAndConditions'.tr,
                  onPressed: () {},
                ),

                SizedBox(height: 10.h),

                // SHARE
                sectionTitle('inviteFriends'.tr),
                Builder(
                  builder: (shareContext) {
                    return buildTile(
                      iconPath: 'assets/icons/share.png',
                      title: 'shareApp'.tr,
                      onPressed: () {
                        final box =
                            shareContext.findRenderObject() as RenderBox?;

                        Share.share(
                          'Hey! Check out this amazing app \n\n '
                          'https://play.google.com/store/apps/details?id=com.your.app',
                          sharePositionOrigin:
                              box!.localToGlobal(Offset.zero) & box.size,
                        );
                      },
                    );
                  },
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // SECTION TITLE
  Widget sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  // TILE WIDGET
  Widget buildTile({
    required String iconPath,
    required String title,
    required VoidCallback onPressed,
  }) {
    final isArabic = Get.locale?.languageCode == 'ar';

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24.w, height: 24.h),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
              ),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(isArabic ? 3.14159 : 0),
              child: Image.asset(
                'assets/icons/aroow.png',
                width: 18.w,
                height: 18.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
