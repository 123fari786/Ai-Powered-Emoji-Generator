// lib/controller/generated_items_controller.dart
// lib/controller/generated_items_controller.dart
import 'package:ai_image_makerr/utils/app_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/database_services.dart';

class GeneratedItemsController extends GetxController {
  final LocalStorageService _storage = LocalStorageService();

  final RxList<Map<String, dynamic>> allItems = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;

  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    loadAllItems();
  }

  Future<void> loadAllItems() async {
    try {
      _isLoading.value = true;
      print(' Loading items from storage...');

      final items = await _storage.getAllItems();
      allItems.assignAll(items);
      searchResults.assignAll(items);

      print(' Loaded ${items.length} items from storage');
    } catch (e) {
      print(' Error loading items: $e');
      if (Get.context != null) {
        Get.snackbar(
          'Error'.tr,
          'Failed to load items'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 2),
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<String> saveGeneratedItem({
    required String url,
    required String prompt,
    required String type,
    required String style,
  }) async {
    try {
      // Generate unique ID
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final newItem = {
        'id': id,
        'url': url,
        'prompt': prompt,
        'type': type,
        'style': style,
        'isFavorite': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save to storage
      await _storage.saveItem(newItem);

      // Add to list immediately (don't wait for reload)
      allItems.insert(0, newItem);
      searchResults.insert(0, newItem);

      print(' Saved item: $type - $prompt');
      return id;
    } catch (e) {
      print(' Error saving item: $e');
      return '';
    }
  }

  // Regenerate and save item
  Future<String> regenerateAndSaveItem({
    required String oldId,
    required String newUrl,
    required String prompt,
    required String type,
    required String style,
    bool keepFavorite = true,
  }) async {
    try {
      // Get old item to preserve favorite status
      bool wasFavorite = false;
      final oldItem = getItemById(oldId);
      if (oldItem != null) {
        wasFavorite = oldItem['isFavorite'] == true;
      }

      // Generate new ID
      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      // Save regenerated item
      await _storage.saveItem({
        'id': newId,
        'url': newUrl,
        'prompt': prompt,
        'type': type,
        'style': style,
        'isFavorite': keepFavorite ? wasFavorite : false,
        'createdAt': DateTime.now().toIso8601String(),
        'regeneratedFrom': oldId, // Track regeneration source
      });

      // Reload items
      await loadAllItems();

      print(' Regenerated item from $oldId to $newId');
      return newId;
    } catch (e) {
      print(' Error regenerating item: $e');
      return '';
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _storage.deleteItem(id);
      await loadAllItems();
      print(' Deleted item: $id');
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to delete item');
      print(' Error deleting item: $e');
    }
  }

  Future<void> toggleFavorite(String id, bool fav) async {
    try {
      await _storage.toggleFavorite(id, fav);
      await loadAllItems();
      print(' Toggle favorite for: $id to $fav');
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to update favorite');
      print(' Error toggling favorite: $e');
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await _storage.clearAllItems();
      allItems.clear();
      searchResults.clear();
      print(' Cleared all history');
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to clear history');
      print(' Error clearing history: $e');
    }
  }

  Future<void> searchItems(String query) async {
    try {
      _isLoading.value = true;
      _searchQuery.value = query;

      if (query.isEmpty) {
        searchResults.assignAll(allItems);
      } else {
        final results = _storage.searchItems(query);
        searchResults.assignAll(results);
      }

      print(' Search results: ${searchResults.length} items for "$query"');
    } catch (e) {
      _showErrorSnackbar('Error', 'Search failed');
      print(' Error searching: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> clearSearch() async {
    _searchQuery.value = '';
    searchResults.assignAll(allItems);
  }

  // Get emoji items
  List<Map<String, dynamic>> get emojiItems {
    return allItems.where((item) => item['type'] == 'emoji').toList();
  }

  // Get sticker items
  List<Map<String, dynamic>> get stickerItems {
    return allItems.where((item) => item['type'] == 'sticker').toList();
  }

  List<Map<String, dynamic>> getRecentItems({int count = 10}) {
    try {
      // Sort by createdAt in descending order (newest first)
      final sortedItems = List<Map<String, dynamic>>.from(allItems)
        ..sort((a, b) {
          try {
            final dateA = DateTime.parse(a['createdAt'] ?? '');
            final dateB = DateTime.parse(b['createdAt'] ?? '');
            return dateB.compareTo(dateA); // Descending order
          } catch (e) {
            return 0;
          }
        });

      // Return only the required count
      return sortedItems.take(count).toList();
    } catch (e) {
      print('Error getting recent items: $e');
      return allItems.take(count).toList();
    }
  }

  // Get favorites
  List<Map<String, dynamic>> get favorites {
    return allItems.where((item) => item['isFavorite'] == true).toList();
  }

  // Get item by ID
  Map<String, dynamic>? getItemById(String id) {
    try {
      return allItems.firstWhereOrNull(
        (item) => item['id'].toString() == id.toString(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get similar items (same prompt or style)
  List<Map<String, dynamic>> getSimilarItems(
    String prompt,
    String style, {
    int limit = 5,
  }) {
    try {
      return allItems
          .where(
            (item) =>
                (item['prompt'] == prompt || item['style'] == style) &&
                item['id'] != null,
          )
          .take(limit)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Check if item exists (prevent duplicates)
  bool itemExists(String url, String prompt) {
    return allItems.any(
      (item) => item['url'] == url && item['prompt'] == prompt,
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Future.delayed(Duration.zero, () {
      if (Get.isSnackbarOpen) Get.back();
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText:  AppColors.fullwhite,
      );
    });
  }

  void _showSuccessSnackbar
      (String title, String message) {
    Future.delayed(Duration.zero, () {
      if (Get.isSnackbarOpen) Get.back();
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: AppColors.fullwhite,
      );
    });
  }

  @override
  void onClose() {
    super.onClose();
  }
}
