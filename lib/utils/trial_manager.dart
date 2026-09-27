// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // class TrialManager {
// //   // Keys for each feature
// //   static const String _textToEmojiTrialKey = 'text_to_emoji_trial_used';
// //   static const String _imageToEmojiTrialKey = 'image_to_emoji_trial_used';
// //   static const String _stickerTrialKey = 'sticker_trial_used';
// //
// //   // Key for tracking successful generations (for rating dialog)
// //   static const String _successfulGenerationsKey = 'successful_generations';
// //
// //   /// Check if trial is available for a specific feature
// //   static Future<bool> isTrialAvailable(String feature) async {
// //     final prefs = await SharedPreferences.getInstance();
// //
// //     switch (feature) {
// //       case 'text_to_emoji':
// //         return !(prefs.getBool(_textToEmojiTrialKey) ?? false);
// //       case 'image_to_emoji':
// //         return !(prefs.getBool(_imageToEmojiTrialKey) ?? false);
// //       case 'sticker':
// //         return !(prefs.getBool(_stickerTrialKey) ?? false);
// //       default:
// //         return true;
// //     }
// //   }
// //
// //   /// Mark trial as used for a specific feature
// //   static Future<void> markTrialUsed(String feature) async {
// //     final prefs = await SharedPreferences.getInstance();
// //
// //     switch (feature) {
// //       case 'text_to_emoji':
// //         await prefs.setBool(_textToEmojiTrialKey, true);
// //         break;
// //       case 'image_to_emoji':
// //         await prefs.setBool(_imageToEmojiTrialKey, true);
// //         break;
// //       case 'sticker':
// //         await prefs.setBool(_stickerTrialKey, true);
// //         break;
// //     }
// //   }
// //
// //   /// Track a successful generation (increment counter)
// //   static Future<void> trackSuccessfulGeneration() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final int currentCount = prefs.getInt(_successfulGenerationsKey) ?? 0;
// //     await prefs.setInt(_successfulGenerationsKey, currentCount + 1);
// //   }
// //
// //   /// Check if we should show rating (after 3 successful generations)
// //   static Future<bool> shouldShowRating() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final int generations = prefs.getInt(_successfulGenerationsKey) ?? 0;
// //     return generations >= 3;
// //   }
// //
// //   /// Check if user has Premium
// //   static Future<bool> hasPremium() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     return prefs.getBool('user_has_premium') ?? false;
// //   }
// //
// //   /// Set Premium status (call this when user purchases)
// //   static Future<void> setPremium(bool status) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.setBool('user_has_premium', status);
// //   }
// //
// //   /// Reset all trials (for testing)
// //   static Future<void> resetAllTrials() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.remove(_textToEmojiTrialKey);
// //     await prefs.remove(_imageToEmojiTrialKey);
// //     await prefs.remove(_stickerTrialKey);
// //     await prefs.remove(_successfulGenerationsKey);
// //   }
// // }
// //
// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // class TrialManager {
// //   // Keys for each feature
// //   static const String _textToEmojiTrialKey = 'text_to_emoji_trial_used';
// //   static const String _imageToEmojiTrialKey = 'image_to_emoji_trial_used';
// //   static const String _stickerTrialKey = 'sticker_trial_used';
// //
// //   // New key for sticker share count
// //   static const String _stickerShareCountKey = 'sticker_share_count';
// //   static const String _stickerDownloadCountKey = 'sticker_download_count';
// //
// //   // Key for tracking successful generations (for rating dialog)
// //   static const String _successfulGenerationsKey = 'successful_generations';
// //
// //   // Maximum free attempts
// //   static const int _maxFreeAttempts = 3;
// //
// //   // Check if trial is available for a specific feature
// //   static Future<bool> isTrialAvailable(String feature) async {
// //     final prefs = await SharedPreferences.getInstance();
// //
// //     switch (feature) {
// //       case 'text_to_emoji':
// //         return !(prefs.getBool(_textToEmojiTrialKey) ?? false);
// //       case 'image_to_emoji':
// //         return !(prefs.getBool(_imageToEmojiTrialKey) ?? false);
// //       case 'sticker':
// //         // For sticker, check both download and share counts
// //         final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
// //         final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
// //         // User can perform total 3 free actions (download + share combined)
// //         return (downloadCount + shareCount) < _maxFreeAttempts;
// //       default:
// //         return true;
// //     }
// //   }
// //
// //   // Mark trial as used for a specific feature
// //   static Future<void> markTrialUsed(String feature) async {
// //     final prefs = await SharedPreferences.getInstance();
// //
// //     switch (feature) {
// //       case 'text_to_emoji':
// //         await prefs.setBool(_textToEmojiTrialKey, true);
// //         break;
// //       case 'image_to_emoji':
// //         await prefs.setBool(_imageToEmojiTrialKey, true);
// //         break;
// //       case 'sticker':
// //         // Sticker is handled differently with counters
// //         break;
// //     }
// //   }
// //
// //   // Track sticker download
// //   static Future<bool> trackStickerDownload() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
// //     final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
// //
// //     if ((downloadCount + shareCount) >= _maxFreeAttempts) {
// //       return false; // No more free attempts
// //     }
// //
// //     await prefs.setInt(_stickerDownloadCountKey, downloadCount + 1);
// //     return true;
// //   }
// //
// //   // Track sticker share
// //   static Future<bool> trackStickerShare() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
// //     final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
// //
// //     if ((downloadCount + shareCount) >= _maxFreeAttempts) {
// //       return false; // No more free attempts
// //     }
// //
// //     await prefs.setInt(_stickerShareCountKey, shareCount + 1);
// //     return true;
// //   }
// //
// //   // Get remaining free attempts for stickers
// //   static Future<int> getRemainingStickerAttempts() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
// //     final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
// //     final usedAttempts = downloadCount + shareCount;
// //     return _maxFreeAttempts - usedAttempts;
// //   }
// //
// //   // Get total used attempts for stickers
// //   static Future<int> getUsedStickerAttempts() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
// //     final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
// //     return downloadCount + shareCount;
// //   }
// //
// //   // Track a successful generation (increment counter)
// //   static Future<void> trackSuccessfulGeneration() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final int currentCount = prefs.getInt(_successfulGenerationsKey) ?? 0;
// //     await prefs.setInt(_successfulGenerationsKey, currentCount + 1);
// //   }
// //
// //   //Check if we should show rating (after 3 successful generations)
// //   static Future<bool> shouldShowRating() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final int generations = prefs.getInt(_successfulGenerationsKey) ?? 0;
// //     return generations >= 3;
// //   }
// //
// //   //Check if user has Premium
// //   static Future<bool> hasPremium() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     return prefs.getBool('user_has_premium') ?? false;
// //   }
// //
// //   //Set Premium status (call this when user purchases)
// //   static Future<void> setPremium(bool status) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.setBool('user_has_premium', status);
// //   }
// //
// //   // Reset all trials (for testing)
// //   static Future<void> resetAllTrials() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.remove(_textToEmojiTrialKey);
// //     await prefs.remove(_imageToEmojiTrialKey);
// //     await prefs.remove(_stickerTrialKey);
// //     await prefs.remove(_stickerShareCountKey);
// //     await prefs.remove(_stickerDownloadCountKey);
// //     await prefs.remove(_successfulGenerationsKey);
// //   }
// // }
//
// // lib/utils/trial_manager.dart
// import 'package:shared_preferences/shared_preferences.dart';
//
// class TrialManager {
//   // Keys for each feature
//   static const String _textToEmojiTrialKey = 'text_to_emoji_trial_used';
//   static const String _imageToEmojiTrialKey = 'image_to_emoji_trial_used';
//   static const String _stickerTrialKey = 'sticker_trial_used';
//
//   // New key for sticker share count
//   static const String _stickerShareCountKey = 'sticker_share_count';
//   static const String _stickerDownloadCountKey = 'sticker_download_count';
//
//   // Key for tracking successful generations (for rating dialog)
//   static const String _successfulGenerationsKey = 'successful_generations';
//
//   // Premium status key
//   static const String _premiumStatusKey = 'user_has_premium';
//
//   // Maximum free attempts
//   static const int _maxFreeAttempts = 3;
//
//   /// Check if user can access a feature
//   /// Returns true if user is premium OR trial is available
//   static Future<bool> canAccessFeature(String feature) async {
//     final isPremium = await hasPremium();
//
//     // Premium用户可以无限使用
//     if (isPremium) {
//       return true;
//     }
//
//     // 非Premium用户检查试用
//     return await isTrialAvailable(feature);
//   }
//
//   /// Check if trial is available for a specific feature
//   static Future<bool> isTrialAvailable(String feature) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     switch (feature) {
//       case 'text_to_emoji':
//         return !(prefs.getBool(_textToEmojiTrialKey) ?? false);
//       case 'image_to_emoji':
//         return !(prefs.getBool(_imageToEmojiTrialKey) ?? false);
//       case 'sticker':
//         // For sticker, check both download and share counts
//         final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
//         final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
//         // User can perform total 3 free actions (download + share combined)
//         return (downloadCount + shareCount) < _maxFreeAttempts;
//       default:
//         return true;
//     }
//   }
//
//   /// Mark trial as used for a specific feature
//   /// Only for non-premium users
//   static Future<void> markTrialUsed(String feature) async {
//     final isPremium = await hasPremium();
//
//     // Premium用户不需要标记试用
//     if (isPremium) {
//       return;
//     }
//
//     final prefs = await SharedPreferences.getInstance();
//
//     switch (feature) {
//       case 'text_to_emoji':
//         await prefs.setBool(_textToEmojiTrialKey, true);
//         break;
//       case 'image_to_emoji':
//         await prefs.setBool(_imageToEmojiTrialKey, true);
//         break;
//       case 'sticker':
//         // Sticker is handled differently with counters
//         break;
//     }
//   }
//
//   /// Track sticker download
//   /// Returns true if operation was successful
//   static Future<bool> trackStickerDownload() async {
//     final isPremium = await hasPremium();
//
//     // Premium用户可以无限下载
//     if (isPremium) {
//       return true;
//     }
//
//     final prefs = await SharedPreferences.getInstance();
//     final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
//     final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
//
//     if ((downloadCount + shareCount) >= _maxFreeAttempts) {
//       return false; // No more free attempts
//     }
//
//     await prefs.setInt(_stickerDownloadCountKey, downloadCount + 1);
//     return true;
//   }
//
//   /// Track sticker share
//   /// Returns true if operation was successful
//   static Future<bool> trackStickerShare() async {
//     final isPremium = await hasPremium();
//
//     // Premium用户可以无限分享
//     if (isPremium) {
//       return true;
//     }
//
//     final prefs = await SharedPreferences.getInstance();
//     final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
//     final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
//
//     if ((downloadCount + shareCount) >= _maxFreeAttempts) {
//       return false; // No more free attempts
//     }
//
//     await prefs.setInt(_stickerShareCountKey, shareCount + 1);
//     return true;
//   }
//
//   /// Get remaining free attempts for stickers
//   static Future<int> getRemainingStickerAttempts() async {
//     final isPremium = await hasPremium();
//
//     // Premium用户返回一个很大的数字表示无限
//     if (isPremium) {
//       return 999;
//     }
//
//     final prefs = await SharedPreferences.getInstance();
//     final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
//     final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
//     final usedAttempts = downloadCount + shareCount;
//     return _maxFreeAttempts - usedAttempts;
//   }
//
//   /// Get total used attempts for stickers
//   static Future<int> getUsedStickerAttempts() async {
//     final prefs = await SharedPreferences.getInstance();
//     final downloadCount = prefs.getInt(_stickerDownloadCountKey) ?? 0;
//     final shareCount = prefs.getInt(_stickerShareCountKey) ?? 0;
//     return downloadCount + shareCount;
//   }
//
//   /// Track a successful generation (increment counter)
//   static Future<void> trackSuccessfulGeneration() async {
//     final prefs = await SharedPreferences.getInstance();
//     final int currentCount = prefs.getInt(_successfulGenerationsKey) ?? 0;
//     await prefs.setInt(_successfulGenerationsKey, currentCount + 1);
//   }
//
//   /// Check if we should show rating (after 3 successful generations)
//   static Future<bool> shouldShowRating() async {
//     final prefs = await SharedPreferences.getInstance();
//     final int generations = prefs.getInt(_successfulGenerationsKey) ?? 0;
//     return generations >= 3;
//   }
//
//   /// Check if user has Premium
//   static Future<bool> hasPremium() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_premiumStatusKey) ?? false;
//   }
//
//   /// Set Premium status (call this when user purchases or cancels)
//   static Future<void> setPremium(bool status) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_premiumStatusKey, status);
//
//     // 如果用户取消Premium，不需要重置试用次数
//     // 保留他们之前的试用状态
//   }
//
//   /// Reset all trials (for testing or when user purchases premium)
//   static Future<void> resetAllTrials() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_textToEmojiTrialKey);
//     await prefs.remove(_imageToEmojiTrialKey);
//     await prefs.remove(_stickerTrialKey);
//     await prefs.remove(_stickerShareCountKey);
//     await prefs.remove(_stickerDownloadCountKey);
//   }
//
//   /// Reset only successful generations counter
//   static Future<void> resetSuccessfulGenerations() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_successfulGenerationsKey);
//   }
//
//   /// Get all trial data for debugging
//   static Future<Map<String, dynamic>> getTrialData() async {
//     final prefs = await SharedPreferences.getInstance();
//     return {
//       'isPremium': prefs.getBool(_premiumStatusKey) ?? false,
//       'textToEmojiUsed': prefs.getBool(_textToEmojiTrialKey) ?? false,
//       'imageToEmojiUsed': prefs.getBool(_imageToEmojiTrialKey) ?? false,
//       'stickerDownloadCount': prefs.getInt(_stickerDownloadCountKey) ?? 0,
//       'stickerShareCount': prefs.getInt(_stickerShareCountKey) ?? 0,
//       'successfulGenerations': prefs.getInt(_successfulGenerationsKey) ?? 0,
//     };
//   }
// }
