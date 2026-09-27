// // lib/services/local_storage_service.dart
// import 'package:get_storage/get_storage.dart';
//
// class LocalStorageService {
//   static final LocalStorageService _instance = LocalStorageService._internal();
//   factory LocalStorageService() => _instance;
//   LocalStorageService._internal();
//
//   final GetStorage _storage = GetStorage();
//   final String _itemsKey = 'generated_items';
//
//   /// Save generated item
//   Future<void> saveItem(Map<String, dynamic> item) async {
//     try {
//       // Get existing items
//       List<dynamic> existingItems =
//           _storage.read<List<dynamic>>(_itemsKey) ?? [];
//
//       // Add new item with unique ID
//       final newItem = {
//         ...item,
//         'id': DateTime.now().millisecondsSinceEpoch,
//         'createdAt': DateTime.now().toIso8601String(),
//       };
//
//       existingItems.insert(0, newItem); // Add to beginning for recent first
//
//       // Save back
//       await _storage.write(_itemsKey, existingItems);
//       print('✅ Item saved to local storage');
//     } catch (e) {
//       print('❌ Error saving item: $e');
//     }
//   }
//
//   /// Get all items
//   List<Map<String, dynamic>> getAllItems() {
//     try {
//       final items = _storage.read<List<dynamic>>(_itemsKey) ?? [];
//       return items.cast<Map<String, dynamic>>();
//     } catch (e) {
//       print('❌ Error getting items: $e');
//       return [];
//     }
//   }
//
//   /// Delete item by ID
//   Future<void> deleteItem(String id) async {
//     try {
//       final items = getAllItems();
//       items.removeWhere((item) => item['id'] == id);
//       await _storage.write(_itemsKey, items);
//       print('✅ Item deleted from local storage');
//     } catch (e) {
//       print('❌ Error deleting item: $e');
//     }
//   }
//
//   /// Toggle favorite status
//   Future<void> toggleFavorite(String id, bool isFavorite) async {
//     try {
//       final items = getAllItems();
//       final index = items.indexWhere((item) => item['id'] == id);
//       if (index != -1) {
//         items[index]['isFavorite'] = isFavorite;
//         await _storage.write(_itemsKey, items);
//         print('✅ Favorite status updated');
//       }
//     } catch (e) {
//       print('❌ Error toggling favorite: $e');
//     }
//   }
//
//   /// Clear all items
//   Future<void> clearAllItems() async {
//     await _storage.write(_itemsKey, []);
//     print('✅ All items cleared from local storage');
//   }
//
//   /// Search items by prompt
//   List<Map<String, dynamic>> searchItems(String query) {
//     try {
//       if (query.isEmpty) return getAllItems();
//
//       final items = getAllItems();
//       return items.where((item) {
//         final prompt = (item['prompt'] ?? '').toString().toLowerCase();
//         return prompt.contains(query.toLowerCase());
//       }).toList();
//     } catch (e) {
//       print('❌ Error searching items: $e');
//       return [];
//     }
//   }
//
//   /// Get favorite items only
//   List<Map<String, dynamic>> getFavorites() {
//     try {
//       final items = getAllItems();
//       return items.where((item) => item['isFavorite'] == true).toList();
//     } catch (e) {
//       print('❌ Error getting favorites: $e');
//       return [];
//     }
//   }
//
//   /// Get items by type (emoji/sticker)
//   List<Map<String, dynamic>> getItemsByType(String type) {
//     try {
//       final items = getAllItems();
//       return items.where((item) => item['type'] == type).toList();
//     } catch (e) {
//       print('❌ Error getting items by type: $e');
//       return [];
//     }
//   }
//
//   /// Get recent items
//   List<Map<String, dynamic>> getRecentItems({int count = 10}) {
//     try {
//       final items = getAllItems();
//       return items.take(count).toList();
//     } catch (e) {
//       print('❌ Error getting recent items: $e');
//       return [];
//     }
//   }
// }

import 'dart:typed_data';

import 'package:get_storage/get_storage.dart';

