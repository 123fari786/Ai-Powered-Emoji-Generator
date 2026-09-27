import 'dart:io';

import 'package:ai_image_makerr/utils/reesposive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_color.dart'; // AppColors.primary

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int selectedRating = 4;
  String feedback = '';

  final List<Map<String, String>> ratings = [
    {
      'emoji': 'assets/emojis/worst.png',
      'label': 'Worst'.tr,
      'title': 'Worst_Title'.tr,
      'description': 'Worst_Description'.tr,
    },
    {
      'emoji': 'assets/emojis/poor.png',
      'label': 'Poor'.tr,
      'title': 'Poor_Title'.tr,
      'description': 'Poor_Description'.tr,
    },
    {
      'emoji': 'assets/emojis/average.png',
      'label': 'Average'.tr,
      'title': 'Average_Title'.tr,
      'description': 'Average_Description'.tr,
    },
    {
      'emoji': 'assets/emojis/good.png',
      'label': 'Good'.tr,
      'title': 'Good_Title'.tr,
      'description': 'Good_Description'.tr,
    },
    {
      'emoji': 'assets/emojis/super.png',
      'label': 'Super'.tr,
      'title': 'Super_Title'.tr,
      'description': 'Super_Description'.tr,
    },
  ];

  void _selectRating(int index) {
    setState(() => selectedRating = index);
  }

  Future<void> _sendSupportEmail() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceName = '';
      String platform = '';
      String osVersion = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        platform = 'Android';
        deviceName = androidInfo.model ?? 'Unknown Android';
        osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        platform = 'iOS';
        deviceName = iosInfo.model ?? 'iPhone';
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }

      final subject = '$appName - $platform - $appVersion';
      final ratingText = 'Rating: ${selectedRating + 1}/5\n';
      final body =
          '''
${feedback.isNotEmpty ? 'Feedback: $feedback\n' : ''}$ratingText
Device: $deviceName
OS Version: $osVersion
App Version: $appVersion
Build Number: $appVersion ($buildNumber)

Please describe your issue here:
''';

      final Uri emailLaunchUri = Uri.parse(
        'mailto:apps@appsbrains.co?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      if (!await launchUrl(emailLaunchUri)) {
        if (kDebugMode) print('Could not launch email app.');
      }
    } catch (e) {
      if (kDebugMode) print('Error opening support email: $e');
    }
  }

  Future<void> _openPlayStore() async {
    const String packageName =
        'com.app.image_to_sticker'; // replace with your package
    final Uri url = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _requestAppRating() async {
    try {
      final inAppReview = InAppReview.instance;
      if (Platform.isIOS) {
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        } else {
          await inAppReview.openStoreListing(appStoreId: 'YOUR_IOS_APP_ID');
        }
      } else if (Platform.isAndroid) {
        Get.dialog(this.widget); // Show custom dialog
      }
    } catch (e) {
      if (kDebugMode) print('Error opening app rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.fullwhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFF1F1F1),
                  child: Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Emojis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                ratings.length,
                (index) => GestureDetector(
                  onTap: () => _selectRating(index),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: selectedRating == index ? 60.w : 40.w,
                        height: selectedRating == index ? 60.h : 40.h,
                        decoration: BoxDecoration(
                          color: selectedRating == index
                              ? AppColors.primary
                              : const Color(0xFFF3F3F3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            ratings[index]['emoji']!,
                            height: 29.h,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ratings[index]['label']!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: selectedRating == index
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: selectedRating == index
                              ? AppColors.primary
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 30.h),

            Text(
              ratings[selectedRating]['title']!,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.blackFull
              ),
            ),

            SizedBox(height: 12.h),

            Text(
              ratings[selectedRating]['description']!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: AppColors.blackFull),
            ),

            SizedBox(height: 12.h),

            // /// Feedback text field
            // TextField(
            //   maxLines: 3,
            //   onChanged: (value) => feedback = value,
            //   decoration: InputDecoration(
            //     hintText: 'Leave your feedback...'.tr,
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //   ),
            // ),
            SizedBox(height: 20.h),

            GestureDetector(
              onTap: () async {
                if (kDebugMode) {
                  print('Selected rating: $selectedRating');
                  print('Feedback: $feedback');
                }

                Navigator.pop(context, selectedRating);

                // Send support email if rating is low
                if (selectedRating <= 2) {
                  await _sendSupportEmail();
                } else {
                  // Redirect to Play Store for high ratings
                  await _openPlayStore();
                }
              },
              child: Container(
                height: 48.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Rate_Us'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color:AppColors.fullwhite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
