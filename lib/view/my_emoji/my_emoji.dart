import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../models/generated_items_controller.dart';
import '../../services/database_services.dart';
import '../../services/image_cache_services.dart';
import '../../utils/app_color.dart';
import '../../utils/reesposive.dart';
import '../Preview_Screen/preview_screen.dart';
import '../premiumScree/Premium.dart';
import '../widgets/background_theme.dart';
import '../widgets/premium_check_widget.dart' hide PremiumScreen;

class MyEmojisScreen extends StatefulWidget {
  const MyEmojisScreen({super.key});

  @override
  State<MyEmojisScreen> createState() => _MyEmojisScreenState();
}

class _MyEmojisScreenState extends State<MyEmojisScreen> {
  final GeneratedItemsController _itemsController =
      Get.find<GeneratedItemsController>();
  final LocalStorageService _storage = LocalStorageService();
  final ImageCacheService _imageCache = ImageCacheService();

  int _selectedTab = 0; // 0: All, 1: Emojis, 2: Stickers
  var isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    isLoading.value = true;
    await _itemsController.loadAllItems();
    isLoading.value = false;
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    final items = _itemsController.allItems;
    switch (_selectedTab) {
      case 1:
        return items.where((item) => item['type'] == 'emoji').toList();
      case 2:
        return items.where((item) => item['type'] == 'sticker').toList();
      default:
        return items.toList();
    }
  }

  Future<Uint8List> _loadImageWithCache(String url) async {
    try {
      final cachedImage = _imageCache.getCachedImage(url);
      if (cachedImage != null) return cachedImage;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
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
      throw Exception('Failed to load image');
    } catch (e) {
      final cachedImage = _imageCache.getCachedImage(url);
      if (cachedImage != null) return cachedImage;
      throw Exception('Image load error: $e');
    }
  }

  void _onItemTap(Map<String, dynamic> item) {
    // Navigate to preview
    Get.to(
      () => MyEmojisPreviewScreen(item: item),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'myEmojis'.tr,
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

                SizedBox(height: 15.h),

                // Always show Tab Bar (no Obx needed here)
                _buildTabBar(),

                // Content
                Expanded(
                  child: Obx(() {
                    if (isLoading.value) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 30.w,
                              height: 30.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Text(
                              'Loading...'.tr,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.blackFull,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final items = _getFilteredItems();

                    if (items.isEmpty) {
                      // Wrap in SingleChildScrollView to prevent overflow
                      return SingleChildScrollView(
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(height: 190.h),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                        color: AppColors.blackFull,
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
                            ],
                          ),
                        ),
                      );
                    }

                    // Grid of emojis/stickers
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 20.h, top: 6.h),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.90,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return GestureDetector(
                            onTap: () => _onItemTap(item),
                            child: _MyItemCard(
                              item: item,
                              loadImage: _loadImageWithCache,
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tab bar
  Widget _buildTabBar() {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15.w),
      ),
      child: Row(
        children: [
          _buildTab(0, 'all'.tr),
          _buildTab(1, 'emojis'.tr),
          _buildTab(2, 'stickers'.tr),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          margin: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12.w),
          ),
          child: Center(
            child: Text(
              title.tr,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Item Card
class _MyItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Future<Uint8List> Function(String) loadImage;

  const _MyItemCard({required this.item, required this.loadImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white30,
        borderRadius: BorderRadius.circular(18.w),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.all(8.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.w),
                child: FutureBuilder<Uint8List>(
                  future: loadImage(item['url']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Icon(
                          Icons.emoji_emotions_outlined,
                          size: 30.w,
                          color: AppColors.grey,
                        ),
                      );
                    }
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    }
                    return SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  SizedBox(height: 4.h),
                  Text(
                    _getFormattedDate(item['createdAt']),
                    style: TextStyle(fontSize: 9.sp, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getItemName(String prompt) {
    if (prompt.isEmpty || prompt == 'null') return 'My Item';
    String name = prompt[0].toUpperCase() + prompt.substring(1);
    if (name.length > 12) name = name.substring(0, 12) + '...';
    return name;
  }

  String _getFormattedDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
