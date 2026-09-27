// import 'package:ai_emoji_maker/view/onboarding/onboarding_three.dart';
// import 'package:flutter/material.dart';
//
// import '../../utils/app_color.dart';
// import '../widgets/background_theme.dart';
//
// class OnboardingTwo extends StatelessWidget {
//   OnboardingTwo({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20, top: 0),
//             child: Text(
//               "Skip",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black.withOpacity(0.3),
//               ),
//             ),
//           ),
//         ],
//       ),
//
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: BoxDecoration(gradient: BackgroundTheme.background),
//
//         child: Column(
//           children: [
//             const SizedBox(height: 80),
//             Expanded(
//               flex: 6,
//               child: Stack(
//                 children: [
//                   Positioned.fill(
//                     child: Image.asset(
//                       "assets/images/emojis.png",
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//
//                   Align(alignment: Alignment.bottomCenter, child: ClipRect()),
//                 ],
//               ),
//             ),
//
//             //  Text Section
//             Expanded(
//               flex: 2,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text(
//                     "Choose Your Style",
//                     style: TextStyle(
//                       fontSize: 30,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   const Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 40),
//                     child: Text(
//                       "Classic, 3D, cartoon, kawaii, pixel, sticker\npick any emoji style you love.",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 14,
//                         height: 1,
//                         color: Colors.black54,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 28),
//
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       _dot(true),
//                       const SizedBox(width: 6),
//                       _dot(false),
//                       const SizedBox(width: 6),
//                       _dot(false),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 50),
//
//             //  Continue Button
//             Padding(
//               padding: const EdgeInsets.only(left: 22, right: 22, bottom: 40),
//               child: GestureDetector(
//                 onTap: () {
//                   // Navigate to your next screen
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => OnboardingThree()),
//                   );
//                 },
//                 child: Container(
//                   height: 55,
//                   decoration: BoxDecoration(
//                     color: AppColors.white30,
//                     borderRadius: BorderRadius.circular(50),
//                   ),
//                   child: const Center(
//                     child: Text(
//                       "Continue",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Dots
//   Widget _dot(bool active) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       width: active ? 22 : 10,
//       height: 6,
//       decoration: BoxDecoration(
//         color: active ? AppColors.primary : AppColors.primary.withOpacity(0.4),
//         borderRadius: BorderRadius.circular(30),
//       ),
//     );
//   }
// }

// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
//
// Future<String> _getLocalPath() async {
//   final directory = await getApplicationDocumentsDirectory();
//   return directory.path;
// }
//
// Future<File> _getLocalFile(String fileName) async {
//   final path = await _getLocalPath();
//   return File('$path/$fileName.png');
// }
//
// Future<void> saveImageLocally(String fileName, Uint8List bytes) async {
//   final file = await _getLocalFile(fileName);
//   await file.writeAsBytes(bytes, flush: true);
// }
//
// Future<Uint8List?> loadImageLocally(String fileName) async {
//   final file = await _getLocalFile(fileName);
//   if (await file.exists()) {
//     return await file.readAsBytes();
//   }
//   return null;
// }
//
// Future<Uint8List> _loadImage(String url, String id) async {
//   // Check local storage first
//   final cachedBytes = await loadImageLocally(id);
//   if (cachedBytes != null) {
//     return cachedBytes;
//   }
//
//   // Download from network
//   final response = await http.get(Uri.parse(url));
//   if (response.statusCode == 200) {
//     final bytes = response.bodyBytes;
//     // Save to local storage
//     await saveImageLocally(id, bytes);
//     return bytes;
//   }
//
//   throw Exception('Failed to load image');
// }
//
// import 'dart:convert';
// import 'dart:typed_data';
//
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
//
// class ImageCacheService {
//   static final ImageCacheService _instance = ImageCacheService._internal();
//   factory ImageCacheService() => _instance;
//   ImageCacheService._internal();
//
//   final GetStorage _storage = GetStorage();
//   final String _cacheKeyPrefix = 'cached_image_';
//
//   /// Get unique key for image URL
//   String _getCacheKey(String url) {
//     return '$_cacheKeyPrefix${url.hashCode}';
//   }
//
//   /// Check if image is cached
//   bool isImageCached(String url) {
//     return _storage.hasData(_getCacheKey(url));
//   }
//
//   /// Get cached image
//   Uint8List? getCachedImage(String url) {
//     try {
//       final cachedData = _storage.read<String>(_getCacheKey(url));
//       if (cachedData != null && cachedData.isNotEmpty) {
//         return base64Decode(cachedData);
//       }
//     } catch (e) {
//       print('Error reading cached image: $e');
//     }
//     return null;
//   }
//
//   /// Cache image from URL
//   Future<void> cacheImage(String url) async {
//     try {
//       // Skip if already cached
//       if (isImageCached(url)) return;
//
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         Uint8List bytes = response.bodyBytes;
//
//         // Optimize image
//         try {
//           final decodedImage = img.decodeImage(bytes);
//           if (decodedImage != null) {
//             bytes = Uint8List.fromList(img.encodePng(decodedImage));
//           }
//         } catch (e) {
//           print('Image optimization error: $e');
//         }
//
//         // Save to cache
//         await _storage.write(_getCacheKey(url), base64Encode(bytes));
//
//         print('✅ Image cached: ${_getCacheKey(url)}');
//       }
//     } catch (e) {
//       print('Error caching image: $e');
//     }
//   }
//
//   /// Cache multiple images
//   Future<void> cacheMultipleImages(List<String> urls) async {
//     for (final url in urls) {
//       await cacheImage(url);
//     }
//   }
//
//   /// Clear image cache
//   Future<void> clearCache() async {
//     final keys = _storage.getKeys();
//     for (final key in keys) {
//       if (key.startsWith(_cacheKeyPrefix)) {
//         await _storage.remove(key);
//       }
//     }
//   }
//
//   /// Get cache size info
//   Map<String, dynamic> getCacheInfo() {
//     final keys = _storage.getKeys();
//     final imageKeys = keys.where((key) => key.startsWith(_cacheKeyPrefix));
//     return {'count': imageKeys.length, 'keys': imageKeys.toList()};
//   }
import 'package:flutter/cupertino.dart';
class bpttpmview extends StatefulWidget {
  const bpttpmview({super.key});

  @override
  State<bpttpmview> createState() => _bpttpmviewState();
}

class _bpttpmviewState extends State<bpttpmview> {
  @override
  Widget build(BuildContext context) {
    return bpttpmview();
  }
}
