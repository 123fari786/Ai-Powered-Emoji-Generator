// lib/services/rating_service.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RatingService {
  static final InAppReview _inAppReview = InAppReview.instance;

  // Track rating prompt attempts per user
  static const String _ratingPromptCountKey = 'rating_prompt_count';
  static const String _lastPromptDateKey = 'last_prompt_date';
  static const String _neverShowAgainKey = 'never_show_rating';

  // Add your actual app store IDs here
  static const String _iosAppStoreId =
      'YOUR_IOS_APP_ID'; // Replace with your iOS App ID
  static const String _androidPackageName =
      'com.yourcompany.yourapp'; // Replace with your Android package

  static Future<bool?> Function(BuildContext)? _showCustomAndroidDialog;

  /// Initialize with your custom dialog
  static void initialize({
    required Future<bool?> Function(BuildContext) showCustomAndroidDialog,
  }) {
    _showCustomAndroidDialog = showCustomAndroidDialog;
  }

  /// Show rating prompt after trial usage
  static Future<void> promptAfterTrial(
    String featureName, {
    BuildContext? context,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we should show the prompt
    if (!await _shouldShowPrompt(prefs)) return;

    print('🔄 Attempting to show rating prompt for $featureName...');

    // Platform-specific logic
    if (Platform.isAndroid &&
        context != null &&
        _showCustomAndroidDialog != null) {
      // Android: Show your pre-made custom dialog
      await _showAndroidCustomDialog(context, prefs, featureName);
    } else {
      // iOS: Always use native review prompt
      await _showNativeRatingPrompt(prefs, featureName);
    }
  }

  /// Android: Show your pre-made custom rating dialog
  static Future<void> _showAndroidCustomDialog(
    BuildContext context,
    SharedPreferences prefs,
    String featureName,
  ) async {
    try {
      // Call your custom dialog function
      bool? shouldRate = await _showCustomAndroidDialog!(context);

      if (shouldRate == true) {
        // User wants to rate - open store
        await _openStoreDirectly();
        await _updatePromptTracking(prefs);
        print('✅ Android custom dialog - user chose to rate');
      } else if (shouldRate == false) {
        // User selected "Never Show Again"
        await prefs.setBool(_neverShowAgainKey, true);
        print('❌ Android custom dialog - user chose "Never Show Again"');
      } else {
        // User dismissed or cancelled
        await _updatePromptTracking(prefs);
        print('⏭️ Android custom dialog - user dismissed');
      }
    } catch (e) {
      print('❌ Error showing custom Android dialog: $e');
      // Fallback to native dialog
      await _showNativeRatingPrompt(prefs, featureName);
    }
  }

  /// iOS: Native rating prompt
  static Future<void> _showNativeRatingPrompt(
    SharedPreferences prefs,
    String featureName,
  ) async {
    try {
      if (await _inAppReview.isAvailable()) {
        // This shows the native StoreKit review dialog
        await _inAppReview.requestReview();
        await _updatePromptTracking(prefs);
        print('✅ iOS native rating shown for $featureName');
      } else {
        // Fallback: Open store listing directly
        print('⚠️ Native rating not available, opening store listing');
        await _openStoreListingFallback();
        await _updatePromptTracking(prefs);
      }
    } catch (e) {
      print('❌ Error showing native rating: $e');
      // Final fallback: Direct store link
      await _openStoreDirectly();
      await _updatePromptTracking(prefs);
    }
  }

  // Fallback: Open store listing (not review dialog)
  static Future<void> _openStoreListingFallback() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: _iosAppStoreId,
        microsoftStoreId: '',
      );
    } catch (e) {
      print('❌ Error opening store listing: $e');
      await _openStoreDirectly();
    }
  }

  // Direct store link as last resort
  static Future<void> _openStoreDirectly() async {
    try {
      if (Platform.isIOS && _iosAppStoreId.isNotEmpty) {
        // iOS App Store URL
        final url = Uri.parse('https://apps.apple.com/app/id$_iosAppStoreId');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isAndroid && _androidPackageName.isNotEmpty) {
        // Android Play Store URL
        final url = Uri.parse(
          'https://play.google.com/store/apps/details?id=$_androidPackageName',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('❌ Error opening store: $e');
    }
  }

  /// Determine if we should show the prompt
  static Future<bool> _shouldShowPrompt(SharedPreferences prefs) async {
    // Check if user selected "Never"
    final bool neverShowAgain = prefs.getBool(_neverShowAgainKey) ?? false;
    if (neverShowAgain) {
      print('⏭️ Rating prompt skipped - user selected "Never Show Again"');
      return false;
    }

    final int promptCount = prefs.getInt(_ratingPromptCountKey) ?? 0;
    final String? lastPromptDate = prefs.getString(_lastPromptDateKey);

    // Don't show more than 3 times
    if (promptCount >= 3) {
      print('⏭️ Rating prompt skipped - already shown 3 times');
      return false;
    }

    // Check last prompt date (minimum 7 days between prompts)
    if (lastPromptDate != null) {
      final lastDate = DateTime.parse(lastPromptDate);
      final daysSinceLast = DateTime.now().difference(lastDate).inDays;

      if (daysSinceLast < 7) {
        print('⏭️ Rating prompt skipped - last shown $daysSinceLast days ago');
        return false;
      }
    }

    return true;
  }

  /// Update tracking after showing prompt
  static Future<void> _updatePromptTracking(SharedPreferences prefs) async {
    final int currentCount = prefs.getInt(_ratingPromptCountKey) ?? 0;
    await prefs.setInt(_ratingPromptCountKey, currentCount + 1);
    await prefs.setString(_lastPromptDateKey, DateTime.now().toIso8601String());

    print('📊 Rating prompt count updated to: ${currentCount + 1}');
  }

  /// Reset for testing
  static Future<void> resetRatingTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ratingPromptCountKey);
    await prefs.remove(_lastPromptDateKey);
    await prefs.remove(_neverShowAgainKey);

    print('🔄 Rating tracking reset for testing');
  }

  /// Manually open store for rating
  static Future<void> openStoreForRating() async {
    await _openStoreDirectly();
  }
}
