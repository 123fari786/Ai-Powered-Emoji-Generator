import 'dart:convert';
import 'dart:typed_data';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final GetStorage _storage = GetStorage();
  final String _cacheKeyPrefix = 'cached_image_';

  // Get unique key for image URL
  String _getCacheKey(String url) {
    return '$_cacheKeyPrefix${url.hashCode}';
  }

  /// Check if image is cached
  bool isImageCached(String url) {
    return _storage.hasData(_getCacheKey(url));
  }

  /// Get cached image
  Uint8List? getCachedImage(String url) {
    try {
      final cachedData = _storage.read<String>(_getCacheKey(url));
      if (cachedData != null && cachedData.isNotEmpty) {
        return base64Decode(cachedData);
      }
    } catch (e) {
      print('Error reading cached image: $e');
    }
    return null;
  }

  /// Cache image from URL
  Future<void> cacheImage(String url) async {
    try {
      // Skip if already cached
      if (isImageCached(url)) return;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Uint8List bytes = response.bodyBytes;

        // Optimize image
        try {
          final decodedImage = img.decodeImage(bytes);
          if (decodedImage != null) {
            bytes = Uint8List.fromList(img.encodePng(decodedImage));
          }
        } catch (e) {
          print('Image optimization error: $e');
        }

        // Save to cache
        await _storage.write(_getCacheKey(url), base64Encode(bytes));

        print(' Image cached: ${_getCacheKey(url)}');
      }
    } catch (e) {
      print('Error caching image: $e');
    }
  }

  /// Cache multiple images
  Future<void> cacheMultipleImages(List<String> urls) async {
    for (final url in urls) {
      await cacheImage(url);
    }
  }

  /// Clear image cache
  Future<void> clearCache() async {
    final keys = _storage.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cacheKeyPrefix)) {
        await _storage.remove(key);
      }
    }
  }

  /// Get cache size info
  Map<String, dynamic> getCacheInfo() {
    final keys = _storage.getKeys();
    final imageKeys = keys.where((key) => key.startsWith(_cacheKeyPrefix));
    return {'count': imageKeys.length, 'keys': imageKeys.toList()};
  }
}
