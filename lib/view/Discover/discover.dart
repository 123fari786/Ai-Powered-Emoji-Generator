import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart'; // gal package
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controller/discover_controller.dart';
import '../../utils/app_color.dart';
import '../../utils/reesposive.dart';
import '../premiumScree/Premium.dart';
import '../widgets/background_theme.dart';
import '../widgets/premium_check_widget.dart' hide PremiumScreen;

class DiscoverScreen extends StatelessWidget {
  DiscoverScreen({super.key});
  final controller = Get.put(DiscoverController());

  // Image cache to avoid multiple downloads
  final Map<String, Uint8List> _imageCache = {};

  @override
  Widget build(BuildContext context) {
    ResponsiveConfig.init(context);

    return Obx(() {
      final bool isLoading = controller.categories.isEmpty;

      final selected = isLoading
          ? null
          : controller.categories.firstWhere(
              (cat) => cat.name == controller.selectedCategory.value,
              orElse: () => controller.categories.first,
            );

      final items = selected?.emojis ?? [];

      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: BackgroundTheme.background),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 15.w,
                    vertical: 0.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'discover'.tr,
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
                        // showPremiumBadge: true,
                        onProButtonTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PremiumScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                // Category chips
                SizedBox(
                  height: 37.h,
                  child: isLoading
                      ? const SizedBox()
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          children: controller.categories.map((cat) {
                            bool isSelected =
                                cat.name == controller.selectedCategory.value;
                            return GestureDetector(
                              onTap: () {
                                controller.selectedCategory.value = cat.name;
                                controller.categoryCount = cat.counts;
                              },
                              child: Container(
                                margin: EdgeInsets.only(right: 16.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30.w),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.fullwhite
                                          : AppColors.primary,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),

                SizedBox(height: 14.h),

                // Free attempts indicator
                // _buildFreeAttemptsIndicator(),

                // Grid or Loader
                Expanded(
                  child: isLoading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              "loadingemojis".tr,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(bottom: 10.h, top: 6.h),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12.w,
                                  mainAxisSpacing: 12.h,
                                  childAspectRatio: 0.99,
                                ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final emoji = items[index];
                              return _EmojiCard(
                                imageUrl: emoji.emojiUrl,
                                title: emoji.name,
                                onTap: () => _showStickerDialog(context, emoji),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // Free attempts indicator widget
  Widget _buildFreeAttemptsIndicator() {
    return FutureBuilder<bool>(
      future: TrialManager.hasPremium(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(height: 10.h);
        }

        final hasPremium = snapshot.data ?? false;
        if (hasPremium) {
          return SizedBox(height: 10.h);
        }

        return FutureBuilder<int>(
          future: TrialManager.getRemainingStickerAttempts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(height: 10.h);
            }

            final remainingAttempts = snapshot.data ?? 3;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.w),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text(
                    //   'freeAttempts'.tr,
                    //   style: TextStyle(
                    //     color: AppColors.primary,
                    //     fontSize: 14.sp,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    Row(
                      children: [
                        Icon(
                          Icons.download,
                          size: 16.w,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.share, size: 16.w, color: AppColors.primary),
                        SizedBox(width: 8.w),
                        // Text(
                        //   // '$remainingAttempts/3',
                        //   style: TextStyle(
                        //     color: AppColors.primary,
                        //     fontSize: 14.sp,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStickerDialog(BuildContext context, emoji) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "stickerdialog".tr,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.fullwhite,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Image.network(
                            emoji.emojiUrl,
                            height: 280,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.error, size: 50),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Builder(
                              builder: (context) {
                                return SizedBox(
                                  height: 48,
                                  width: 147,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:AppColors.fullwhite,
                                      foregroundColor: AppColors.blackFull,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async =>
                                        _shareSticker(context, emoji),
                                    icon: const Icon(
                                      Icons.share,
                                      color: AppColors.blackFull,
                                    ),
                                    label: Text(
                                      "share".tr,
                                      style: TextStyle(color: AppColors.blackFull),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              height: 48,
                              width: 147,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:AppColors.fullwhite,
                                  foregroundColor: AppColors.blackFull,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async =>
                                    _downloadSticker(context, emoji),
                                icon: Image.asset(
                                  "assets/icons/download.png",
                                  height: 20,
                                  width: 20,
                                  color: AppColors.blackFull,
                                ),
                                label: Text(
                                  "download".tr,
                                  style: TextStyle(color: AppColors.blackFull),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  Future<void> _shareSticker(BuildContext context, emoji) async {
    // Check if user has premium or free attempts left
    final hasPremium = await TrialManager.hasPremium();
    if (!hasPremium) {
      final canShare = await TrialManager.trackStickerShare();
      if (!canShare) {
        // Show premium screen if no free attempts left
        Navigator.of(context).pop(); // Close dialog first
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PremiumScreen()),
        );
        return;
      }
    }

    try {
      Uint8List bytes;
      if (_imageCache.containsKey(emoji.emojiUrl)) {
        bytes = _imageCache[emoji.emojiUrl]!;
      } else {
        final response = await http.get(Uri.parse(emoji.emojiUrl));
        if (response.statusCode != 200)
          throw Exception('Failed to download image');
        bytes = response.bodyBytes;
        _imageCache[emoji.emojiUrl] = bytes;
      }

      // Decode and re-encode PNG to preserve transparency
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Invalid image');
      Uint8List pngBytes = Uint8List.fromList(img.encodePng(image));

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/${emoji.name}.png');
      await file.writeAsBytes(pngBytes);

      // Get the RenderBox for iPad share position
      final box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: emoji.name,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.fromLTWH(0, 0, 1, 1), // fallback for safety
      );

      // Show remaining attempts message for non-premium users
      if (!hasPremium) {
        Navigator.of(context).pop(); // Close dialog first
        final remaining = await TrialManager.getRemainingStickerAttempts();
        // Optional: Show snackbar for remaining attempts
      } else {
        Navigator.of(context).pop(); // Close dialog
        Get.snackbar(
          'success'.tr,
          'stickerShared'.tr,
          backgroundColor: AppColors.fullwhite,
          colorText: AppColors.blackFull,
          duration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      print("Share failed: $e");
      Navigator.of(context).pop(); // Close dialog
      Get.snackbar(
        'error'.tr,
        'failedToShare'.tr,
        backgroundColor: AppColors.fullwhite,
        colorText: AppColors.blackFull,
      );
    }
  }

  Future<void> _downloadSticker(BuildContext context, emoji) async {
    // Check if user has premium or free attempts left
    final hasPremium = await TrialManager.hasPremium();
    if (!hasPremium) {
      final canDownload = await TrialManager.trackStickerDownload();
      if (!canDownload) {
        // Show premium screen if no free attempts left
        Navigator.of(context).pop(); // Close dialog first
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PremiumScreen()),
        );
        return;
      }
    }

    try {
      Uint8List bytes;
      if (_imageCache.containsKey(emoji.emojiUrl)) {
        bytes = _imageCache[emoji.emojiUrl]!;
      } else {
        final response = await http.get(Uri.parse(emoji.emojiUrl));
        if (response.statusCode != 200)
          throw Exception('Failed to download image');
        bytes = response.bodyBytes;
        _imageCache[emoji.emojiUrl] = bytes;
      }

      // Decode and re-encode PNG to preserve transparency
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Invalid image');
      Uint8List pngBytes = Uint8List.fromList(img.encodePng(image));

      await Gal.putImageBytes(pngBytes, name: emoji.name);

      // Show remaining attempts message for non-premium users
      if (!hasPremium) {
        Navigator.of(context).pop(); // Close dialog first
        final remaining = await TrialManager.getRemainingStickerAttempts();
        Get.snackbar(
          'success'.tr,
          'savedToGallery'.tr,
          // (remaining > 0
          //     ? '\n${'remainingAttempts'.tr}: $remaining'
          //     : '\n${'noFreeAttemptsLeft'.tr}'),
          backgroundColor: AppColors.fullwhite,
          colorText: AppColors.blackFull,
          duration: Duration(seconds: 2),
        );
      } else {
        Navigator.of(context).pop(); // Close dialog
        Get.snackbar(
          'success'.tr,
          'savedToGallery'.tr,
          backgroundColor: AppColors.fullwhite,
          colorText: AppColors.blackFull,
          duration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      print("Download failed: $e");
      Navigator.of(context).pop(); // Close dialog
      Get.snackbar(
        'error'.tr,
        'failedToSave'.tr,
        backgroundColor: AppColors.fullwhite,
        colorText: AppColors.blackFull,
      );
    }
  }
}

class _EmojiCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback onTap;

  const _EmojiCard({
    required this.imageUrl,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white30,
          borderRadius: BorderRadius.circular(22.w),
        ),
        child: Center(
          child: SizedBox(
            height: 80.h,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Icon(Icons.error, size: 20.w),
              loadingBuilder: (c, child, loading) => loading == null
                  ? child
                  : SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// TrialManager Class
class TrialManager {
  // Keys for each feature
  static const String _textToEmojiTrialKey = 'text_to_emoji_trial_used';
  static const String _imageToEmojiTrialKey = 'image_to_emoji_trial_used';
  static const String _stickerTrialKey = 'sticker_trial_used';

  // New key for sticker share count
  static const String _stickerShareCountKey = 'sticker_share_count';
  static const String _stickerDownloadCountKey = 'sticker_download_count';

  // Key for tracking successful generations (for rating dialog)
  static const String _successfulGenerationsKey = 'successful_generations';

  // Maximum free attempts
  static const int _maxFreeAttempts = 3;

  /// Check if trial is available for a specific feature
  static Future<bool> isTrialAvailable(String feature) async {
    final prefs = await SharedPreferences.getInstance();

    switch (feature) {
      case 'text_to_emoji':
        return !(prefs.getBool(_textToEmojiTrialKey) ?? false);
      case 'image_to_emoji':
        return !(prefs.getBool(_imageToEmojiTrialKey) ?? false);
      case 'sticker':
        // For sticker, check both download and share counts
        final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
        final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
        // User can perform total 3 free actions (download + share combined)
        return (downloadCount + shareCount) < _maxFreeAttempts;
      default:
        return true;
    }
  }

  // Mark trial as used for a specific feature
  static Future<void> markTrialUsed(String feature) async {
    final prefs = await SharedPreferences.getInstance();

    switch (feature) {
      case 'text_to_emoji':
        await prefs.setBool(_textToEmojiTrialKey, true);
        break;
      case 'image_to_emoji':
        await prefs.setBool(_imageToEmojiTrialKey, true);
        break;
      case 'sticker':
        // Sticker is handled differently with counters
        break;
    }
  }

  // Track sticker download
  static Future<bool> trackStickerDownload() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
    final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;

    if ((downloadCount + shareCount) >= _maxFreeAttempts) {
      return false; // No more free attempts
    }

    await prefs.setInt(_stickerDownloadCountKey, downloadCount + 1);
    return true;
  }

  // Track sticker share
  static Future<bool> trackStickerShare() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
    final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;

    if ((downloadCount + shareCount) >= _maxFreeAttempts) {
      return false; // No more free attempts
    }

    await prefs.setInt(_stickerShareCountKey, shareCount + 1);
    return true;
  }

  // Get remaining free attempts for stickers
  static Future<int> getRemainingStickerAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
    final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
    final usedAttempts = downloadCount + shareCount;
    return _maxFreeAttempts - usedAttempts;
  }

  // Get total used attempts for stickers
  static Future<int> getUsedStickerAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
    final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
    return downloadCount + shareCount;
  }

  // Track a successful generation (increment counter)
  static Future<void> trackSuccessfulGeneration() async {
    final prefs = await SharedPreferences.getInstance();
    final int currentCount = prefs.getInt(_successfulGenerationsKey) ?? 0;
    await prefs.setInt(_successfulGenerationsKey, currentCount + 1);
  }

  //Check if we should show rating (after 3 successful generations)
  static Future<bool> shouldShowRating() async {
    final prefs = await SharedPreferences.getInstance();
    final int generations = prefs.getInt(_successfulGenerationsKey) ?? 0;
    return generations >= 3;
  }

  // Check if user has Premium
  static Future<bool> hasPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('user_has_premium') ?? false;
  }

  //Set Premium status (call this when user purchases)
  static Future<void> setPremium(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_has_premium', status);
  }

  /// Reset all trials (for testing)
  static Future<void> resetAllTrials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_textToEmojiTrialKey);
    await prefs.remove(_imageToEmojiTrialKey);
    await prefs.remove(_stickerTrialKey);
    await prefs.remove(_stickerShareCountKey);
    await prefs.remove(_stickerDownloadCountKey);
    await prefs.remove(_successfulGenerationsKey);
  }

  /// Reset sticker counters only
  static Future<void> resetStickerCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stickerShareCountKey);
    await prefs.remove(_stickerDownloadCountKey);
  }
}
