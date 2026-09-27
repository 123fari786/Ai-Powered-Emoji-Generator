import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'controller/premium_controller.dart';
import 'controller/emoji_controller.dart';
import 'controller/image_to_emoji.dart';
import 'controller/sticker.dart';
import 'models/generated_items_controller.dart';
import 'utils/app_color.dart';
import 'utils/app_texts.dart';
import 'view/splash/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Controllers
  Get.put(PremiumController(), permanent: true);
  Get.put(GeneratedItemsController(), permanent: true);
  Get.put(EmojiController(), permanent: true);
  Get.put(ImageToEmojiController(), permanent: true);
  Get.put(StickerController(), permanent: true);

  final box = GetStorage();
  User? user;

  // Anonymous Firebase login
  try {
    String? storedUserId = box.read('user_id');
    String? storedBucketId = box.read('bucket_id');

    if (storedUserId != null && storedBucketId != null) {
      if (kDebugMode) {
        print('User already exists in storage: $storedUserId');
      }
    } else {
      UserCredential userCredential =
      await FirebaseAuth.instance.signInAnonymously();
      user = userCredential.user;

      if (user != null) {
        String bucketId = "bucket_${user.uid.substring(0, 8)}";

        await box.write('user_id', user.uid);
        await box.write('bucket_id', bucketId);

        if (kDebugMode) {
          print('✅ Anonymous login successful!');
          print('User ID: ${user.uid}');
          print('Bucket ID: $bucketId');
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error signing in anonymously: $e');
    }
  }

  // Orientation & System UI
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  //  Status bar fully white + icons black
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Status bar background
    statusBarIconBrightness: Brightness.dark, // Android: black icons
    statusBarBrightness: Brightness.dark, // iOS: black icons
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    // Language handling
    String savedLangCode = box.read('langCode') ?? 'en_US';
    List<String> parts = savedLangCode.split('_');
    final locale = Locale(
      parts[0],
      parts.length > 1 ? parts[1] : 'US',
    );

    return GetMaterialApp(
      title: 'AI Emoji Maker',
      debugShowCheckedModeBanner: false,
      translations: AppTranslation(),
      locale: locale,
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        fontFamily: 'Fredoka',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