import 'image_cache_services.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  final GetStorage _storage = GetStorage();
  final ImageCacheService _imageCache = ImageCacheService();
  final String _itemsKey = 'generated_items';

  /// Save generated item with image caching
  Future<void> saveItem(Map<String, dynamic> item) async {
    try {
      // Get existing items
      List<dynamic> existingItems =
          _storage.read<List<dynamic>>(_itemsKey) ?? [];

      // Add new item with unique ID
      final newItem = {
        ...item,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'createdAt': DateTime.now().toIso8601String(),
        'isFavorite': item['isFavorite'] ?? false,
      };

      // Add to beginning for recent first
      existingItems.insert(0, newItem);

      // Save back
      await _storage.write(_itemsKey, existingItems);

      // Cache the image in background
      if (item['url'] != null && item['url'].toString().isNotEmpty) {
        _imageCache.cacheImage(item['url']);
      }

      print(' Item saved to local storage with ID: ${newItem['id']}');
    } catch (e) {
      print(' Error saving item: $e');
    }
  }

  /// Get all items with cached images
  List<Map<String, dynamic>> getAllItems() {
    try {
      final items = _storage.read<List<dynamic>>(_itemsKey) ?? [];
      final itemList = items.cast<Map<String, dynamic>>();

      // Pre-cache all images in background
      final urls = itemList
          .where((item) => item['url'] != null)
          .map((item) => item['url'].toString())
          .toList();

      if (urls.isNotEmpty) {
        _imageCache.cacheMultipleImages(urls);
      }

      return itemList;
    } catch (e) {
      print(' Error getting items: $e');
      return [];
    }
  }

  /// Delete item by ID
  Future<void> deleteItem(String id) async {
    try {
      final items = getAllItems();
      items.removeWhere((item) => item['id'] == id);
      await _storage.write(_itemsKey, items);
      print(' Item deleted from local storage');
    } catch (e) {
      print(' -------------------------Error deleting item: $e');
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      final items = getAllItems();
      final index = items.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        items[index]['isFavorite'] = isFavorite;
        await _storage.write(_itemsKey, items);
        print(' Favorite status updated');
      }
    } catch (e) {
      print('----------------------- Error toggling favorite: $e');
    }
  }

  /// Clear all items
  Future<void> clearAllItems() async {
    await _storage.write(_itemsKey, []);
    print('------------------ All items cleared from local storage');
  }

  /// Search items by prompt
  List<Map<String, dynamic>> searchItems(String query) {
    try {
      if (query.isEmpty) return getAllItems();

      final items = getAllItems();
      return items.where((item) {
        final prompt = (item['prompt'] ?? '').toString().toLowerCase();
        final type = (item['type'] ?? '').toString().toLowerCase();
        return prompt.contains(query.toLowerCase()) ||
            type.contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('0-------- Error searching items: $e');
      return [];
    }
  }

  /// Get cached image for item
  Uint8List? getCachedImageForItem(Map<String, dynamic> item) {
    if (item['url'] == null) return null;
    return _imageCache.getCachedImage(item['url']);
  }

  /// Check if item image is cached
  bool isItemImageCached(Map<String, dynamic> item) {
    if (item['url'] == null) return false;
    return _imageCache.isImageCached(item['url']);
  }

  /// Get favorite items only
  List<Map<String, dynamic>> getFavorites() {
    try {
      final items = getAllItems();
      return items.where((item) => item['isFavorite'] == true).toList();
    } catch (e) {
      print(' Error getting favorites: $e');
      return [];
    }
  }

  /// Get items by type (emoji/sticker)
  List<Map<String, dynamic>> getItemsByType(String type) {
    try {
      final items = getAllItems();
      return items.where((item) => item['type'] == type).toList();
    } catch (e) {
      print(' Error getting items by type: $e');
      return [];
    }
  }

  /// Get recent items (sorted by date)
  List<Map<String, dynamic>> getRecentItems({int count = 10}) {
    try {
      final items = getAllItems();

      // Sort by date (newest first)
      items.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['createdAt'] ?? '');
          final dateB = DateTime.parse(b['createdAt'] ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      return items.take(count).toList();
    } catch (e) {
      print(' Error getting recent items: $e');
      return [];
    }
  }

  /// Get item by ID
  Map<String, dynamic>? getItemById(String id) {
    try {
      final items = getAllItems();
      return items.firstWhere((item) => item['id'] == id);
    } catch (e) {
      return null;
    }
  }
}
