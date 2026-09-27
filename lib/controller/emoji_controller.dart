import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/generated_items_controller.dart';

class EmojiController extends GetxController {
  // Variables
  RxInt selectedStyleIndex = 1.obs;
  RxString promptText = ''.obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString imageUrl = ''.obs;
  RxBool isRegenerating = false.obs;

  // API Configuration
  final String apiUrl =
      'https://ai-image-service-hi5b6srqfq-uc.a.run.app/ai-prompt-emoji';
  final String apiKey = 'pk_7cecaa59e7bd4860b566fcf4382de14c';

  // Style mapping
  final Map<int, String> styleMap = {
    0: 'classic',
    1: 'cartoon',
    2: 'pixel',
    3: 'lineart',
  };

  // Style name mapping for display
  final Map<int, String> styleDisplayNames = {
    0: 'Classic',
    1: 'Cartoon',
    2: 'Pixel',
    3: 'Line Art',
  };

  // Set selected style
  void setSelectedStyle(int index) {
    selectedStyleIndex.value = index;
  }

  // Set prompt text
  void setPromptText(String text) {
    promptText.value = text;
  }

  // Save generated emoji to database
  Future<void> _saveToHistory(String imageUrl) async {
    try {
      final itemsController = Get.find<GeneratedItemsController>();
      await itemsController.saveGeneratedItem(
        url: imageUrl,
        prompt: promptText.value,
        type: 'emoji',
        style: styleDisplayNames[selectedStyleIndex.value] ?? 'Cartoon',
      );
      print(' Emoji saved to history');
    } catch (e) {
      print(' Error saving to history: $e');
    }
  }

  // Core API Call
  Future<bool> _callApi() async {
    try {
      final Map<String, dynamic> requestBody = {
        'prompt': promptText.value,
        'style': styleMap[selectedStyleIndex.value] ?? 'cartoon',
        'appID': 'mobile',
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'X-Api-Key': apiKey},
        body: json.encode(requestBody),
      );

      print(' API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is Map && responseData.containsKey('image_url')) {
          final newImageUrl = responseData['image_url'];
          imageUrl.value = newImageUrl;
          print(' Image URL: $newImageUrl');

          // Auto-save to history
          await _saveToHistory(newImageUrl);
          return true;
        } else {
          errorMessage.value = 'no_url_found'.tr;
          return false;
        }
      } else {
        errorMessage.value = 'Please Choose Actual Image';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Network error: ${e.toString()}';
      print(' Error: $e');
      return false;
    }
  }

  // First-time generation
  Future<bool> generateEmoji() async {
    if (promptText.isEmpty) {
      errorMessage.value = 'Please enter a prompt';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';
    imageUrl.value = '';

    final success = await _callApi();
    isLoading.value = false;

    return success;
  }

  // Regenerate using same prompt + style
  Future<bool> regenerateEmoji() async {
    if (promptText.isEmpty) {
      errorMessage.value = 'Prompt missing (regen)';
      return false;
    }

    isRegenerating.value = true;
    errorMessage.value = '';

    final success = await _callApi();
    isRegenerating.value = false;

    return success;
  }

  // Clear all data
  void clearData() {
    promptText.value = '';
    imageUrl.value = '';
    errorMessage.value = '';
  }
}
