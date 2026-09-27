import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ai_image_makerr/utils/reesposive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../controller/discover_controller.dart';
import '../../controller/emoji_controller.dart';
import '../../controller/premium_controller.dart';
import '../../models/emoji_category.dart';
import '../../utils/app_color.dart';
import '../premiumScree/Premium.dart';
import '../result/final_result.dart';
import '../widgets/background_theme.dart';

class AiPromptEmojiScreen extends StatefulWidget {
  const AiPromptEmojiScreen({super.key});

  @override
  State<AiPromptEmojiScreen> createState() => _AiPromptEmojiScreenState();
}

class _AiPromptEmojiScreenState extends State<AiPromptEmojiScreen> {
  final EmojiController emojiController = Get.put(EmojiController());
  final DiscoverController discoverController = Get.put(DiscoverController());
  final ImagePicker picker = ImagePicker();

  // SPEECH TO TEXT
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  final TextEditingController promptController = TextEditingController();
  Timer? _listeningTimer;
  bool _hasSpeechStarted = false;

  // Word limit variables (CHANGED FROM CHARACTER TO WORD LIMIT)
  final int _maxWordLimit = 100;
  int _currentWordCount = 0;
  bool _wordLimitReached = false; // New flag to track limit reached

  // Variable to track selected category index
  int _selectedCategoryIndex = 0;

  // Image cache to avoid multiple downloads
  final Map<String, Uint8List> _imageCache = {};

  // Focus node for keyboard dismissal
  final FocusNode _focusNode = FocusNode();

  // Overlay entry for toast
  OverlayEntry? _toastOverlayEntry;
  Timer? _toastTimer;

  // Download tracking
  static const String _downloadCountKey = 'discover_emoji_download_count';
  // Add share tracking key
  static const String _shareCountKey = 'discover_emoji_share_count';

  // FIXED: Add trial tracking for text-to-emoji generation
  bool _hasUsedTrial = false;

