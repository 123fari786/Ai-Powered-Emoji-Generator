import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/generated_items_controller.dart';
import '../../utils/app_color.dart';
import '../../utils/reesposive.dart';
// Import background theme
import '../widgets/background_theme.dart'; // Add this import

class MyEmojisPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const MyEmojisPreviewScreen({super.key, required this.item});

  @override
  State<MyEmojisPreviewScreen> createState() => _MyEmojisPreviewScreenState();
}

class _MyEmojisPreviewScreenState extends State<MyEmojisPreviewScreen> {
  bool isLoading = false;
  bool isSharing = false;
  final Map<String, Uint8List> _imageCache = {};

  // Image cache
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

  Future<void> saveToGallery() async {
    try {
      bool allowed = await Gal.requestAccess();
      if (!allowed) {
        Fluttertoast.showToast(msg: 'Permission denied'.tr);
        return;
      }

      final imageUrl = widget.item['url'];
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

  Future<void> _shareImage(BuildContext buttonContext) async {
    // Accept context parameter
    try {
      final imageUrl = widget.item['url'];
      if (imageUrl.isEmpty) {
        Fluttertoast.showToast(msg: 'No image to share'.tr);
        return;
      }

      setState(() {
        isSharing = true;
      });

      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Save temporarily and share
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/shared_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(response.bodyBytes);

        // CORRECTED: Get RenderBox from the buttonContext passed in
        final box = buttonContext.findRenderObject() as RenderBox?;

        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              widget.item['prompt']?.toString() ??
              'Check out this emoji/sticker!',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null, // It's safer to pass null than a fallback Rect if the box is null
        );
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      print('Share error: $e');
      Fluttertoast.showToast(msg: 'failedToShare'.tr);
    } finally {
      if (mounted) {
        setState(() {
          isSharing = false;
        });
      }
    }
  }

  Future<void> _deleteFromHistory() async {
    try {
      final itemsController = Get.find<GeneratedItemsController>();
      final itemId = widget.item['id'].toString();

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
              child: Text('Delete'.tr, style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await itemsController.deleteItem(itemId);

        Fluttertoast.showToast(
          msg: 'Item deleted from history'.tr,
          backgroundColor: AppColors.fullwhite,
          textColor: AppColors.blackFull,
          toastLength: Toast.LENGTH_SHORT,
        );

        // Navigate back
        Get.back();
      }
    } catch (e) {
      print('Delete error: $e');
      Fluttertoast.showToast(
        msg: 'Failed to delete item'.tr,
        backgroundColor:AppColors.fullwhite,
        textColor: AppColors.blackFull,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  String _getStyleName(String style) {
    // Map style names to display names
    final styleMap = {
      'Classic': 'Classic',
      'Cartoon': 'Cartoon',
      'Pixel': 'Pixel',
      'Line Art': 'Line Art',
      '3D': '3D',
      'Pastel': 'Pastel',
      'Minmal': 'Minimal',
      'Sketch': 'Sketch',
      'Anime': 'Anime',
      'classic_style': 'Classic',
    };
    return styleMap[style] ?? style;
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

  // UPDATED: Function to check if prompt is a system-generated default prompt
  bool _isDefaultSystemPrompt(String prompt) {
    if (prompt.isEmpty) return true;

    final defaultPrompts = [
      'image to sticker',
      'image to emoji',
      'prompt to emoji',
      'Image to sticker',
      'Image to emoji',
      'Prompt to emoji',
      'convert image to sticker',
      'convert to sticker',
      'convert to emoji',
      'create sticker from image',
      'make sticker',
      'make emoji',
      'generate sticker',
      'generate emoji',
      'sticker from image',
      'emoji from image',
    ];

    // Trim and lowercase for comparison
    final cleanedPrompt = prompt.trim().toLowerCase();

    // Check if it contains any default prompt (case-insensitive)
    for (var defaultPrompt in defaultPrompts) {
      if (cleanedPrompt.contains(defaultPrompt.toLowerCase())) {
        return true;
      }
    }

    // Also check for exact matches
    return defaultPrompts.contains(prompt.trim());
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveConfig.init(context);

    // Get the prompt and check if it's a valid user prompt
    final prompt = widget.item['prompt']?.toString() ?? '';
    final hasUserPrompt = prompt.isNotEmpty && !_isDefaultSystemPrompt(prompt);

    return Scaffold(
      // Apply background theme here
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: BackgroundTheme.background),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar - Fixed height without extra padding
              Container(
                height: 60.h,
                child: Row(
                  children: [
                    // Back Button
                    _circleBackBtn(),

                    // Title (centered)
                    Expanded(
                      child: Center(
                        child: Text(
                          'preview'.tr,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blackFull,
                          ),
                        ),
                      ),
                    ),

                    // Empty space for alignment
                    Container(width: 40.w, height: 40.w),
                  ],
                ),
              ),

              // Body Content - No top padding
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP IMAGE BOX
                      Container(
                        width: double.infinity,
                        height: 290.h,
                        decoration: BoxDecoration(
                          color: AppColors.fullwhite,
                          borderRadius: BorderRadius.circular(22.w),
                        ),
                        child: _buildImageDisplay(),
                      ),

                      SizedBox(height: 15.h),

                      // ONLY SHOW PROMPT SECTION IF USER PROVIDED A REAL PROMPT
                      if (hasUserPrompt) ...[
                        Text(
                          "prompt".tr,
                          style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blackFull,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          height: 110.h, // Fixed height for 4 lines
                          padding: EdgeInsets.all(9.w),
                          decoration: BoxDecoration(
                            color: AppColors.fullwhite,
                            borderRadius: BorderRadius.circular(22.w),
                          ),
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              child: Text(
                                // Show only the actual user prompt
                                prompt,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  height: 1.45,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 25.h),

                        // Info Section (SMALL when prompt exists)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Type
                            _infoChip(
                              icon: widget.item['type'] == 'sticker'
                                  ? Icons.sticky_note_2
                                  : Icons.emoji_emotions,
                              text: (widget.item['type'] ?? 'item')
                                  .toString()
                                  .capitalizeFirst!,
                              isSmall: true, // Small version
                            ),

                            // Date
                            _infoChip(
                              icon: Icons.calendar_today,
                              text: _getFormattedDate(
                                widget.item['createdAt'].toString(),
                              ),
                              isSmall: true, // Small version
                            ),
                          ],
                        ),
                      ] else ...[
                        // If no user prompt, show LARGER info chips
                        SizedBox(height: 40.h), // Extra spacing

                        Center(
                          child: Column(
                            children: [
                              // Type (LARGE)
                              _infoChip(
                                icon: widget.item['type'] == 'sticker'
                                    ? Icons.sticky_note_2
                                    : Icons.emoji_emotions,
                                text: (widget.item['type'] ?? 'item')
                                    .toString()
                                    .capitalizeFirst!,
                                isSmall: false, // Large version
                              ),

                              SizedBox(height: 15.h),

                              // Date (LARGE)
                              _infoChip(
                                icon: Icons.calendar_today,
                                text: _getFormattedDate(
                                  widget.item['createdAt'].toString(),
                                ),
                                isSmall: false, // Large version
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(),

                      // SHARE AND DELETE BUTTONS ROW
                      Row(
                        children: [
                          // SHARE BUTTON
                          // SHARE BUTTON
                          Expanded(
                            child: Builder(
                              // Wrap with Builder to get the correct context
                              builder: (BuildContext buttonContext) {
                                return GestureDetector(
                                  onTap: isSharing
                                      ? null
                                      : () => _shareImage(
                                          buttonContext,
                                        ), // Pass the new context
                                  child: Container(
                                    height: 50.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(40.w),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: isSharing
                                          ? SizedBox(
                                              width: 22.w,
                                              height: 22.w,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.fullwhite,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.share,
                                                  color:AppColors.fullwhite,
                                                  size: 22.sp,
                                                ),
                                                SizedBox(width: 10.w),
                                                Text(
                                                  "share".tr,
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
                                );
                              },
                            ),
                          ),

                          SizedBox(width: 15.w),

                          // DELETE BUTTON
                          Expanded(
                            child: GestureDetector(
                              onTap: _deleteFromHistory,
                              child: Container(
                                height: 50.h,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(40.w),
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: AppColors.fullwhite,
                                        size: 22.sp,
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        "delete".tr,
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
                        ],
                      ),

                      SizedBox(height: 10.h),

                      // DOWNLOAD BUTTON
                      GestureDetector(
                        onTap: saveToGallery,
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
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
                                  color: AppColors.fullwhite,
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

                      SizedBox(height: 15.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleBackBtn() {
    return GestureDetector(
      onTap: () {
        Get.back();
      },
      child: Container(
        margin: EdgeInsets.only(left: 18.w),
        height: 30.w,
        width: 30.w,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.fullwhite,
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp),
      ),
    );
  }

  Widget _buildImageDisplay() {
    final imageUrl = widget.item['url'];
    if (imageUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 60, color: AppColors.grey),
            SizedBox(height: 10),
            Text("No image available".tr, style: TextStyle(fontSize: 15.sp)),
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
                  Icon(Icons.error, size: 40, color: Colors.red),
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

  Widget _infoChip({
    required IconData icon,
    required String text,
    bool isSmall = true,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12.w : 20.w,
        vertical: isSmall ? 8.h : 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white30,
        borderRadius: BorderRadius.circular(isSmall ? 20.w : 25.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 16.w : 20.w, color: AppColors.primary),
          SizedBox(width: isSmall ? 5.w : 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 12.sp : 16.sp,
              fontWeight: isSmall ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
