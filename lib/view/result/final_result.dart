import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../controller/emoji_controller.dart';
import '../../controller/image_to_emoji.dart';
import '../../controller/sticker.dart';
import '../../models/generated_items_controller.dart';
import '../../utils/app_color.dart';
import '../../utils/reesposive.dart';
import '../Home_Screen/bottombar/bottom_bar.dart';
import '../premiumScree/Premium.dart';
import '../widgets/premium_check_widget.dart' hide PremiumScreen;

enum ResultType { imageToEmoji, textToEmoji, sticker }

class UnifiedResultScreen extends StatefulWidget {
  final ResultType resultType;
  final Map<String, dynamic>? extraData;

  const UnifiedResultScreen({
    super.key,
    required this.resultType,
    this.extraData,
  });

  @override
  State<UnifiedResultScreen> createState() => _UnifiedResultScreenState();
}

class _UnifiedResultScreenState extends State<UnifiedResultScreen> {
  ImageToEmojiController? _imageToEmojiController;
  EmojiController? _emojiController;
  StickerController? _stickerController;

  bool _isFirstLoad = true;
  bool isLoading = false;
  String imageUrl = '';
  String promptText = '';
  int selectedStyle = 0;
  String? errorMessage;

  // Current item ID for tracking
  String? _currentItemId;

  // Image cache
  final Map<String, Uint8List> _imageCache = {};

  // Scroll controller for styles
  final ScrollController _styleScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeController();