  @override
  void initState() {
    super.initState();

    // Load trial status
    _loadTrialStatus();

    // Sync text field with controller
    promptController.addListener(() {
      emojiController.setPromptText(promptController.text);
      setState(() {
        _currentWordCount = _countWords(promptController.text);
        // Check if word limit reached
        if (_currentWordCount >= _maxWordLimit && !_wordLimitReached) {
          _wordLimitReached = true;
          // Show toast when limit is reached
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showToast('wordLimitReached'.tr);
          });
        } else if (_currentWordCount < _maxWordLimit && _wordLimitReached) {
          _wordLimitReached = false;
        }
      });
    });

    // Load discover data if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (discoverController.categories.isEmpty) {
        discoverController.loadCategories();
      }
    });
  }

  // Load trial status from SharedPreferences
  Future<void> _loadTrialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasUsedTrial = prefs.getBool('textToEmojiTrialUsed') ?? false;
      if (mounted) setState(() {});
    } catch (e) {
      print("Error loading trial status: $e");
    }
  }

  // Save trial status to SharedPreferences
  Future<void> _saveTrialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('textToEmojiTrialUsed', true);
    } catch (e) {
      print("Error saving trial status: $e");
    }
  }

  @override
  void dispose() {
    promptController.removeListener(() {});
    promptController.dispose();
    _listeningTimer?.cancel();
    _toastTimer?.cancel();
    _hideToast();
    speech.stop();
    _focusNode.dispose();
    super.dispose();
  }

  // Method to get current download count
  Future<int> _getDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_downloadCountKey) ?? 0;
  }

  // Method to increment download count
  Future<void> _incrementDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_downloadCountKey) ?? 0;
    await prefs.setInt(_downloadCountKey, currentCount + 1);
  }

  // Method to check if user can download (less than 3 downloads)
  Future<bool> _canDownload() async {
    final downloadCount = await _getDownloadCount();
    return downloadCount < 3;
  }

  // Method to get current share count
  Future<int> _getShareCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_shareCountKey) ?? 0;
  }

  // Method to increment share count
  Future<void> _incrementShareCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_shareCountKey) ?? 0;
    await prefs.setInt(_shareCountKey, currentCount + 1);
  }

  // Method to check if user can share (less than 3 shares)
  Future<bool> _canShare() async {
    final shareCount = await _getShareCount();
    return shareCount < 3;
  }

  // Function to count words in text
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;

    // Split by whitespace and filter out empty strings
    List<String> words = text.trim().split(RegExp(r'\s+'));

    // Filter out any empty strings that might occur
    words = words.where((word) => word.isNotEmpty).toList();

    return words.length;
  }

  // Function to get words from text
  List<String> _getWords(String text) {
    if (text.trim().isEmpty) return [];

    List<String> words = text.trim().split(RegExp(r'\s+'));
    words = words.where((word) => word.isNotEmpty).toList();

    return words;
  }

  // Keyboard dismissal function
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // INTERNET CHECK - FIXED (NO TOAST HERE)
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection =
          connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;

      return hasConnection;
    } catch (e) {
      print('Connectivity error: $e');
      return false;
    }
  }

  // PASTE FROM CLIPBOARD - UPDATED WITH WORD LIMIT
  Future<void> pasteFromClipboard() async {
    // Dismiss keyboard first
    _dismissKeyboard();

    await Future.delayed(const Duration(milliseconds: 100));

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

    if (clipboardData != null && clipboardData.text!.isNotEmpty) {
      String textToPaste = clipboardData.text!.trim();

      // Check if pasting will exceed word limit
      int currentWords = _countWords(promptController.text);
      int availableWords = _maxWordLimit - currentWords;

      if (availableWords <= 0) {
        _showToast('wordLimitReached'.tr);
        return;
      }

      // Split text to paste into words
      List<String> wordsToPaste = _getWords(textToPaste);

      // If number of words exceeds available words, trim
      if (wordsToPaste.length > availableWords) {
        wordsToPaste = wordsToPaste.sublist(0, availableWords);
        textToPaste = wordsToPaste.join(' ');
        _showToast('pastedTextTrimmed'.tr);
      }

      final currentText = promptController.text;
      final cursorPosition = promptController.selection.baseOffset;

      if (cursorPosition < 0) {
        promptController.text =
            currentText +
            (currentText.isNotEmpty && !currentText.endsWith(' ') ? ' ' : '') +
            textToPaste;
        promptController.selection = TextSelection.fromPosition(
          TextPosition(offset: promptController.text.length),
        );
      } else {
        // Check if we need to add space before pasted text
        String spaceBefore = '';
        if (cursorPosition > 0 &&
            !currentText.substring(0, cursorPosition).endsWith(' ') &&
            !textToPaste.startsWith(' ')) {
          spaceBefore = ' ';
        }

        final newText =
            currentText.substring(0, cursorPosition) +
            spaceBefore +
            textToPaste +
            currentText.substring(cursorPosition);

        promptController.text = newText;
        promptController.selection = TextSelection.fromPosition(
          TextPosition(
            offset: cursorPosition + spaceBefore.length + textToPaste.length,
          ),
        );
      }

      // Update controller and word count
      emojiController.setPromptText(promptController.text);
      _currentWordCount = _countWords(promptController.text);
      _showToast('textPasted'.tr);
    } else {
      _showToast('noTextInClipboard'.tr);
    }
  }

  // SPEECH TO TEXT - UPDATED WITH NEW LOGIC
  Future<void> startListening() async {
    // Dismiss keyboard before starting speech
    _dismissKeyboard();

    if (!isListening) {
      // Check if text field is already at max word limit
      if (_currentWordCount >= _maxWordLimit) {
        _showToast('wordLimitReached'.tr);
        return;
      }

      bool available = false;

      try {
        available = await speech.initialize(
          onStatus: (status) {
            // Remove auto-stop on 'done' status
            // if (status == 'done') stopListening();
          },
          onError: (error) {
            stopListening();
          },
        );
      } catch (e) {
        _showToast('speechPermission'.tr);
        return;
      }

      if (available) {
        setState(() {
          isListening = true;
          _hasSpeechStarted = false;
        });

        // Timer for 10 seconds of no speech
        _listeningTimer = Timer(const Duration(seconds: 15), () {
          if (isListening && !_hasSpeechStarted) {
            // User didn't speak for 10 seconds
            _showToast('noSpeechDetected'.tr);
            stopListening();
          }
        });

        int cursorPosition = promptController.text.length;

        speech.listen(
          onResult: (result) {
            // Cancel the 10-second timer when user starts speaking
            if (!_hasSpeechStarted &&
                result.recognizedWords.trim().isNotEmpty) {
              _listeningTimer?.cancel();
              _hasSpeechStarted = true;
            }

            if (result.finalResult) {
              setState(() {
                String existingText = promptController.text;
                String recognizedText = result.recognizedWords.trim();

                // Calculate available words
                int currentWords = _countWords(existingText);
                int availableWords = _maxWordLimit - currentWords;

                // If no words available, show toast and stop
                if (availableWords <= 0) {
                  _showToast('wordLimitReached'.tr);
                  stopListening();
                  return;
                }

                // Split recognized text into words
                List<String> recognizedWordsList = _getWords(recognizedText);

                // Trim if exceeds available words
                if (recognizedWordsList.length > availableWords) {
                  recognizedWordsList = recognizedWordsList.sublist(
                    0,
                    availableWords,
                  );
                  recognizedText = recognizedWordsList.join(' ');
                }

                // Check if we need to add space before recognized text
                String spaceBefore = '';
                if (existingText.isNotEmpty &&
                    cursorPosition > 0 &&
                    !existingText.substring(0, cursorPosition).endsWith(' ') &&
                    !recognizedText.startsWith(' ')) {
                  spaceBefore = ' ';
                }

                String newText =
                    existingText.substring(0, cursorPosition) +
                    spaceBefore +
                    recognizedText +
                    existingText.substring(cursorPosition);

                promptController.text = newText;
                emojiController.setPromptText(promptController.text);
                _currentWordCount = _countWords(promptController.text);
                promptController.selection = TextSelection.fromPosition(
                  TextPosition(
                    offset:
                        cursorPosition +
                        spaceBefore.length +
                        recognizedText.length,
                  ),
                );
              });
            }
          },
          listenFor: const Duration(minutes: 3), // User can speak for 2 minutes
          pauseFor: const Duration(seconds: 10), // 5 seconds pause allowed
          partialResults: true,
          localeId: "en_US",
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
          onSoundLevelChange: (level) {},
        );
      } else {
        _showToast('speechNotAvailable'.tr);
      }
    }
  }

  void stopListening() {
    _listeningTimer?.cancel();
    if (isListening) speech.stop();
    setState(() {
      isListening = false;
      _hasSpeechStarted = false;
    });
  }

  void handleMicTap() {
    // Dismiss keyboard before mic tap
    _dismissKeyboard();

    if (isListening) {
      stopListening();
    } else {
      startListening();
      Future.delayed(Duration.zero, () {
        if (promptController.text.isNotEmpty) {
          promptController.selection = TextSelection.fromPosition(
            TextPosition(offset: promptController.text.length),
          );
        }
      });
    }
  }

  // UNIFIED TOAST FUNCTION WITH CONSISTENT STYLING
  void _showToast(String message) {
    // Hide any existing toast
    _hideToast();

    // Create overlay entry
    _toastOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100.h,
        left: 20.w,
        right: 20.w,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(_toastOverlayEntry!);

    // Remove toast after 2 seconds
    _toastTimer = Timer(const Duration(seconds: 2), () {
      _hideToast();
    });
  }

  void _hideToast() {
    _toastTimer?.cancel();
    _toastTimer = null;

    if (_toastOverlayEntry != null) {
      _toastOverlayEntry!.remove();
      _toastOverlayEntry = null;
    }
  }

  // GENERATE BUTTON ACTION - UPDATED WITH TRIAL LOGIC
  Future<void> handleGenerate() async {
    _dismissKeyboard();
    if (isListening) stopListening();

    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      _showToast('enter_prompt'.tr);
      return;
    }

    int wordCount = _countWords(prompt);
    if (wordCount > _maxWordLimit) {
      _showToast('wordLimitExceeded'.tr);
      return;
    }

    // Check premium status
    final premiumController = Get.find<PremiumController>();
    bool isPremium = premiumController.isPaidVersion.value;

    // Check if user is not premium and has already used trial
    if (!isPremium && _hasUsedTrial) {
      _showPremiumScreen();
      return;
    }

    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      bool success = await emojiController.generateEmoji();

      if (Get.isDialogOpen!) Get.back();

      if (success) {
        // Mark trial as used if not premium
        if (!isPremium && !_hasUsedTrial) {
          _hasUsedTrial = true;
          await _saveTrialStatus();
        }

        Get.to(
          () => const UnifiedResultScreen(resultType: ResultType.textToEmoji),
        );
      } else {
        String errorMsg = emojiController.errorMessage.value.toLowerCase();
        if (errorMsg.contains('network') || errorMsg.contains('connection')) {
          _showToast('noInternet'.tr);
        } else {
          _showToast(emojiController.errorMessage.value);
        }
      }
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      _showToast('Error: $e');
    }
  }

  // Add this helper method
  void _showPremiumScreen() {
    // _showToast('upgradeForMoreGenerations'.tr);
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PremiumScreen()),
      );
    });
  }

  // Reset trial status (for testing purposes)
  Future<void> _resetTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('textToEmojiTrialUsed');
      _hasUsedTrial = false;
      if (mounted) setState(() {});
      _showToast('Trial reset successfully');
    } catch (e) {
      print("Error resetting trial: $e");
    }
  }

  // Function to get selected category emojis
  List<EmojiItem> _getSelectedCategoryEmojis() {
    if (discoverController.categories.isEmpty) return [];
    if (_selectedCategoryIndex >= discoverController.categories.length) {
      _selectedCategoryIndex = 0;
    }
    return discoverController.categories[_selectedCategoryIndex].emojis;
  }

  // Share and Download Functions for DISCOVER SECTION
  void _showStickerDialog(BuildContext context, EmojiItem emoji) {
    // Dismiss keyboard before showing dialog
    _dismissKeyboard();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "stickerdialog".tr,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:  AppColors.fullwhite,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Image.network(
                            emoji.emojiUrl,
                            height: 280,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.error, size: 50),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Builder(
                              builder: (context) {
                                return SizedBox(
                                  height: 48,
                                  width: 147,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:  AppColors.fullwhite,
                                      foregroundColor:  AppColors.blackFull,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async =>
                                        _shareSticker(context, emoji),
                                    icon: const Icon(
                                      Icons.share,
                                      color:AppColors.blackFull,
                                    ),
                                    label: Text(
                                      "share".tr,
                                      style: TextStyle(color: AppColors.blackFull,),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              height: 48,
                              width: 147,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:  AppColors.fullwhite,
                                  foregroundColor: AppColors.blackFull,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async =>
                                    _downloadSticker(context, emoji),
                                icon: Image.asset(
                                  "assets/icons/download.png",
                                  height: 20,
                                  width: 20,
                                  color: AppColors.blackFull,
                                ),
                                label: Text(
                                  "download".tr,
                                  style: TextStyle(color: AppColors.blackFull),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  Future<void> _shareSticker(BuildContext context, EmojiItem emoji) async {
    final premiumController = Get.find<PremiumController>();
    final isPremium = premiumController.isPaidVersion.value;

    // Non-premium users can share only once
    final prefs = await SharedPreferences.getInstance();
    final sharedOnce = prefs.getBool('shared_emoji_once') ?? false;

    if (!isPremium && sharedOnce) {
      _showPremiumScreen();
      return;
    }

    try {
      Uint8List bytes;
      if (_imageCache.containsKey(emoji.emojiUrl)) {
        bytes = _imageCache[emoji.emojiUrl]!;
      } else {
        final response = await http.get(Uri.parse(emoji.emojiUrl));
        if (response.statusCode != 200)
          throw Exception('Failed to download image');
        bytes = response.bodyBytes;
        _imageCache[emoji.emojiUrl] = bytes;
      }

      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Invalid image');
      Uint8List pngBytes = Uint8List.fromList(img.encodePng(image));

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/${emoji.name}.png');
      await file.writeAsBytes(pngBytes);

      final box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: emoji.name,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.fromLTWH(0, 0, 1, 1),
      );

      if (!isPremium) await prefs.setBool('shared_emoji_once', true);

      Get.snackbar(
        'success'.tr,
        'stickerShared'.tr,
        backgroundColor:  AppColors.fullwhite,
        colorText: Colors.black,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _showToast('failedToShare'.tr);
    }
  }

  // MODIFIED DOWNLOAD FUNCTION WITH 3 DOWNLOAD LIMIT
  Future<void> _downloadSticker(BuildContext context, EmojiItem emoji) async {
    // Check if user can download (less than 3 downloads)
    final canDownload = await _canDownload();

    if (!canDownload) {
      // Show premium screen if user tries 4th download
      _showToast('downloadLimitReached'.tr);
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PremiumScreen()),
        );
      });
      return;
    }

    try {
      Uint8List bytes;
      if (_imageCache.containsKey(emoji.emojiUrl)) {
        bytes = _imageCache[emoji.emojiUrl]!;
      } else {
        final response = await http.get(Uri.parse(emoji.emojiUrl));
        if (response.statusCode != 200)
          throw Exception('Failed to download image');
        bytes = response.bodyBytes;
        _imageCache[emoji.emojiUrl] = bytes;
      }

      // Decode and re-encode PNG to preserve transparency
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Invalid image');
      Uint8List pngBytes = Uint8List.fromList(img.encodePng(image));

      await Gal.putImageBytes(pngBytes, name: emoji.name);

      // Increment download count after successful download
      await _incrementDownloadCount();

      // Get updated count for message
      final downloadCount = await _getDownloadCount();
      final remainingDownloads = 3 - downloadCount;

      String message = 'savedToGallery'.tr;
      if (remainingDownloads > 0) {
        // message += '\n${'remainingDownloads'.tr}: $remainingDownloads';
      } else {
        // message += '\n${'noDownloadsLeft'.tr}';
      }

      _showToast(message);
    } catch (e) {
      print("Download failed: $e");
      _showToast('failedToSave'.tr);
    }
  }

  // Custom Input Formatter to limit words and show toast
  TextInputFormatter _getWordLimitingFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      // Count words in new text
      int newWordCount = _countWords(newValue.text);

      // If within word limit, allow it
      if (newWordCount <= _maxWordLimit) {
        return newValue;
      }

      // If exceeds word limit, return old value
      // The toast will be shown by the listener
      return oldValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveConfig.init(context);

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            bottom: 20.h + MediaQuery.of(context).padding.bottom,
          ),
          child: GestureDetector(
            onTap: handleGenerate,
            child: Container(
              height: 55.h,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(40.w),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'generate'.tr,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.fullwhite,
                ),
              ),
            ),
          ),
        ),

        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: BackgroundTheme.background),
          child: SafeArea(
            child: Column(
              children: [
                // HEADER - UPDATED WITH PRO BUTTON
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 15.w,
                    vertical: 0.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () {
                          if (isListening) stopListening();
                          _dismissKeyboard();
                          Get.back();
                        },
                        child: Container(
                          width: 32.w,
                          height: 32.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 16),
                        ),
                      ),

                      // Title
                      Expanded(
                        child: Center(
                          child: Text(
                            'aiPromptEmojiTitle'.tr,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // DEBUG: Trial Status Indicator (remove in production)
                      // GestureDetector(
                      //   onTap: _resetTrial,
                      //   child: Container(
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: 10.w,
                      //       vertical: 5.h,
                      //     ),
                      //     decoration: BoxDecoration(
                      //       color: _hasUsedTrial ? Colors.red : Colors.green,
                      //       borderRadius: BorderRadius.circular(15.w),
                      //     ),
                      //     child: Text(
                      //       _hasUsedTrial ? 'Trial Used' : 'Trial Available',
                      //       style: TextStyle(
                      //         fontSize: 12.sp,
                      //         color: Colors.white,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                SizedBox(height: 5),

                // MAIN SCROLL
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 15.w,
                      right: 15.w,
                      bottom: 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PROMPT INPUT WITH WORD COUNTER
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.whiteee,
                            borderRadius: BorderRadius.circular(28.w),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  TextField(
                                    controller: promptController,
                                    focusNode: _focusNode,
                                    maxLines: 5,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      hintText: 'describeEmojiHint'.tr,
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(fontSize: 15.sp),
                                    ),
                                    style: TextStyle(fontSize: 16.sp),
                                    onSubmitted: (_) {
                                      _dismissKeyboard();
                                    },
                                    // Add word limit formatter
                                    inputFormatters: [
                                      _getWordLimitingFormatter(),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // PASTE BUTTON
                                  GestureDetector(
                                    onTap: pasteFromClipboard,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 13.w,
                                        vertical: 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(
                                          28.w,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            "assets/icons/paste_icon.png",
                                            width: 16.w,
                                            height: 16.w,
                                            color: AppColors.fullwhite,
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            'paste'.tr,
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              color: AppColors.fullwhite,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: handleMicTap,
                                    child: Container(
                                      width: 38.w,
                                      height: 38.h,
                                      decoration: BoxDecoration(
                                        color: isListening
                                            ? AppColors.red
                                            : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isListening ? Icons.mic_off : Icons.mic,
                                        color: AppColors.fullwhite,
                                        size: 20.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15.h),

                        // STYLE EMOJIS
                        Text(
                          'selectStyleTitle'.tr,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 7.h),
                        SizedBox(
                          height: 90.h,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              styleEmojiItem(
                                1,
                                'styleClassic'.tr,
                                'assets/emojis/classic.png',
                              ),
                              styleEmojiItem(
                                2,
                                'styleCartoon'.tr,
                                'assets/emojis/cartoon.png',
                              ),
                              styleEmojiItem(
                                3,
                                'stylePixel'.tr,
                                'assets/emojis/pixel.png',
                              ),
                              styleEmojiItem(
                                4,
                                'styleLineArt'.tr,
                                'assets/emojis/line_art.png',
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // DISCOVER EMOJIS SECTION WITH CATEGORIES
                        Obx(() {
                          final isLoading =
                              discoverController.categories.isEmpty;
                          final categories = discoverController.categories;
                          final emojis = _getSelectedCategoryEmojis();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'discoverTitle'.tr,
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 10.h),

                              // CATEGORY SELECTION (HORIZONTAL LIST)
                              if (!isLoading && categories.isNotEmpty)
                                SizedBox(
                                  height: 40.h,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      bool isSelected =
                                          index == _selectedCategoryIndex;

                                      return GestureDetector(
                                        onTap: () {
                                          _dismissKeyboard();
                                          setState(() {
                                            _selectedCategoryIndex = index;
                                          });
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(right: 10.w),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              20.w,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.grey.shade400,
                                              width: 1.w,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              category.name,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.fullwhite
                                                    : AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              SizedBox(height: 15.h),

                              if (isLoading)
                                Center(
                                  child: SizedBox(
                                    height: 200.h,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          color: AppColors.primary,
                                          strokeWidth: 2,
                                        ),
                                        SizedBox(height: 10.h),
                                        Text(
                                          'loadingemojis'.tr,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (emojis.isEmpty)
                                Container(
                                  height: 100.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.white30,
                                    borderRadius: BorderRadius.circular(22.w),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'noEmojisAvailable'.tr,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: emojis.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 12.h,
                                        crossAxisSpacing: 12.w,
                                        childAspectRatio: 1.0,
                                      ),
                                  itemBuilder: (context, index) {
                                    final emoji = emojis[index];
                                    return _DiscoverEmojiCard(
                                      emoji: emoji,
                                      onTap: () {
                                        _dismissKeyboard();
                                        _showStickerDialog(context, emoji);
                                      },
                                    );
                                  },
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget styleEmojiItem(int index, String title, String assetPath) {
    return Obx(() {
      bool selected = index == emojiController.selectedStyleIndex.value;

      return GestureDetector(
        onTap: () {
          _dismissKeyboard();
          emojiController.setSelectedStyle(index);
        },
        child: Container(
          width: 90.w,
          margin: EdgeInsets.only(right: 12.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.whiteee : AppColors.white30,
            borderRadius: BorderRadius.circular(22.w),
            border: selected
                ? Border.all(color: AppColors.primary, width: 2.w)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji from assets
              Image.asset(
                assetPath,
                width: 40.w,
                height: 40.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 5.h),
              Text(
                title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _DiscoverEmojiCard extends StatelessWidget {
  final EmojiItem emoji;
  final VoidCallback onTap;

  const _DiscoverEmojiCard({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white30,
          borderRadius: BorderRadius.circular(22.w),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.w),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Image.network(
              emoji.emojiUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.emoji_emotions_outlined,
                  size: 40.w,
                  color: AppColors.primary,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
