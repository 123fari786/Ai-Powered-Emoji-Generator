import 'dart:async';
import 'dart:io';

import 'package:ai_image_makerr/utils/reesposive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ADD THIS
import 'package:speech_to_text/speech_to_text.dart';

import '../../controller/premium_controller.dart';
import '../../controller/sticker.dart';
import '../../utils/app_color.dart';
import '../premiumScree/Premium.dart';
import '../result/final_result.dart';
import '../widgets/background_theme.dart';

class Sticker extends StatefulWidget {
  const Sticker({super.key});

  @override
  State<Sticker> createState() => _StickerScreenState();
}

class _StickerScreenState extends State<Sticker> {
  int selectedStyle = 0;
  final ImagePicker picker = ImagePicker();

  // Get the controller instance
  final StickerController controller = Get.find<StickerController>();
  final PremiumController premiumController = Get.find<PremiumController>();

  // SPEECH TO TEXT - UPDATED WITH NEW LOGIC
  SpeechToText speech = SpeechToText();
  bool isListening = false;

  // FIXED: Change from Obx to regular bool and load from SharedPreferences
  bool _hasUsedTrial = false; // Track if user has used their free trial

  bool _hasSpeechStarted = false; // Track if user has started speaking
  late TextEditingController promptController;
  late FocusNode _focusNode;
  Timer? _listeningTimer;

  // Word limit variables
  final int _maxWordLimit = 100;
  int _currentWordCount = 0;

  // Scroll controller for prompt text
  late ScrollController _promptScrollController;

