import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

class EmojiModel {
  final String name;
  final String emojiUrl;

  EmojiModel({required this.name, required this.emojiUrl});
}

class EmojiCategory {
  final String name;
  final List<EmojiModel> emojis;

  EmojiCategory({required this.name, required this.emojis});

  int get counts => emojis.length;
}

class DiscoverController extends GetxController {
  var categories = <EmojiCategory>[].obs;
  var selectedCategory = ''.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void onInit() {
    super.onInit();
    fetchCategoriesFromFirebase();
  }

  Future<void> fetchCategoriesFromFirebase() async {
    try {
      final snapshot = await _firestore.collection('emoji_categories').get();

      List<EmojiCategory> tempCategories = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String name = data['name'] ?? 'Unknown';
        final List emojisData = data['emojis'] ?? [];

        List<EmojiModel> emojiList = [];

        for (var e in emojisData) {
          final String path = e['path'] ?? '';
          final String emojiName = e['name'] ?? 'Emoji';

          // Get download URL from Firebase Storage
          String url = '';
          if (path.isNotEmpty) {
            try {
              url = await _storage.ref(path).getDownloadURL();
            } catch (e) {
              print(' Error getting download URL for $path: $e');
            }
          }

          emojiList.add(EmojiModel(name: emojiName, emojiUrl: url));
        }

        tempCategories.add(EmojiCategory(name: name, emojis: emojiList));
      }

      categories.assignAll(tempCategories);

      if (categories.isNotEmpty) {
        selectedCategory.value = categories.first.name;
      }
    } catch (e) {
      print(' Error fetching categories from Firebase: $e');
    }
  }
}
