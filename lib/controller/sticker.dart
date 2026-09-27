// // lib/controllers/sticker_controller.dart
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
//
// import '../models/generated_items_controller.dart';
//
// class StickerController extends GetxController {
//   // Variables
//   RxBool isLoading = false.obs;
//   RxString errorMessage = ''.obs;
//   RxString imageUrl = ''.obs;
//   RxString imageNetworkUrl = ''.obs;
//   RxString generatedStickerUrl = ''.obs;
//   RxString promptText = ''.obs;
//   RxInt selectedStyle = 1.obs;
//
//   final ImagePicker _picker = ImagePicker();
//
//   // API Configuration
//   final String stickerApiUrl =
//       'https://ai-image-service-hi5b6srqfq-uc.a.run.app/image-to-sticker';
//   final String apiKey = 'pk_7cecaa59e7bd4860b566fcf4382de14c';
//
//   // Style names
//   final List<String> styleNames = ['Classic', 'Cartoon', 'Pixel', 'Line Art'];
//
//   // Save generated sticker to database
//   Future<void> _saveToHistory(String imageUrl) async {
//     try {
//       final itemsController = Get.find<GeneratedItemsController>();
//       await itemsController.saveGeneratedItem(
//         url: imageUrl,
//         prompt: promptText.value.isNotEmpty
//             ? promptText.value
//             : 'Image to Sticker',
//         type: 'sticker',
//         style: styleNames[selectedStyle.value],
//       );
//       print('✅ Sticker saved to history');
//     } catch (e) {
//       print('❌ Error saving to history: $e');
//     }
//   }
//
//   // Pick Image From Gallery
//   Future<void> pickImageFromGallery() async {
//     try {
//       final XFile? pickedImage = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 85,
//         maxWidth: 1024,
//         maxHeight: 1024,
//       );
//
//       if (pickedImage != null) {
//         imageUrl.value = pickedImage.path;
//         print("📸 Picked Image: ${imageUrl.value}");
//         await _uploadImageToServer();
//       }
//     } catch (e) {
//       print("❌ Image Pick Error: $e");
//     }
//   }
//
//   Future<void> _uploadImageToServer() async {
//     if (imageUrl.isEmpty) return;
//
//     try {
//       isLoading.value = true;
//       final dataUrl = await _convertToDataUrl();
//       if (dataUrl.isNotEmpty) {
//         imageNetworkUrl.value = dataUrl;
//         print("✅ Image converted to base64");
//       }
//     } catch (e) {
//       print("❌ Upload error: $e");
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   Future<String> _convertToDataUrl() async {
//     try {
//       final file = File(imageUrl.value);
//       final bytes = await file.readAsBytes();
//
//       if (bytes.length > 5 * 1024 * 1024) {
//         return '';
//       }
//
//       final base64Image = base64Encode(bytes);
//       final mimeType = _getMimeType(imageUrl.value);
//       return 'data:$mimeType;base64,$base64Image';
//     } catch (e) {
//       return '';
//     }
//   }
//
//   String _getMimeType(String filePath) {
//     final ext = filePath.split('.').last.toLowerCase();
//     switch (ext) {
//       case 'jpg':
//       case 'jpeg':
//         return 'image/jpeg';
//       case 'png':
//         return 'image/png';
//       case 'gif':
//         return 'image/gif';
//       default:
//         return 'image/jpeg';
//     }
//   }
//
//   void setPromptText(String text) {
//     promptText.value = text;
//   }
//
//   void setSelectedStyle(int style) {
//     selectedStyle.value = style;
//   }
//
//   // Generate Sticker API Call
//   Future<bool> generateSticker() async {
//     if (imageUrl.isEmpty) {
//       errorMessage.value = 'Please select an image first'.tr;
//       return false;
//     }
//
//     isLoading.value = true;
//     errorMessage.value = '';
//     generatedStickerUrl.value = '';
//
//     try {
//       String imageUrlForApi;
//
//       if (imageNetworkUrl.isNotEmpty) {
//         imageUrlForApi = imageNetworkUrl.value;
//       } else {
//         imageUrlForApi = await _convertToDataUrl();
//         if (imageUrlForApi.isEmpty) {
//           errorMessage.value = 'Failed to process image'.tr;
//           return false;
//         }
//       }
//
//       print("📤 Sending request to API...");
//
//       var request = http.MultipartRequest('POST', Uri.parse(stickerApiUrl));
//       request.headers['X-Api-Key'] = apiKey;
//       request.fields['image_url'] = imageUrlForApi;
//       request.fields['prompt'] = promptText.value;
//       request.fields['style'] = styleNames[selectedStyle.value];
//       request.fields['appID'] = "mobile";
//
//       final streamedResponse = await request.send().timeout(
//         Duration(seconds: 60),
//         onTimeout: () {
//           throw TimeoutException('Request timeout');
//         },
//       );
//
//       final response = await http.Response.fromStream(streamedResponse);
//
//       print('📥 API Response: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         print("🔍 Response data: $data");
//
//         if (data is Map) {
//           String? newImageUrl;
//
//           if (data.containsKey('image_url')) {
//             newImageUrl = data['image_url'];
//           } else if (data.containsKey('sticker_url')) {
//             newImageUrl = data['sticker_url'];
//           } else {
//             // Try to find any URL in response
//             for (var key in data.keys) {
//               if (key.toString().toLowerCase().contains('url')) {
//                 newImageUrl = data[key].toString();
//                 break;
//               }
//             }
//           }
//
//           if (newImageUrl != null && newImageUrl.isNotEmpty) {
//             generatedStickerUrl.value = newImageUrl;
//             print("✅ Sticker Generated URL: $newImageUrl");
//
//             // Auto-save to history
//             await _saveToHistory(newImageUrl);
//             return true;
//           } else {
//             errorMessage.value = "no_url_found".tr;
//             return false;
//           }
//         } else {
//           errorMessage.value = "invalid_response_format".tr;
//           return false;
//         }
//       } else {
//         errorMessage.value = "Server error: ${response.statusCode}".tr;
//         return false;
//       }
//     } on TimeoutException {
//       errorMessage.value = "request_timeout".tr;
//       return false;
//     } on SocketException {
//       errorMessage.value = "noInternet".tr;
//       return false;
//     } on http.ClientException {
//       errorMessage.value = "network_error".tr;
//       return false;
//     } catch (e) {
//       errorMessage.value = "Error: ${e.toString()}".tr;
//       print("❌ API Error: $e");
//       return false;
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   // Clear all data
//   void clearData() {
//     imageUrl.value = '';
//     imageNetworkUrl.value = '';
//     generatedStickerUrl.value = '';
//     errorMessage.value = '';
//     promptText.value = '';
//     selectedStyle.value = 1;
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/generated_items_controller.dart';

class StickerController extends GetxController {
  // Variables
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString imageUrl = ''.obs;
  RxString imageNetworkUrl = ''.obs;
  RxString generatedStickerUrl = ''.obs;
  RxString promptText = ''.obs;
  RxInt selectedStyle = 0.obs;

  final ImagePicker _picker = ImagePicker();

  // API Configuration
  final String stickerApiUrl =
      'https://ai-image-service-hi5b6srqfq-uc.a.run.app/image-to-sticker';
  final String apiKey = 'pk_7cecaa59e7bd4860b566fcf4382de14c';

  // Style names
  final List<String> styleNames = ['Classic', 'Cartoon', 'Pixel', 'Line Art'];

  // Save generated sticker to database
  Future<void> _saveToHistory(String imageUrl) async {
    try {
      final itemsController = Get.find<GeneratedItemsController>();
      await itemsController.saveGeneratedItem(
        url: imageUrl,
        prompt: promptText.value.isNotEmpty
            ? promptText.value
            : 'Image to Sticker',
        type: 'sticker',
        style: styleNames[selectedStyle.value],
      );
      print(' Sticker saved to history');
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
      }
    } catch (e) {
      print(" Image Pick Error: $e");
    }
  }

  Future<void> _uploadImageToServer() async {
    if (imageUrl.isEmpty) return;

    try {
      isLoading.value = true;
      final dataUrl = await _convertToDataUrl();
      if (dataUrl.isNotEmpty) {
        imageNetworkUrl.value = dataUrl;
        print(" Image converted to base64");
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
      final bytes = await file.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        return '';
      }

      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageUrl.value);
      return 'data:$mimeType;base64,$base64Image';
    } catch (e) {
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

  // Clear selected image only (not all data)
  void clearSelectedImage() {
    imageUrl.value = '';
    imageNetworkUrl.value = '';
  }

  // Clear all data
  void clearAllData() {
    clearSelectedImage();
    generatedStickerUrl.value = '';
    errorMessage.value = '';
    promptText.value = '';
    selectedStyle.value = 0;
  }

  // Generate Sticker API Call - MODIFIED to keep image for regenerate
  Future<bool> generateSticker() async {
    if (imageUrl.isEmpty) {
      errorMessage.value = 'Please select an image first'.tr;
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';
    generatedStickerUrl.value = '';

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

      print(" Sending request to API...");

      var request = http.MultipartRequest('POST', Uri.parse(stickerApiUrl));
      request.headers['X-Api-Key'] = apiKey;
      request.fields['image_url'] = imageUrlForApi;
      request.fields['prompt'] = promptText.value;
      request.fields['style'] = styleNames[selectedStyle.value];
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
        print("Response data: $data");

        if (data is Map) {
          String? newImageUrl;

          if (data.containsKey('image_url')) {
            newImageUrl = data['image_url'];
          } else if (data.containsKey('sticker_url')) {
            newImageUrl = data['sticker_url'];
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
            generatedStickerUrl.value = newImageUrl;
            print(" Sticker Generated URL: $newImageUrl");

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
        errorMessage.value = "Please Choose Actual Image".tr;
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
  Future<bool> regenerateSticker() async {
    // Check if we still have the original image
    if (imageUrl.isEmpty && imageNetworkUrl.isEmpty) {
      errorMessage.value = 'Original image not available for regeneration'.tr;
      return false;
    }

    return await generateSticker();
  }
}