  @override
  void initState() {
    super.initState();
    promptController = TextEditingController();
    _focusNode = FocusNode();
    _promptScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.clearSelectedImage();
    });

    // Listen for prompt text changes from controller
    controller.promptText.listen((value) {
      if (promptController.text != value) {
        promptController.text = value;
        _currentWordCount = _countWords(promptController.text);
        promptController.selection = TextSelection.fromPosition(
          TextPosition(offset: promptController.text.length),
        );
      }
    });

    // Listen to text changes for word count
    promptController.addListener(() {
      _currentWordCount = _countWords(promptController.text);
    });

    // Load trial status from SharedPreferences
    _loadTrialStatus();
  }

  // Load trial status from SharedPreferences
  Future<void> _loadTrialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasUsedTrial = prefs.getBool('stickerTrialUsed') ?? false;
      if (mounted) setState(() {});
    } catch (e) {
      print("Error loading trial status: $e");
    }
  }

  // Save trial status to SharedPreferences
  Future<void> _saveTrialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stickerTrialUsed', true);
    } catch (e) {
      print("Error saving trial status: $e");
    }
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

  @override
  void dispose() {
    promptController.dispose();
    _focusNode.dispose();
    _promptScrollController.dispose();
    _listeningTimer?.cancel();
    speech.stop();

    // Screen dispose
    controller.clearSelectedImage();

    super.dispose();
  }

  // Keyboard dismiss function
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // PICK IMAGE FROM GALLERY
  Future pickImageFromGallery() async {
    _dismissKeyboard();
    await controller.pickImageFromGallery();
    if (controller.imageUrl.isNotEmpty) {
      setState(() {}); // Update UI
    }
  }

  // Internet connection check
  Future<bool> isConnected() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      // Check if device shows connectivity
      if (connectivityResult == ConnectivityResult.none) {
        showToast('noInternet'.tr);
        return false;
      }

      // Additional check to verify real internet connectivity
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 1), onTimeout: () => []);

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // Real internet connection
      } else {
        showToast('noInternet'.tr);
        return false;
      }
    } on SocketException catch (_) {
      showToast('noInternet'.tr);
      return false;
    } on TimeoutException catch (_) {
      showToast('noInternet'.tr);
      return false;
    } catch (e) {
      print("Connection check error: $e");
      showToast('noInternet'.tr);
      return false;
    }
  }

  // PASTE FROM CLIPBOARD (Updated with word limit)
  Future<void> pasteFromClipboard() async {
    _dismissKeyboard();
    await Future.delayed(const Duration(milliseconds: 100));

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

    if (clipboardData != null && clipboardData.text!.isNotEmpty) {
      String textToPaste = clipboardData.text!.trim();

      // Check if pasting will exceed word limit
      int currentWords = _countWords(promptController.text);
      int availableWords = _maxWordLimit - currentWords;

      if (availableWords <= 0) {
        showToast('wordLimitReached'.tr);
        return;
      }

      // Split text to paste into words
      List<String> wordsToPaste = _getWords(textToPaste);

      // If number of words exceeds available words, trim
      if (wordsToPaste.length > availableWords) {
        wordsToPaste = wordsToPaste.sublist(0, availableWords);
        textToPaste = wordsToPaste.join(' ');
      }

      // Get cursor position
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
      controller.setPromptText(promptController.text);
      _currentWordCount = _countWords(promptController.text);

      // Scroll to bottom after pasting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptScrollController.animateTo(
          _promptScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      // Success message
      // showToast('textPasted'.tr);
    } else {
      // showToast('noTextInClipboard'.tr);
    }
  }

  // START LISTENING - UPDATED WITH NEW LOGIC
  Future startListening() async {
    _dismissKeyboard();

    // Check if text field is already at max word limit
    if (_currentWordCount >= _maxWordLimit) {
      // showToast('wordLimitReached'.tr);
      return;
    }

    bool available = await speech.initialize();
    if (available) {
      setState(() {
        isListening = true;
        _hasSpeechStarted = false; // Reset speech started flag
      });

      // Timer for 10 seconds of no speech
      _listeningTimer = Timer(const Duration(seconds: 10), () {
        if (isListening && !_hasSpeechStarted) {
          // User didn't speak for 10 seconds
          showNoSpeechToast();
          stopListening();
        }
      });

      speech.listen(
        onResult: (val) {
          // Cancel the 10-second timer when user starts speaking
          if (!_hasSpeechStarted && val.recognizedWords.trim().isNotEmpty) {
            _listeningTimer?.cancel();
            _hasSpeechStarted = true;
          }

          if (val.finalResult) {
            setState(() {
              String recognizedText = val.recognizedWords.trim();

              // Calculate available words
              int currentWords = _countWords(promptController.text);
              int availableWords = _maxWordLimit - currentWords;

              // If no words available, show toast and stop
              if (availableWords <= 0) {
                showToast('wordLimitReached'.tr);
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

              promptController.text = recognizedText;
              promptController.selection = TextSelection.fromPosition(
                TextPosition(offset: promptController.text.length),
              );

              // Update controller and word count
              controller.setPromptText(recognizedText);
              _currentWordCount = _countWords(promptController.text);

              // Scroll to bottom after speech recognition
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _promptScrollController.animateTo(
                  _promptScrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            });
          }
        },
        listenFor: const Duration(minutes: 10), // 10 minutes - very long time
        pauseFor: const Duration(seconds: 5), // 5 seconds pause allowed
        partialResults: true,
        localeId: "en_US",
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } else {
      // Show error toast if speech recognition is not available
      showToast('speechNotAvailable'.tr);
    }
  }

  // STOP LISTENING - UPDATED
  void stopListening() {
    _listeningTimer?.cancel();
    if (isListening) speech.stop();
    setState(() {
      isListening = false;
      _hasSpeechStarted = false;
    });
  }

  // SHOW TOAST FOR NO SPEECH DETECTED
  void showNoSpeechToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('noSpeechDetected'.tr, style: TextStyle(fontSize: 14.sp)),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.w),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      ),
    );
  }

  // GENERAL TOAST METHOD
  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14.sp, color: Colors.black),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.w),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      ),
    );
  }

  // HANDLE MICROPHONE TAP - UPDATED
  void handleMicTap() {
    _dismissKeyboard();

    if (isListening) {
      stopListening();
    } else {
      // Start listening
      startListening();

      // Check if there's existing text and set cursor at end
      if (promptController.text.isNotEmpty) {
        Future.delayed(Duration.zero, () {
          promptController.selection = TextSelection.fromPosition(
            TextPosition(offset: promptController.text.length),
          );
        });
      }
    }
  }

  // Handle text field changes
  void _onPromptTextChanged(String text) {
    controller.setPromptText(text);
  }

  // Handle generate button tap - FIXED VERSION
  Future<void> _handleGenerate() async {
    _dismissKeyboard();

    if (isListening) stopListening();

    // Check Internet
    final hasInternet = await isConnected();
    if (!hasInternet) return;

    controller.setPromptText(promptController.text);

    if (controller.imageUrl.isEmpty) {
      showToast('please_select_image_first'.tr);
      return;
    }

    // Check word limit
    int wordCount = _countWords(promptController.text);
    if (wordCount > _maxWordLimit) {
      showToast('wordLimitExceeded'.tr);
      return;
    }

    // Check premium status
    bool isPremium = premiumController.isPaidVersion.value;

    // Check if user is not premium and has already used trial
    if (!isPremium && _hasUsedTrial) {
      // User has already used their free trial → show premium screen
      _showPremiumScreen();
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );

    try {
      final success = await controller.generateSticker().timeout(
        const Duration(seconds: 30),
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (success && controller.generatedStickerUrl.value.isNotEmpty) {
        // Mark trial as used if not premium
        if (!isPremium && !_hasUsedTrial) {
          _hasUsedTrial = true;
          await _saveTrialStatus();
        }

        // Navigate to result
        Get.to(
          () => const UnifiedResultScreen(resultType: ResultType.sticker),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 300),
        );
      } else if (controller.errorMessage.isNotEmpty) {
        showToast(controller.errorMessage.value);
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showToast('generationFailed'.tr);
      print("Generation error: $e");
    }
  }

  // Premium screen show method
  void _showPremiumScreen() {
    // showToast('upgradeForMoreGenerations'.tr);
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
      await prefs.remove('stickerTrialUsed');
      _hasUsedTrial = false;
      if (mounted) setState(() {});
      showToast('Trial reset successfully');
    } catch (e) {
      print("Error resetting trial: $e");
    }
  }

  // Style button tap handler
  void _onStyleTap(int index) {
    _dismissKeyboard();
    setState(() => selectedStyle = index);
    controller.setSelectedStyle(index);
  }

  // Custom Input Formatter to limit words
  TextInputFormatter _getWordLimitingFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      // Count words in new text
      int newWordCount = _countWords(newValue.text);

      // If within word limit, allow it
      if (newWordCount <= _maxWordLimit) {
        return newValue;
      }

      // If exceeds word limit, return old value
      return oldValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveConfig.init(context);

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) {
            controller.clearSelectedImage();
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: BoxDecoration(gradient: BackgroundTheme.background),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// TOP BAR
                          SizedBox(
                            height: 30.h,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Back Button
                                GestureDetector(
                                  onTap: () {
                                    _dismissKeyboard();
                                    controller.clearSelectedImage();
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(5.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 19.sp,
                                    ),
                                  ),
                                ),

                                // Title
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'sticker'.tr,
                                      style: TextStyle(
                                        fontSize: 24.sp,
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

                          SizedBox(height: 10.h),

                          //UPLOAD BOX
                          GestureDetector(
                            onTap: pickImageFromGallery,
                            child: Container(
                              width: double.infinity,
                              height: 250.h,
                              padding: EdgeInsets.all(1.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(30.w),
                              ),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: DottedDecoration(
                                  shape: Shape.box,
                                  borderRadius: BorderRadius.circular(26.w),
                                  color: AppColors.primary,
                                  strokeWidth: 1.5.w,
                                  dash: const <int>[15, 8],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(26.w),
                                  child: controller.imageUrl.isEmpty
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              "assets/icons/upload_file_icon.png",
                                              height: 80.h,
                                            ),
                                            SizedBox(height: 12.h),
                                            Text(
                                              'uploadAPhotoToConvertIntoASticker'
                                                  .tr,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 5.h),
                                            Text(
                                              'supports'.tr,
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Image.file(
                                          File(controller.imageUrl.value),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 15.h),

                          // STYLE SELECTOR
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'selectAStyle'.tr,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            height: 85.h,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              children: [
                                styleButton(
                                  0,
                                  'assets/emojis/classic_style.png',
                                  'styleClassic'.tr,
                                ),
                                styleButton(1, 'assets/emojis/3D.png', '3D'),
                                styleButton(
                                  2,
                                  'assets/emojis/pastel.png',
                                  'pastel'.tr,
                                ),
                                styleButton(
                                  3,
                                  'assets/emojis/minmal.png',
                                  'minimal'.tr,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 10.h),

                          // PROMPT SECTION
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text(
                                      'prompt'.tr,
                                      style: TextStyle(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'optional'.tr,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.h),

                              // PROMPT CONTAINER with Scrollable Text
                              Container(
                                height: 160.h,
                                decoration: BoxDecoration(
                                  color: AppColors.whiteee,
                                  borderRadius: BorderRadius.circular(28.w),
                                ),
                                child: Stack(
                                  children: [
                                    // Text Field with Scroll
                                    Positioned.fill(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: 12.w,
                                          right: 12.w,
                                          top: 10.h,
                                          bottom: 60.h, // Space for buttons
                                        ),
                                        child: Scrollbar(
                                          controller: _promptScrollController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller: _promptScrollController,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            child: TextField(
                                              controller: promptController,
                                              focusNode: _focusNode,
                                              maxLines: null,
                                              onChanged: _onPromptTextChanged,
                                              textInputAction:
                                                  TextInputAction.done,
                                              textAlignVertical:
                                                  TextAlignVertical.top,
                                              onTapOutside: (_) =>
                                                  _dismissKeyboard(),
                                              onSubmitted: (_) =>
                                                  _dismissKeyboard(),
                                              inputFormatters: [
                                                _getWordLimitingFormatter(),
                                              ],
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText:
                                                    'typeYourPromptHere'.tr,
                                                hintStyle: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 16.sp,
                                                ),
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              style: TextStyle(fontSize: 16.sp),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Bottom Buttons (Fixed Position)
                                    Positioned(
                                      bottom: 10.h,
                                      left: 10.w,
                                      right: 10.w,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Paste Button
                                          GestureDetector(
                                            onTap: pasteFromClipboard,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 6.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(20.w),
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
                                                  SizedBox(width: 6.w),
                                                  Text(
                                                    'paste'.tr,
                                                    style: TextStyle(
                                                      fontSize: 16.sp,
                                                      color:
                                                          AppColors.fullwhite,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Mic Button
                                          GestureDetector(
                                            onTap: handleMicTap,
                                            child: Container(
                                              width: 36.w,
                                              height: 36.h,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isListening
                                                    ? AppColors.red
                                                    : AppColors.primary,
                                              ),
                                              child: Icon(
                                                isListening
                                                    ? Icons.mic_off
                                                    : Icons.mic,
                                                color: AppColors.white,
                                                size: 22.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20.h),

                          // GENERATE BUTTON
                          GestureDetector(
                            onTap: _handleGenerate,
                            child: Container(
                              height: 53.h,
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 10.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(40.w),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10.w,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
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

                          /// Trial status indicator (optional)
                          // if (!premiumController.isPaidVersion.value)
                          //   Padding(
                          //     padding: EdgeInsets.only(bottom: 10.h),
                          //     child: Text(
                          //       _hasUsedTrial
                          //           ? 'Upgrade to generate more stickers'
                          //           : 'Free trial: 1 generation available',
                          //       style: TextStyle(
                          //         fontSize: 14.sp,
                          //         color: _hasUsedTrial ? Colors.red : Colors.green,
                          //       ),
                          //       textAlign: TextAlign.center,
                          //     ),
                          //   ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget styleButton(int index, String assetPath, String text) {
    bool selected = index == selectedStyle;

    return GestureDetector(
      onTap: () => _onStyleTap(index),
      child: Container(
        margin: EdgeInsets.only(right: 12.w),
        width: 85.w,
        height: 70.h,
        decoration: BoxDecoration(
          color: AppColors.white30,
          borderRadius: BorderRadius.circular(22.w),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              width: 36.w,
              height: 36.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 2.h),
            Text(
              text,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