    // Check for auto-save when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAutoSave();
      // Scroll to selected style after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_styleScrollController.hasClients) {
          _scrollToSelectedStyle();
        }
      });
    });
  }

  void _initializeController() {
    switch (widget.resultType) {
      case ResultType.imageToEmoji:
        _imageToEmojiController = Get.find<ImageToEmojiController>();
        break;
      case ResultType.textToEmoji:
        _emojiController = Get.find<EmojiController>();
        break;
      case ResultType.sticker:
        _stickerController = Get.find<StickerController>();
        break;
    }
    _updateStateFromController();
  }

  void _updateStateFromController() {
    switch (widget.resultType) {
      case ResultType.imageToEmoji:
        if (_imageToEmojiController != null) {
          isLoading = _imageToEmojiController!.isLoading.value;
          imageUrl = _imageToEmojiController!.generatedEmojiUrl.value;
          promptText = _imageToEmojiController!.promptText.value;
          selectedStyle = _imageToEmojiController!.selectedStyle.value;
        }
        break;
      case ResultType.textToEmoji:
        if (_emojiController != null) {
          isLoading =
              _emojiController!.isLoading.value ||
              _emojiController!.isRegenerating.value;
          imageUrl = _emojiController!.imageUrl.value;
          promptText = _emojiController!.promptText.value;
          selectedStyle = _emojiController!.selectedStyleIndex.value;
        }
        break;
      case ResultType.sticker:
        if (_stickerController != null) {
          isLoading = _stickerController!.isLoading.value;
          imageUrl = _stickerController!.generatedStickerUrl.value;
          promptText = _stickerController!.promptText.value;
          selectedStyle = _stickerController!.selectedStyle.value;
        }
        break;
    }
  }

  void _checkAndAutoSave() async {
    if (_isFirstLoad && imageUrl.isNotEmpty && imageUrl != '') {
      _isFirstLoad = false;

      await Future.delayed(Duration(milliseconds: 800));

      try {
        final itemsController = Get.find<GeneratedItemsController>();

        // Check if item already exists (duplicate prevention)
        bool urlExists = itemsController.allItems.any(
          (item) => item['url'] == imageUrl,
        );

        if (urlExists) {
          print('⚠️ Item with same URL already exists, skipping auto-save');

          for (var item in itemsController.allItems) {
            if (item['url'] == imageUrl) {
              _currentItemId = item['id'].toString();
              print('📌 Using existing item ID: $_currentItemId');
              break;
            }
          }
          return;
        }

        String styleName = _getStyleName(selectedStyle);
        String typeName = widget.resultType == ResultType.sticker
            ? 'sticker'
            : 'emoji';

        // Generate a meaningful prompt if empty
        String finalPrompt = promptText.isNotEmpty
            ? promptText
            : '${typeName.capitalizeFirst} ${DateTime.now().hour}:${DateTime.now().minute}';

        final newId = await itemsController.saveGeneratedItem(
          url: imageUrl,
          prompt: finalPrompt,
          type: typeName,
          style: styleName,
        );

        // Save the new item ID
        _currentItemId = newId;

        print('✅ Auto-saved $typeName to local storage');
        print('📋 Prompt: $finalPrompt');
        print('🆔 Item ID: $newId');
        print(
          '🖼 Image URL: ${imageUrl.substring(0, min(50, imageUrl.length))}...',
        );

        // Success feedback
        if (Get.context != null) {
          Future.delayed(Duration(seconds: 1), () {
            // Get.snackbar(
            //   'success'.tr,
            //   '${typeName.capitalizeFirst} saved to history'.tr,
            //   snackPosition: SnackPosition.BOTTOM,
            //   duration: Duration(seconds: 2),
            //   backgroundColor: Colors.green.withOpacity(0.8),
            //   colorText: Colors.white,
            // );
          });
        }
      } catch (e) {
        print('❌ Error auto-saving: $e');
        // Show error only if context is available
        if (Get.context != null) {
          Get.snackbar(
            'Error'.tr,
            'Failed to save to history'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: AppColors.fullwhite,
          );
        }
      }
    }
  }

  String _getStyleName(int index) {
    switch (widget.resultType) {
      case ResultType.imageToEmoji:
        // Image to Emoji style mapping
        switch (index) {
          case 0:
            return 'Classic';
          case 1:
            return 'Cartoon';
          case 2:
            return 'Pixel';
          case 3:
            return 'Line Art';
          default:
            return 'Classic';
        }

      case ResultType.textToEmoji:
        // Text to Emoji (AI Prompt) style mapping
        switch (index) {
          case 1:
            return 'Classic';
          case 2:
            return 'Cartoon';
          case 3:
            return 'Pixel';
          case 4:
            return 'Line Art';
          default:
            return 'Classic';
        }

      case ResultType.sticker:
        // Sticker style mapping
        switch (index) {
          case 0:
            return 'Classic';
          case 1:
            return '3D';
          case 2:
            return 'Pastel';
          case 3:
            return 'Minmal';
          default:
            return 'Classic';
        }
    }
  }

  String _getStyleAssetPath(int index) {
    switch (widget.resultType) {
      case ResultType.imageToEmoji:
        // Image to Emoji assets
        switch (index) {
          case 0:
            return 'assets/emojis/classic.png';
          case 1:
            return 'assets/emojis/cartoon.png';
          case 2:
            return 'assets/emojis/pixel.png';
          case 3:
            return 'assets/emojis/line_art.png';
          default:
            return 'assets/emojis/classic.png';
        }

      case ResultType.textToEmoji:
        // Text to Emoji (AI Prompt) assets
        switch (index) {
          case 1:
            return 'assets/emojis/classic.png';
          case 2:
            return 'assets/emojis/cartoon.png';
          case 3:
            return 'assets/emojis/pixel.png';
          case 4:
            return 'assets/emojis/line_art.png';
          default:
            return 'assets/emojis/classic.png';
        }

      case ResultType.sticker:
        // Sticker assets
        switch (index) {
          case 0:
            return 'assets/emojis/classic_style.png';
          case 1:
            return 'assets/emojis/3D.png';
          case 2:
            return 'assets/emojis/pastel.png';
          case 3:
            return 'assets/emojis/minmal.png';
          default:
            return 'assets/emojis/classic_style.png';
        }
    }
  }

  String _getStyleDisplayText(int index) {
    switch (widget.resultType) {
      case ResultType.imageToEmoji:
        // Image to Emoji display texts
        switch (index) {
          case 0:
            return "styleClassic".tr;
          case 1:
            return "styleCartoon".tr;
          case 2:
            return "stylePixel".tr;
          case 3:
            return "styleLineArt".tr;
          default:
            return "styleClassic".tr;
        }

      case ResultType.textToEmoji:
        // Text to Emoji (AI Prompt) display texts
        switch (index) {
          case 1:
            return "styleClassic".tr;
          case 2:
            return "styleCartoon".tr;
          case 3:
            return "stylePixel".tr;
          case 4:
            return "styleLineArt".tr;
          default:
            return "styleClassic".tr;
        }

      case ResultType.sticker:
        // Sticker display texts
        switch (index) {
          case 0:
            return "Classic";
          case 1:
            return "3D";
          case 2:
            return "Pastel";
          case 3:
            return "Minmal";
          default:
            return "Classic";
        }
    }
  }

  // Get total number of styles for current screen
  int _getTotalStyles() {
    switch (widget.resultType) {
      case ResultType.imageToEmoji:
        return 4; // Classic, Cartoon, Pixel, Line Art
      case ResultType.textToEmoji:
        return 4; // Classic, Cartoon, Pixel, Line Art
      case ResultType.sticker:
        return 4; // Classic, 3D, Pastel, Minmal
    }
  }

  // Get style index for text to emoji (AI Prompt) adjustment
  int _getAdjustedIndex(int index) {
    if (widget.resultType == ResultType.textToEmoji) {
      // Convert 1,2,3,4 to 0,1,2,3 for display
      return index - 1;
    }
    return index;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ResponsiveConfig.isInitialized) {
      ResponsiveConfig.init(context);
    }
  }

  Future<void> saveToGallery() async {
    try {
      bool allowed = await Gal.requestAccess();
      if (!allowed) {
        Fluttertoast.showToast(msg: 'Permission denied'.tr);
        return;
      }

      if (imageUrl.isEmpty) {
        Fluttertoast.showToast(msg: 'No image to save'.tr);
        return;
      }

      Uint8List imageBytes;
      if (_imageCache.containsKey(imageUrl)) {
        imageBytes = _imageCache[imageUrl]!;
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image');
        }
        imageBytes = response.bodyBytes;
        _imageCache[imageUrl] = imageBytes;
      }

      await Gal.putImageBytes(imageBytes);
      Fluttertoast.showToast(msg: 'savedToGallery'.tr);
    } catch (e) {
      print('Save to gallery error: $e');
      Fluttertoast.showToast(msg: 'failedToSave'.tr);
    }
  }

  // Delete function (kept if needed elsewhere, but removed from AppBar)
  Future<void> _deleteFromHistory() async {
    try {
      if (_currentItemId == null) {
        Fluttertoast.showToast(
          msg: 'No item to delete'.tr,
          backgroundColor: AppColors.fullwhite,
          textColor: Colors.black,
          toastLength: Toast.LENGTH_SHORT,
        );
        return;
      }

      final itemsController = Get.find<GeneratedItemsController>();

      // Confirm deletion
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete from History'.tr),
          content: Text(
            'Are you sure you want to delete this item from your history?'.tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete'.tr, style: TextStyle(color: AppColors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await itemsController.deleteItem(_currentItemId!);
        Fluttertoast.showToast(
          msg: 'Item Deleted from History'.tr,
          backgroundColor:AppColors.fullwhite,
          textColor: AppColors.blackFull,
          toastLength: Toast.LENGTH_SHORT,
        );

        // Navigate back
        Get.offAll(CustomBottomBar());
      }
    } catch (e) {
      print('Delete error: $e');
      Fluttertoast.showToast(
        msg: 'Failed to delete item'.tr,
        backgroundColor: AppColors.fullwhite,
        textColor: AppColors.blackFull,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  String _getScreenTitle() {
    switch (widget.resultType) {
      case ResultType.imageToEmoji:
        return 'result'.tr;
      case ResultType.textToEmoji:
        return 'result'.tr;
      case ResultType.sticker:
        return 'result'.tr;
      default:
        return 'Result';
    }
  }

  Future<Uint8List> _loadNetworkImage(String url) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url]!;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        // Optimize image if needed
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          final optimizedBytes = img.encodePng(decodedImage);
          _imageCache[url] = Uint8List.fromList(optimizedBytes);
          return optimizedBytes;
        }
        _imageCache[url] = bytes;
        return bytes;
      }
      throw Exception('Failed to load image: ${response.statusCode}');
    } catch (e) {
      throw Exception('Image load error: $e');
    }
  }

  void _scrollToSelectedStyle() {
    if (_styleScrollController.hasClients) {
      final adjustedSelectedStyle = _getAdjustedIndex(selectedStyle);

      // Calculate the position to scroll to
      final double itemWidth = 72.w + 10.w; // width + spacing
      final double scrollPosition = adjustedSelectedStyle * itemWidth;

      _styleScrollController.animateTo(
        scrollPosition,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _styleScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveConfig.init(context);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          switch (widget.resultType) {
            case ResultType.imageToEmoji:
              if (_imageToEmojiController != null) {
                _imageToEmojiController!.clearSelectedImage();
              }
              break;
            case ResultType.sticker:
              if (_stickerController != null) {
                _stickerController!.clearSelectedImage();
              }
              break;
            case ResultType.textToEmoji:
              break;
          }

          _currentItemId = null;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF3EDFF),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xffF3EDFF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Row(
                  children: [
                    // Back button
                    _circleBackBtn(),

                    // Spacer
                    Expanded(
                      child: Center(
                        child: Text(
                          _getScreenTitle().tr,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackFull,
                          ),
                        ),
                      ),
                    ),

                    // Pro button
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
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP IMAGE BOX
              Container(
                width: double.infinity,
                height: 290.h,
                decoration: BoxDecoration(
                  color: AppColors.fullwhite,
                  borderRadius: BorderRadius.circular(26.w),
                ),
                child: _buildImageDisplay(),
              ),

              SizedBox(height: 15.h),

              if (promptText.isNotEmpty) ...[
                Text(
                  "prompt".tr,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackFull,
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  height: 85.h, // Fixed height for approximately 3 lines
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.fullwhite,
                    borderRadius: BorderRadius.circular(22.w),
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Text(
                        promptText,
                        style: TextStyle(
                          fontSize: 15.sp,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15.h),
              ],

              // Selected Style Display
              Text(
                "selectStyleTitle".tr,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.blackFull,
                ),
              ),

              SizedBox(height: 10.h),

              // HORIZONTAL SCROLLABLE STYLES LIST (ALL STYLES SHOW)
              Container(
                height: 90.h,
                child: SingleChildScrollView(
                  controller: _styleScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_getTotalStyles(), (index) {
                      // Adjust index for text to emoji
                      final displayIndex =
                          widget.resultType == ResultType.textToEmoji
                          ? index + 1
                          : index;

                      final adjustedSelectedStyle = _getAdjustedIndex(
                        selectedStyle,
                      );
                      final bool isSelected = index == adjustedSelectedStyle;

                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == _getTotalStyles() - 1 ? 2.w : 10.w,
                          left: index == 0 ? 2.w : 0,
                        ),
                        child: _styleBox(displayIndex, isSelected),
                      );
                    }),
                  ),
                ),
              ),

              const Spacer(),

              // BOTTOM DOWNLOAD BUTTON
              Padding(
                padding: EdgeInsets.only(
                  left: 0.w,
                  right: 10.w,
                  bottom: 5.h + MediaQuery.of(context).padding.bottom,
                ),
                child: GestureDetector(
                  onTap: saveToGallery,
                  child: Container(
                    width: double.infinity,
                    height: 55.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(40.w),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/download.png',
                            width: 22.w,
                            height: 22.h,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            "download".tr,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.fullwhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleBackBtn() {
    return GestureDetector(
      onTap: () {
        switch (widget.resultType) {
          case ResultType.imageToEmoji:
            if (_imageToEmojiController != null) {
              _imageToEmojiController!.clearSelectedImage();
            }
            break;
          case ResultType.sticker:
            if (_stickerController != null) {
              _stickerController!.clearSelectedImage();
            }
            break;
          case ResultType.textToEmoji:
            break;
        }

        _currentItemId = null;

        Get.offAll(CustomBottomBar());
      },
      child: Container(
        height: 30.h,
        width: 30.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.fullwhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18.sp,
          color: AppColors.blackFull,
        ),
      ),
    );
  }

  // NEW: Pro Button Widget
  // Widget _proButton() {
  //   return PremiumCheckWidget(
  //     onProButtonTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => PremiumScreen()),
  //       );
  //     },
  //   );
  // }

  Widget _buildImageDisplay() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (imageUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 60, color: AppColors.grey),
            SizedBox(height: 10),
            Text("No image generated".tr, style: TextStyle(fontSize: 15.sp)),
          ],
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: _loadNetworkImage(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: AppColors.white30,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            color: AppColors.white30,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 40, color: AppColors.red),
                  SizedBox(height: 10),
                  Text("Failed to load image".tr),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26.w),
              color: AppColors.white30,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.w),
              child: Image.memory(snapshot.data!, fit: BoxFit.contain),
            ),
          );
        }

        return Container(
          color: AppColors.white30,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
    );
  }

  Widget _styleBox(int index, bool isSelected) {
    String title = _getStyleDisplayText(index);
    String assetPath = _getStyleAssetPath(index);

    return Container(
      height: 76.h,
      width: 72.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.w),
        color: AppColors.white30,
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //Emoji from assets
          Image.asset(
            assetPath,
            width: 28.w,
            height: 28.w,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.blackFull,
            ),
          ),
        ],
      ),
    );
  }
}
