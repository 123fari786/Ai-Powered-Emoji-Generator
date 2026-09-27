// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:gal/gal.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
//
// import '../../models/generated_items_controller.dart';
// import '../../utils/app_color.dart';
// import '../../utils/reesposive.dart';
// // Import background theme
// import '../widgets/background_theme.dart'; // Add this import
//
// class MyEmojisPreviewScreen extends StatefulWidget {
//   final Map<String, dynamic> item;
//
//   const MyEmojisPreviewScreen({super.key, required this.item});
//
//   @override
//   State<MyEmojisPreviewScreen> createState() => _MyEmojisPreviewScreenState();
// }
//
// class _MyEmojisPreviewScreenState extends State<MyEmojisPreviewScreen> {
//   bool isLoading = false;
//   bool isSharing = false;
//   final Map<String, Uint8List> _imageCache = {};
//
//   // Image cache
//   Future<Uint8List> _loadNetworkImage(String url) async {
//     if (_imageCache.containsKey(url)) {
//       return _imageCache[url]!;
//     }
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final bytes = response.bodyBytes;
//         // Optimize image if needed
//         final decodedImage = img.decodeImage(bytes);
//         if (decodedImage != null) {
//           final optimizedBytes = img.encodePng(decodedImage);
//           _imageCache[url] = Uint8List.fromList(optimizedBytes);
//           return optimizedBytes;
//         }
//         _imageCache[url] = bytes;
//         return bytes;
//       }
//       throw Exception('Failed to load image: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Image load error: $e');
//     }
//   }
//
//   Future<void> saveToGallery() async {
//     try {
//       bool allowed = await Gal.requestAccess();
//       if (!allowed) {
//         Fluttertoast.showToast(msg: 'Permission denied'.tr);
//         return;
//       }
//
//       final imageUrl = widget.item['url'];
//       if (imageUrl.isEmpty) {
//         Fluttertoast.showToast(msg: 'No image to save'.tr);
//         return;
//       }
//
//       Uint8List imageBytes;
//       if (_imageCache.containsKey(imageUrl)) {
//         imageBytes = _imageCache[imageUrl]!;
//       } else {
//         final response = await http.get(Uri.parse(imageUrl));
//         if (response.statusCode != 200) {
//           throw Exception('Failed to download image');
//         }
//         imageBytes = response.bodyBytes;
//         _imageCache[imageUrl] = imageBytes;
//       }
//
//       await Gal.putImageBytes(imageBytes);
//       Fluttertoast.showToast(msg: 'savedToGallery'.tr);
//     } catch (e) {
//       print('Save to gallery error: $e');
//       Fluttertoast.showToast(msg: 'failedToSave'.tr);
//     }
//   }
//
//   Future<void> _shareImage() async {
//     try {
//       final imageUrl = widget.item['url'];
//       if (imageUrl.isEmpty) {
//         Fluttertoast.showToast(msg: 'No image to share'.tr);
//         return;
//       }
//
//       setState(() {
//         isSharing = true;
//       });
//
//       // Download image
//       final response = await http.get(Uri.parse(imageUrl));
//       if (response.statusCode == 200) {
//         // Save temporarily and share
//         final tempDir = await getTemporaryDirectory();
//         final file = File(
//           '${tempDir.path}/shared_${DateTime.now().millisecondsSinceEpoch}.png',
//         );
//         await file.writeAsBytes(response.bodyBytes);
//
//         await Share.shareXFiles(
//           [XFile(file.path)],
//           text:
//               widget.item['prompt']?.toString() ??
//               'Check out this emoji/sticker!',
//         );
//       } else {
//         throw Exception('Failed to download image');
//       }
//     } catch (e) {
//       print('Share error: $e');
//       Fluttertoast.showToast(msg: 'failedToShare'.tr);
//     } finally {
//       if (mounted) {
//         setState(() {
//           isSharing = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _deleteFromHistory() async {
//     try {
//       final itemsController = Get.find<GeneratedItemsController>();
//       final itemId = widget.item['id'].toString();
//
//       // Confirm deletion
//       bool confirm = await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Delete from History'.tr),
//           content: Text(
//             'Are you sure you want to delete this item from your history?'.tr,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: Text('Cancel'.tr),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: Text('Delete'.tr, style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         ),
//       );
//
//       if (confirm == true) {
//         await itemsController.deleteItem(itemId);
//         Fluttertoast.showToast(msg: 'Item deleted from history'.tr);
//
//         // Navigate back
//         Get.back();
//       }
//     } catch (e) {
//       print('Delete error: $e');
//       Fluttertoast.showToast(msg: 'Failed to delete item'.tr);
//     }
//   }
//
//   String _getStyleName(String style) {
//     // Map style names to display names
//     final styleMap = {
//       'Classic': 'Classic',
//       'Cartoon': 'Cartoon',
//       'Pixel': 'Pixel',
//       'Line Art': 'Line Art',
//       '3D': '3D',
//       'Pastel': 'Pastel',
//       'Minmal': 'Minimal',
//       'Sketch': 'Sketch',
//       'Anime': 'Anime',
//       'classic_style': 'Classic',
//     };
//     return styleMap[style] ?? style;
//   }
//
//   String _getFormattedDate(String dateString) {
//     try {
//       final date = DateTime.parse(dateString);
//       final months = [
//         'Jan',
//         'Feb',
//         'Mar',
//         'Apr',
//         'May',
//         'Jun',
//         'Jul',
//         'Aug',
//         'Sep',
//         'Oct',
//         'Nov',
//         'Dec',
//       ];
//       return '${date.day} ${months[date.month - 1]} ${date.year}';
//     } catch (e) {
//       return dateString;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     ResponsiveConfig.init(context);
//
//     return Scaffold(
//       // Apply background theme here
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: BoxDecoration(gradient: BackgroundTheme.background),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // App Bar - Fixed height without extra padding
//               Container(
//                 height: 60.h,
//                 child: Row(
//                   children: [
//                     // Back Button
//                     _circleBackBtn(),
//
//                     // Title (centered)
//                     Expanded(
//                       child: Center(
//                         child: Text(
//                           'preview'.tr,
//                           style: TextStyle(
//                             fontSize: 24.sp,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     // Empty space for alignment
//                     Container(width: 40.w, height: 40.w),
//                   ],
//                 ),
//               ),
//
//               // Body Content - No top padding
//               Expanded(
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 20.w),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // TOP IMAGE BOX
//                       Container(
//                         width: double.infinity,
//                         height: 290.h,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(22.w),
//                         ),
//                         child: _buildImageDisplay(),
//                       ),
//
//                       SizedBox(height: 15.h),
//
//                       // Prompt Section
//                       if (widget.item['prompt'] != null &&
//                           widget.item['prompt'].toString().isNotEmpty) ...[
//                         Text(
//                           "prompt".tr,
//                           style: TextStyle(
//                             fontSize: 19.sp,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.black,
//                           ),
//                         ),
//                         SizedBox(height: 10.h),
//                         Container(
//                           width: double.infinity,
//                           height: 110.h, // Fixed height for 4 lines
//                           padding: EdgeInsets.all(9.w),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(22.w),
//                           ),
//                           child: Scrollbar(
//                             child: SingleChildScrollView(
//                               child: Text(
//                                 widget.item['prompt'].toString(),
//                                 style: TextStyle(
//                                   fontSize: 15.sp,
//                                   height: 1.45,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 25.h),
//                       ],
//
//                       // Info Section
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           // Type
//                           _infoChip(
//                             icon: widget.item['type'] == 'sticker'
//                                 ? Icons.sticky_note_2
//                                 : Icons.emoji_emotions,
//                             text: (widget.item['type'] ?? 'item')
//                                 .toString()
//                                 .capitalizeFirst!,
//                           ),
//
//                           // Date
//                           _infoChip(
//                             icon: Icons.calendar_today,
//                             text: _getFormattedDate(
//                               widget.item['createdAt'].toString(),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const Spacer(),
//
//                       // SHARE AND DELETE BUTTONS ROW
//                       Row(
//                         children: [
//                           // SHARE BUTTON
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: isSharing ? null : _shareImage,
//                               child: Container(
//                                 height: 50.h,
//                                 decoration: BoxDecoration(
//                                   color: AppColors.primary, // ✅ fill color
//                                   borderRadius: BorderRadius.circular(40.w),
//                                   border: Border.all(
//                                     color: AppColors.primary,
//                                     width: 2,
//                                   ),
//                                 ),
//                                 child: Center(
//                                   child: isSharing
//                                       ? SizedBox(
//                                           width: 22.w,
//                                           height: 22.w,
//                                           child: CircularProgressIndicator(
//                                             strokeWidth: 2,
//                                             color:
//                                                 Colors.white, // ✅ loader white
//                                           ),
//                                         )
//                                       : Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             Icon(
//                                               Icons.share,
//                                               color: Colors.white, // ✅
//                                               size: 22.sp,
//                                             ),
//                                             SizedBox(width: 10.w),
//                                             Text(
//                                               "share".tr,
//                                               style: TextStyle(
//                                                 fontSize: 18.sp,
//                                                 fontWeight: FontWeight.w600,
//                                                 color: Colors.white, // ✅
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           SizedBox(width: 15.w),
//
//                           // DELETE BUTTON
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: _deleteFromHistory,
//                               child: Container(
//                                 height: 50.h,
//                                 decoration: BoxDecoration(
//                                   color: Colors.red, // ✅ fill color
//                                   borderRadius: BorderRadius.circular(40.w),
//                                   border: Border.all(
//                                     color: Colors.red,
//                                     width: 2,
//                                   ),
//                                 ),
//                                 child: Center(
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(
//                                         Icons.delete_outline,
//                                         color: Colors.white, // ✅
//                                         size: 22.sp,
//                                       ),
//                                       SizedBox(width: 10.w),
//                                       Text(
//                                         "delete".tr,
//                                         style: TextStyle(
//                                           fontSize: 18.sp,
//                                           fontWeight: FontWeight.w600,
//                                           color: Colors.white, // ✅
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       SizedBox(height: 10.h),
//
//                       // DOWNLOAD BUTTON
//                       GestureDetector(
//                         onTap: saveToGallery,
//                         child: Container(
//                           width: double.infinity,
//                           height: 50.h,
//                           decoration: BoxDecoration(
//                             color: AppColors.primary,
//                             borderRadius: BorderRadius.circular(40.w),
//                           ),
//                           child: Center(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Image.asset(
//                                   'assets/icons/download.png',
//                                   width: 22.w,
//                                   height: 22.h,
//                                   color: Colors.white,
//                                 ),
//                                 SizedBox(width: 10.w),
//                                 Text(
//                                   "download".tr,
//                                   style: TextStyle(
//                                     fontSize: 18.sp,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       SizedBox(height: 15.h),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _circleBackBtn() {
//     return GestureDetector(
//       onTap: () {
//         Get.back();
//       },
//       child: Container(
//         margin: EdgeInsets.only(left: 18.w),
//         height: 30.w,
//         width: 30.w,
//         decoration: const BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.white,
//         ),
//         child: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp),
//       ),
//     );
//   }
//
//   Widget _buildImageDisplay() {
//     final imageUrl = widget.item['url'];
//     if (imageUrl.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.image, size: 60, color: AppColors.grey),
//             SizedBox(height: 10),
//             Text("No image available".tr, style: TextStyle(fontSize: 15.sp)),
//           ],
//         ),
//       );
//     }
//
//     return FutureBuilder<Uint8List>(
//       future: _loadNetworkImage(imageUrl),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Container(
//             color: AppColors.white30,
//             child: Center(
//               child: CircularProgressIndicator(color: AppColors.primary),
//             ),
//           );
//         }
//
//         if (snapshot.hasError) {
//           return Container(
//             color: AppColors.white30,
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error, size: 40, color: Colors.red),
//                   SizedBox(height: 10),
//                   Text("Failed to load image".tr),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         if (snapshot.hasData) {
//           return Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(26.w),
//               color: AppColors.white30,
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(26.w),
//               child: Image.memory(snapshot.data!, fit: BoxFit.contain),
//             ),
//           );
//         }
//
//         return Container(
//           color: AppColors.white30,
//           child: Center(
//             child: CircularProgressIndicator(color: AppColors.primary),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _infoChip({required IconData icon, required String text}) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
//       decoration: BoxDecoration(
//         color: AppColors.white30,
//         borderRadius: BorderRadius.circular(20.w),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16.w, color: AppColors.primary),
//           SizedBox(width: 5.w),
//           Text(text, style: TextStyle(fontSize: 12.sp)),
//         ],
//       ),
//     );
//   }
// }
import 'package:get/get.dart';

class BottomBarController extends GetxController {
  RxInt currentIndex = 0.obs;

  void changeIndex(int index) {
    currentIndex.value = index;
  }
}
