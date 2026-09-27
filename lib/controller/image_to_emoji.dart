import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/generated_items_controller.dart';

class ImageToEmojiController extends GetxController {
  // Variables
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString imageUrl = ''.obs;
  RxString imageNetworkUrl = ''.obs; // Added for base64 image
  RxString generatedEmojiUrl = ''.obs;
  RxString promptText = ''.obs;
  RxInt selectedStyle = 0.obs;

  final ImagePicker _picker = ImagePicker();

  // API Configuration
  final String apiUrl =
      'https://ai-image-service-hi5b6srqfq-uc.a.run.app/image-to-emoji';
  final String apiKey = 'pk_7cecaa59e7bd4860b566fcf4382de14c';

  // Style names
  final List<String> styleNames = ['Classic', 'Cartoon', 'Pixel', 'Line Art'];

  // Save generated emoji to database
  Future<void> _saveToHistory(String imageUrl) async {
    try {
      final itemsController = Get.find<GeneratedItemsController>();
      await itemsController.saveGeneratedItem(
        url: imageUrl,
        prompt: promptText.value.isNotEmpty
            ? promptText.value
            : 'Image to Emoji',
        type: 'emoji',
        style: styleNames[selectedStyle.value],
      );
      print(' Image-to-Emoji saved to history');
    } catch (e) {
      print(' Error saving to history: $e');
    }
  }

  // Pick Image From Gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedImage != null) {
        imageUrl.value = pickedImage.path;
        print(" Picked Image: ${imageUrl.value}");
        await _uploadImageToServer();
      } else {
        print("⚠ No image selected");
      }
    } catch (e) {
      print(" Image Pick Error: $e");
    }
  }

  // Upload image to server and convert to base64
  Future<void> _uploadImageToServer() async {
    if (imageUrl.isEmpty) return;

    try {
      isLoading.value = true;
      final dataUrl = await _convertToDataUrl();
      if (dataUrl.isNotEmpty) {
        imageNetworkUrl.value = dataUrl;
        print(" Image converted to base64");
      } else {
        print(" Failed to convert image to base64");
      }
    } catch (e) {
      print(" Upload error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> _convertToDataUrl() async {
    try {
      final file = File(imageUrl.value);
      if (!await file.exists()) {
        return '';
      }

      final bytes = await file.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        print("⚠ Image too large: ${bytes.length / 1024 / 1024} MB");
        return '';
      }

      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageUrl.value);

      return 'data:$mimeType;base64,$base64Image';
    } catch (e) {
      print("Base64 conversion error: $e");
      return '';
    }
  }

  String _getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  void setPromptText(String text) {
    promptText.value = text;
  }

  void setSelectedStyle(int style) {
    selectedStyle.value = style;
  }

  // Clear selected image only
  void clearSelectedImage() {
    imageUrl.value = '';
    imageNetworkUrl.value = ''; // Clear base64 image too
  }

  // Clear all data
  void clearAllData() {
    clearSelectedImage();
    generatedEmojiUrl.value = '';
    errorMessage.value = '';
    promptText.value = '';
    selectedStyle.value = 0;
  }

  // Generate Emoji API Call - MODIFIED to keep image for regenerate
  Future<bool> generateEmoji() async {
    if (imageUrl.isEmpty) {
      errorMessage.value = 'Please select an image first'.tr;
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';
    generatedEmojiUrl.value = '';

    try {
      String imageUrlForApi;

      if (imageNetworkUrl.isNotEmpty) {
        imageUrlForApi = imageNetworkUrl.value;
      } else {
        imageUrlForApi = await _convertToDataUrl();
        if (imageUrlForApi.isEmpty) {
          errorMessage.value = 'Failed to process image'.tr;
          return false;
        }
      }

      print(" Sending request to Emoji API...");

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers['X-Api-Key'] = apiKey;
      request.fields['image_url'] = imageUrlForApi;
      request.fields['style'] = styleNames[selectedStyle.value];
      request.fields['prompt'] = promptText.value;
      request.fields['appID'] = "mobile";

      final streamedResponse = await request.send().timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print(' API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(" Response data: $data");

        if (data is Map) {
          String? newImageUrl;

          if (data.containsKey('image_url')) {
            newImageUrl = data['image_url'];
          } else if (data.containsKey('emoji_url')) {
            newImageUrl = data['emoji_url'];
          } else if (data.containsKey('url')) {
            newImageUrl = data['url'];
          } else {
            // Try to find any URL in response
            for (var key in data.keys) {
              if (key.toString().toLowerCase().contains('url')) {
                newImageUrl = data[key].toString();
                break;
              }
            }
          }

          if (newImageUrl != null && newImageUrl.isNotEmpty) {
            generatedEmojiUrl.value = newImageUrl;
            print(" Emoji Generated URL: $newImageUrl");

            // Auto-save to history
            await _saveToHistory(newImageUrl);

            return true;
          } else {
            errorMessage.value = "no_url_found".tr;
            return false;
          }
        } else {
          errorMessage.value = "invalid_response_format".tr;
          return false;
        }
      } else {
        errorMessage.value = "Please choose Actual Image".tr;
        return false;
      }
    } on TimeoutException {
      errorMessage.value = "request_timeout".tr;
      return false;
    } on SocketException {
      errorMessage.value = "noInternet".tr;
      return false;
    } on http.ClientException {
      errorMessage.value = "network_error".tr;
      return false;
    } catch (e) {
      errorMessage.value = "Error: ${e.toString()}".tr;
      print(" API Error: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // New method for regenerate functionality from result screen
  Future<bool> regenerateEmoji() async {
    // Check if we still have the original image
    if (imageUrl.isEmpty && imageNetworkUrl.isEmpty) {
      errorMessage.value = 'Original image not available for regeneration'.tr;
      return false;
    }

    return await generateEmoji();
  }
}
