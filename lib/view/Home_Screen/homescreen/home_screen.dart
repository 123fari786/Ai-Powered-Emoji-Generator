import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../../models/generated_items_controller.dart';
import '../../../services/image_cache_services.dart';
import '../../../utils/app_color.dart';
import '../../../utils/reesposive.dart';
import '../../Preview_Screen/preview_screen.dart';
import '../../ai_prompt_emoji/ai_prompt_emoji.dart';
import '../../image_to_emoji /image_to_emoji.dart';
import '../../premiumScree/Premium.dart';
import '../../sticker/sticker.dart';
import '../../widgets/background_theme.dart';
import '../../widgets/premium_check_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GeneratedItemsController _itemsController =
  Get.find<GeneratedItemsController>();
  final ImageCacheService _imageCache = ImageCacheService();

  @override
  void initState() {
    super.initState();
    _itemsController.loadAllItems();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveConfig.init(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: BackgroundTheme.background),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'home'.tr,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Simple usage - it will automatically use the styling from your old code
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

                  SizedBox(height: 10.h),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AiPromptEmojiScreen(),
                              ),
                            );
                          },
                          child: Container(
                            height: 290.h,
                            decoration: BoxDecoration(
                              color: AppColors.containerPurple10,
                              borderRadius: BorderRadius.circular(25.w),
                              border: Border.all(
                                color: AppColors.fullwhite,
                                width: 1.w,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 2.w,
                                  top: 6.h,
                                  child: Image.asset(
                                    'assets/icons/home_emoji.png',
                                    height: 120.h,
                                  ),
                                ),
                                Positioned(
                                  left: 10.w,
                                  right: 10.w,
                                  bottom: 10.h,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'explainEmoji'.tr,
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'describeAndGetClearUniqueEmojis'.tr,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.blackFull,
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

                      SizedBox(width: 8.w),

                      Expanded(
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const ImageToEmojiScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                height: 140.h,
                                decoration: BoxDecoration(
                                  color: AppColors.containerBlue10,
                                  borderRadius: BorderRadius.circular(25.w),
                                  border: Border.all(
                                    color: AppColors.fullwhite,
                                    width: 1.w,
                                  ),
                                ),
                                child: SizedBox(
                                  height: 100.h,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 8.w,
                                        bottom: 15.h,
                                        right: 10,
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'imageToEmoji'.tr,
                                              style: TextStyle(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 0.h),
                                            Text(
                                              'uploadAnyImageAndConvertItIntoAFunEmoji'
                                                  .tr,
                                              style: TextStyle(fontSize: 12.sp),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 12,
                                        child: Image.asset(
                                          'assets/icons/home_two_images.png',
                                          height: 50.h,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 8.h),

                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Sticker(),
                                  ),
                                );
                              },
                              child: Container(
                                height: 140.h,
                                decoration: BoxDecoration(
                                  color: AppColors.containerYellow10,
                                  borderRadius: BorderRadius.circular(25.w),
                                  border: Border.all(
                                    color: AppColors.fullwhite,
                                    width: 1.w,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 0.w,
                                      top: -4.h,
                                      child: Image.asset(
                                        'assets/icons/home_sticker.png',
                                        height: 80.h,
                                        width: 80.w,
                                      ),
                                    ),
                                    Positioned(
                                      left: 8.w,
                                      right: 8.w,
                                      bottom: 8.h,
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'createSticker'.tr,
                                            style: TextStyle(
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            'turnYourPhotosIntoStickersForSocialMedia'
                                                .tr,
                                            style: TextStyle(fontSize: 12.sp),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'recent'.tr,
                        style: TextStyle(
                          fontSize: 23.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final bottomBarController =
                          Get.find<BottomBarController>();
                          bottomBarController.changeIndex(2);
                        },
                        child: Text(
                          'viewAll'.tr,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black30,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  Obx(() {
                    final recentItems = _itemsController.getRecentItems(
                      count: 6,
                    );

                    if (recentItems.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50.h),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icons/norecent.png',
                                height: 44.w,
                                width: 44.w,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                'noRecentEmojisYet'.tr,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                'createyourfirstemojiorsticker'.tr,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.blackFull,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 15.h,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: recentItems.length,
                      itemBuilder: (context, index) {
                        final item = recentItems[index];
                        return _RecentItemCard(item: item);
                      },
                    );
                  }),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final ImageCacheService _imageCache = ImageCacheService();

  _RecentItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(
              () => MyEmojisPreviewScreen(item: item),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        width: 95.w,
        decoration: BoxDecoration(
          color: AppColors.white30,
          borderRadius: BorderRadius.circular(18.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.w,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.w),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.w),
                child: _buildImage(),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getItemName(item['prompt'].toString()),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackFull,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _getFormattedDate(item['createdAt']),
                    style: TextStyle(fontSize: 10.sp, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final cachedImage = _imageCache.getCachedImage(item['url']);

    if (cachedImage != null) {
      return Image.memory(
        cachedImage,
        height: 72.w,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return FutureBuilder<Uint8List>(
      future: _loadImageWithCache(item['url']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 10.w,
              height: 10.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          final cached = _imageCache.getCachedImage(item['url']);
          if (cached != null) {
            return Image.memory(
              cached,
              height: 72.w,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          }
          return Center(
            child: Icon(
              Icons.emoji_emotions_outlined,
              size: 26.w,
              color: AppColors.grey,
            ),
          );
        }

        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            height: 72.w,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        }

        return Center(
          child: SizedBox(
            width: 10.w,
            height: 10.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List> _loadImageWithCache(String url) async {
    final cachedImage = _imageCache.getCachedImage(url);
    if (cachedImage != null) return cachedImage;

    final response = await http.get(Uri.parse(url));
    Uint8List bytes = response.bodyBytes;

    try {
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage != null) {
        bytes = Uint8List.fromList(img.encodePng(decodedImage));
      }
    } catch (e) {
      print('Image optimization error: $e');
    }

    await _imageCache.cacheImage(url);

    return bytes;
  }

  String _getItemName(String prompt) {
    if (prompt.isEmpty || prompt == 'null') return 'Generated Item';
    String name = prompt[0].toUpperCase() + prompt.substring(1);
    if (name.length > 15) name = name.substring(0, 15) + '...';
    return name;
  }

  String _getFormattedDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final itemDate = DateTime(date.year, date.month, date.day);

      if (itemDate == today) return 'Today';
      if (itemDate == today.subtract(Duration(days: 1))) return 'Yesterday';

      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      if (date.year == now.year) {
        return '${date.day} ${months[date.month - 1]}';
      } else {
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}

class BottomBarController extends GetxController {
  RxInt currentIndex = 0.obs;

  void changeIndex(int index) {
    currentIndex.value = index;
  }
}
