import 'dart:ui';

import 'package:ai_image_makerr/utils/reesposive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/app_color.dart';
import '../../Discover/discover.dart';
import '../../Setting/setting.dart';
import '../../my_emoji/my_emoji.dart';
import '../homescreen/home_screen.dart';

class CustomBottomBar extends StatefulWidget {
  const CustomBottomBar({Key? key}) : super(key: key);
  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  final BottomBarController _controller = Get.put(BottomBarController());

  final List<Widget> _screens = [
    const HomeScreen(),
    DiscoverScreen(),
    const MyEmojisScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ResponsiveConfig.init(context);

    return WillPopScope(
      onWillPop: () async {
        if (_controller.currentIndex.value != 0) {
          _controller.changeIndex(0);
          return false; // do NOT exit app
        }

        return true; // exit app when already on HomeScreen
      },
      child: Scaffold(
        extendBody: true,
        body: Obx(
          () => IndexedStack(
            index: _controller.currentIndex.value,
            children: _screens,
          ),
        ),
        bottomNavigationBar: Obx(() {
          final bottomPadding = MediaQuery.of(
            context,
          ).padding.bottom; // nav bar height
          return Container(
            height: 100.h + bottomPadding, //  bottom padding
            padding: EdgeInsets.only(bottom: bottomPadding), // inner padding
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.w),
                topRight: Radius.circular(20.w),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 2.w,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.w),
                topRight: Radius.circular(20.w),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem('assets/icons/home.png', 'home'.tr, 0),
                    SizedBox(width: 15.w),
                    _buildNavItem(
                      'assets/icons/discover.png',
                      'discover'.tr,
                      1,
                    ),
                    SizedBox(width: 15.w),
                    _buildNavItem(
                      'assets/icons/my_emoji.png',
                      'myEmojis'.tr,
                      2,
                    ),
                    SizedBox(width: 15.w),
                    _buildNavItem('assets/icons/setting.png', 'settings'.tr, 3),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavItem(String assetIcon, String label, int index) {
    final isSelected = _controller.currentIndex.value == index;

    return GestureDetector(
      onTap: () => _controller.changeIndex(index),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25.w),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 2.w,
                ),
              )
            : null,
        padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 12.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetIcon,
              color: isSelected
                  ? AppColors.primary
                  : Colors.black.withOpacity(0.6),
              width: 25.w,
              height: 25.h,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected
                    ? AppColors.primary
                    : Colors.black.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
