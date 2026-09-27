import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/emoji_category.dart';

class DiscoverController extends GetxController {
  var categories = <EmojiCategory>[].obs;
  var selectedCategory = ''.obs;
  var categoryCount = 0;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<String> getImageURL({
    required String baseURL,
    required String title,
    required int index,
    required String? uid,
    required String? bucket,
  }) async {
    if (uid == null || bucket == null) return '';

    // Path to the thumbnail
    final newIndex = index + 1;
    String formattedIndex = newIndex.toString().padLeft(2, '0');
    String thumbnailPath = 'Emoji/$title/$formattedIndex.png';

    // Encode path components safely
    String encodedPath = Uri.encodeComponent(thumbnailPath);

    // Full URL
    String url =
        'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media&token=$uid';

    return url;
  }

  Future<void> loadCategories() async {
    final box = GetStorage();
    final storage = FirebaseStorage.instance;
    final rootRef = storage
        .refFromURL("gs://aiemojie.firebasestorage.app")
        .child("Emoji");

    final listResult = await rootRef.listAll();
    List<EmojiCategory> loadedCategories = [];

    for (var folder in listResult.prefixes) {
      List<EmojiItem> emojis = [];
      final files = await folder.listAll();
      for (var i = 0; i < files.items.length; i++) {
        final file = files.items[i];

        // Get Firebase download URL using our Dart function
        final url = await getImageURL(
          baseURL: 'Emoji', // root folder
          title: folder.name,
          index: i,
          uid: box.read('user_id'), // get from your user manager
          bucket: 'aiemojie.firebasestorage.app', // get from your config
        );
        emojis.add(EmojiItem(name: file.name.split(".").first, emojiUrl: url));
      }

      if (emojis.isNotEmpty) {
        loadedCategories.add(
          EmojiCategory(
            name: folder.name,
            emojis: emojis,
            counts: emojis.length,
          ),
        );
      }
    }

    categories.value = loadedCategories;
    if (categories.isNotEmpty) {
      selectedCategory.value = categories.first.name;
    }
  }
}
