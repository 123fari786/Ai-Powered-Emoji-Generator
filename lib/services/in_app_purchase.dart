// // import 'dart:async';
// //
// // import 'package:flutter/foundation.dart';
// // import 'package:get/get.dart';
// // import 'package:in_app_purchase/in_app_purchase.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // class InAppPurchaseService {
// //   static final InAppPurchaseService _instance =
// //       InAppPurchaseService._internal();
// //
// //   factory InAppPurchaseService() => _instance;
// //
// //   InAppPurchaseService._internal();
// //
// //   final InAppPurchase _inAppPurchase = InAppPurchase.instance;
// //   late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
// //
// //   List<ProductDetails> _products = [];
// //   bool _isAvailable = false;
// //   bool _initialized = false;
// //
// //   // UPDATED Platform-specific product IDs
// //   static List<String> get _productIds {
// //     if (GetPlatform.isIOS) {
// //       // iOS Product IDs
// //       return [
// //         'as.emojimaker.yearlySub', // iOS Yearly Subscription
// //         'as.emojimaker.weeklySub', // iOS Weekly Subscription
// //       ];
// //     } else if (GetPlatform.isAndroid) {
// //       // Android Product IDs (Google Play Console)
// //       return [
// //         'weekly_id', // Android Yearly Subscription
// //         'yearly_id', // Android Weekly Subscription
// //       ];
// //     } else {
// //       return [];
// //     }
// //   }
// //
// //   // Static product ID getters for platform-specific IDs
// //   static String get staticWeeklyProductId {
// //     return GetPlatform.isIOS
// //         ? 'as.emojimaker.weeklySub' // iOS
// //         :      'weekly_id'; // Android
// //   }
// //
// //   static String get staticYearlyProductId {
// //     return GetPlatform.isIOS
// //         ? 'as.emojimaker.yearlySub' // iOS
// //         : 'yearly_id'; // Android
// //   }
// //
// //   // Instance property getters
// //   String get weeklyProductId => staticWeeklyProductId;
// //   String get yearlyProductId => staticYearlyProductId;
// //
// //   // Callbacks
// //   Function(List<ProductDetails>)? onProductsLoaded;
// //   Function(PurchaseDetails)? onPurchaseSuccess;
// //   Function(String)? onPurchaseError;
// //   Function()? onPurchasePending;
// //   Function()? onPurchasesRestored;
// //
// //   SharedPreferences? _prefs;
// //   static const String _kPrefPurchasedKey = 'iap_purchased_ids';
// //
// //   // Initialize the service
// //   Future<bool> initialize() async {
// //     if (_initialized) return _isAvailable;
// //
// //     try {
// //       _prefs = await SharedPreferences.getInstance();
// //       _isAvailable = await _inAppPurchase.isAvailable();
// //
// //       if (!_isAvailable) {
// //         print('In-app purchases are not available on this device.');
// //         return false;
// //       }
// //
// //       _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
// //         _handlePurchaseUpdates,
// //         onDone: () => print('Purchase stream closed'),
// //         onError: (error) => print('Purchase stream error: $error'),
// //       );
// //
// //       _initialized = true;
// //       return true;
// //     } catch (e) {
// //       print('Error initializing in-app purchase: $e');
// //       return false;
// //     }
// //   }
// //
// //   // Load products
// //   Future<void> loadProducts() async {
// //     try {
// //       if (!_isAvailable) {
// //         onPurchaseError?.call(
// //           'In-app purchases are not available on this device.',
// //         );
// //         return;
// //       }
// //
// //       final ProductDetailsResponse response = await _inAppPurchase
// //           .queryProductDetails(_productIds.toSet());
// //
// //       if (response.notFoundIDs.isNotEmpty) {
// //         print("Products not found: ${response.notFoundIDs}");
// //       }
// //
// //       if (response.error != null) {
// //         print("Error loading products: ${response.error}");
// //         onPurchaseError?.call("Failed to load products: ${response.error}");
// //         return;
// //       }
// //
// //       _products = response.productDetails;
// //
// //       print('=== LOADED PRODUCTS ===');
// //       for (var product in _products) {
// //         print('ID: ${product.id}');
// //         print('Title: ${product.title}');
// //         print('Price: ${product.price}');
// //         print('Description: ${product.description}');
// //         print('----------------------');
// //       }
// //
// //       onProductsLoaded?.call(_products);
// //     } catch (e) {
// //       print('Error loading products: $e');
// //       onPurchaseError?.call('Failed to load products: ${e.toString()}');
// //     }
// //   }
// //
// //   // Get product by ID
// //   ProductDetails? getProductById(String productId) {
// //     try {
// //       return _products.firstWhere((p) => p.id == productId);
// //     } catch (e) {
// //       return null;
// //     }
// //   }
// //
// //   // Get price for product
// //   String getPriceForProduct(String productId) {
// //     final product = getProductById(productId);
// //     if (product != null) {
// //       return product.price;
// //     } else {
// //       // Fallback prices for testing
// //       if (productId == yearlyProductId || productId == staticYearlyProductId) {
// //         return GetPlatform.isAndroid ? '\$79.99/year' : '\$99.99/year';
// //       }
// //       if (productId == weeklyProductId || productId == staticWeeklyProductId) {
// //         return GetPlatform.isAndroid ? '\$23.99/week' : '\$29.99/week';
// //       }
// //       return 'Not Available';
// //     }
// //   }
// //
// //   // Buy product
// //   Future<void> buyProduct(String productId) async {
// //     try {
// //       final product = getProductById(productId);
// //       if (product == null) {
// //         // Try alternative casing for Android
// //         if (GetPlatform.isAndroid) {
// //           final altProductId = productId.toLowerCase();
// //           final altProduct = getProductById(altProductId);
// //           if (altProduct != null) {
// //             await _buyProductWithDetails(altProduct);
// //             return;
// //           }
// //         }
// //         throw Exception('Product not found: $productId');
// //       }
// //
// //       await _buyProductWithDetails(product);
// //     } catch (e) {
// //       onPurchaseError?.call('Failed to purchase: ${e.toString()}');
// //       rethrow;
// //     }
// //   }
// //
// //   Future<void> _buyProductWithDetails(ProductDetails product) async {
// //     try {
// //       final PurchaseParam purchaseParam = PurchaseParam(
// //         productDetails: product,
// //       );
// //
// //       print('Purchasing: ${product.id} - ${product.title} - ${product.price}');
// //
// //       if (product.id.contains('sub')) {
// //         await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
// //       } else {
// //         await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
// //       }
// //     } catch (e) {
// //       print('Buy product error: $e');
// //       rethrow;
// //     }
// //   }
// //
// //   // Restore purchases
// //   Future<void> restorePurchases() async {
// //     try {
// //       onPurchasePending?.call();
// //       await _inAppPurchase.restorePurchases();
// //
// //       // Wait for stream to process
// //       await Future.delayed(Duration(seconds: 3));
// //
// //       final localPurchases =
// //           _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //
// //       if (localPurchases.isNotEmpty) {
// //         print("Restored local purchases: $localPurchases");
// //         onPurchasesRestored?.call();
// //       } else {
// //         onPurchaseError?.call("No previous purchases found");
// //       }
// //     } catch (e) {
// //       print("Failed to restore purchases: $e");
// //       onPurchaseError?.call("Failed to restore purchases");
// //     }
// //   }
// //
// //   // Handle purchase updates
// //   void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
// //     print("Purchase Updates: ${purchaseDetailsList.length}");
// //
// //     for (var purchaseDetails in purchaseDetailsList) {
// //       print("Purchase Status: ${purchaseDetails.status}");
// //       print("Product ID: ${purchaseDetails.productID}");
// //       print("Pending Complete: ${purchaseDetails.pendingCompletePurchase}");
// //
// //       switch (purchaseDetails.status) {
// //         case PurchaseStatus.pending:
// //           print('Purchase pending...');
// //           onPurchasePending?.call();
// //           break;
// //
// //         case PurchaseStatus.purchased:
// //         case PurchaseStatus.restored:
// //           print('Purchase successful/restored');
// //           _verifyAndCompletePurchase(purchaseDetails);
// //           onPurchaseSuccess?.call(purchaseDetails);
// //           break;
// //
// //         case PurchaseStatus.error:
// //           print('Purchase error: ${purchaseDetails.error?.message}');
// //           onPurchaseError?.call(
// //             purchaseDetails.error?.message ?? "Unknown error",
// //           );
// //           break;
// //
// //         case PurchaseStatus.canceled:
// //           print('Purchase cancelled');
// //           onPurchaseError?.call("Purchase cancelled by user");
// //           break;
// //       }
// //     }
// //   }
// //
// //   // Verify + complete purchase
// //   Future<void> _verifyAndCompletePurchase(
// //     PurchaseDetails purchaseDetails,
// //   ) async {
// //     try {
// //       bool isValid = await _verifyPurchase(purchaseDetails);
// //
// //       if (isValid) {
// //         await _storePurchaseLocally(purchaseDetails);
// //
// //         if (purchaseDetails.pendingCompletePurchase) {
// //           print('Completing purchase...');
// //           await _inAppPurchase.completePurchase(purchaseDetails);
// //         } else {
// //           print('Purchase already completed');
// //         }
// //
// //         print('Purchase verified and stored successfully');
// //       } else {
// //         print('Purchase verification failed');
// //         onPurchaseError?.call('Purchase verification failed');
// //       }
// //     } catch (e) {
// //       print("Error completing purchase: $e");
// //       onPurchaseError?.call("Error completing purchase: $e");
// //     }
// //   }
// //
// //   Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
// //     try {
// //       // For testing, always return true
// //       if (kDebugMode) {
// //         print('Debug mode: Skipping purchase verification');
// //         return true;
// //       }
// //
// //       // For production, verify with server
// //       final serverData =
// //           purchaseDetails.verificationData.serverVerificationData;
// //       return serverData.isNotEmpty;
// //     } catch (e) {
// //       print('Verification error: $e');
// //       return false;
// //     }
// //   }
// //
// //   // Store purchase locally
// //   Future<void> _storePurchaseLocally(PurchaseDetails purchaseDetails) async {
// //     try {
// //       final productId = purchaseDetails.productID.toLowerCase();
// //       final List<String> current =
// //           _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //
// //       // Add both variants for Android compatibility
// //       if (!current.contains(productId)) {
// //         current.add(productId);
// //
// //         // Also add uppercase variant for iOS compatibility
// //         if (GetPlatform.isAndroid) {
// //           final upperVariant = productId.replaceAll('sub', 'Sub');
// //           if (!current.contains(upperVariant)) {
// //             current.add(upperVariant);
// //           }
// //         }
// //
// //         await _prefs?.setStringList(_kPrefPurchasedKey, current);
// //       }
// //
// //       // Store additional info
// //       await _prefs?.setBool('isPremium', true);
// //       await _prefs?.setString('productId', productId);
// //       await _prefs?.setString('purchaseDate', DateTime.now().toIso8601String());
// //
// //       print('Purchase stored locally: $productId');
// //     } catch (e) {
// //       print("Error saving purchase: $e");
// //     }
// //   }
// //
// //   // Check if purchased
// //   bool isPurchased(String productId) {
// //     final current = _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //     final lowerId = productId.toLowerCase();
// //     final upperId = productId.replaceAll('sub', 'Sub');
// //
// //     return current.contains(productId) ||
// //         current.contains(lowerId) ||
// //         current.contains(upperId);
// //   }
// //
// //   // Check subscription access
// //   Future<bool> hasPremiumAccess() async {
// //     final current = _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //
// //     // Check for yearly subscription (both casing)
// //     final yearlyId = yearlyProductId.toLowerCase();
// //     final yearlyIdUpper = yearlyProductId.replaceAll('sub', 'Sub');
// //     if (current.contains(yearlyId) || current.contains(yearlyIdUpper)) {
// //       return true;
// //     }
// //
// //     // Check for weekly subscription (both casing)
// //     final weeklyId = weeklyProductId.toLowerCase();
// //     final weeklyIdUpper = weeklyProductId.replaceAll('sub', 'Sub');
// //     if (current.contains(weeklyId) || current.contains(weeklyIdUpper)) {
// //       return true;
// //     }
// //
// //     return _prefs?.getBool('isPremium') ?? false;
// //   }
// //
// //   // Clear cache (for testing)
// //   Future<void> clearPurchaseCache() async {
// //     await _prefs?.remove(_kPrefPurchasedKey);
// //     await _prefs?.remove('isPremium');
// //     print("Purchase cache cleared");
// //   }
// //
// //   // Dispose
// //   void dispose() {
// //     _purchaseSubscription.cancel();
// //     _initialized = false;
// //   }
// //
// //   // Getters
// //   List<ProductDetails> get products => _products;
// //   bool get isAvailable => _isAvailable;
// //   bool get isLoading => _initialized && _products.isEmpty;
// // }
// // import 'dart:async';
// // import 'dart:convert';
// //
// // import 'package:flutter/foundation.dart';
// // import 'package:get/get.dart';
// // import 'package:in_app_purchase/in_app_purchase.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// //
// // import '../utils/trial_manager.dart';
// //
// // class InAppPurchaseService {
// //   static final InAppPurchaseService _instance =
// //       InAppPurchaseService._internal();
// //   factory InAppPurchaseService() => _instance;
// //   InAppPurchaseService._internal();
// //
// //   final InAppPurchase _inAppPurchase = InAppPurchase.instance;
// //   late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
// //
// //   List<ProductDetails> _products = [];
// //   bool _isAvailable = false;
// //   bool _initialized = false;
// //
// //   // NEW: Variables to block automatic restore
// //   bool _ignoreInitialRestoreEvents = true;
// //   Timer? _restoreBlockTimer;
// //   bool _userInitiatedRestore = false;
// //
// //   // Platform-specific product IDs
// //   static List<String> get _productIds {
// //     if (GetPlatform.isIOS) {
// //       return ['as.emojimaker.yearlySub', 'as.emojimaker.weeklySub'];
// //     } else if (GetPlatform.isAndroid) {
// //       return ['weekly_id', 'yearly_id'];
// //     } else {
// //       return [];
// //     }
// //   }
// //
// //   // Static product ID getters
// //   static String get staticWeeklyProductId {
// //     return GetPlatform.isIOS ? 'as.emojimaker.weeklySub' : 'weekly_id';
// //   }
// //
// //   static String get staticYearlyProductId {
// //     return GetPlatform.isIOS ? 'as.emojimaker.yearlySub' : 'yearly_id';
// //   }
// //
// //   // Instance property getters
// //   String get weeklyProductId => staticWeeklyProductId;
// //   String get yearlyProductId => staticYearlyProductId;
// //
// //   // Callbacks
// //   Function(List<ProductDetails>)? onProductsLoaded;
// //   Function(PurchaseDetails)? onPurchaseSuccess;
// //   Function(String)? onPurchaseError;
// //   Function()? onPurchasePending;
// //   Function()? onPurchasesRestored;
// //   Function(bool isPremium)? onPremiumStatusChanged;
// //
// //   SharedPreferences? _prefs;
// //   static const String _kPrefPurchasedKey = 'iap_purchased_ids';
// //   static const String _kIsPremiumKey = 'isPremium';
// //   static const String _kPremiumExpiryKey = 'premium_expiry_date';
// //   static const String _kPurchaseTokenKey = 'purchase_token';
// //   static const String _kCancelDate = 'cancel_date';
// //   static const String _kAppStartTime = 'app_start_time'; // NEW
// //
// //   // Stream controller for premium status updates
// //   final StreamController<bool> _premiumStatusController =
// //       StreamController<bool>.broadcast();
// //   Stream<bool> get premiumStatusStream => _premiumStatusController.stream;
// //
// //   // Initialize the service
// //   Future<bool> initialize() async {
// //     if (_initialized) return _isAvailable;
// //
// //     try {
// //       _prefs = await SharedPreferences.getInstance();
// //       _isAvailable = await _inAppPurchase.isAvailable();
// //
// //       print('🎯 IAP INITIALIZE - Available: $_isAvailable');
// //
// //       if (!_isAvailable) {
// //         print('❌ IAP not available');
// //         return false;
// //       }
// //
// //       // Store app start time to detect fresh start
// //       await _prefs?.setString(_kAppStartTime, DateTime.now().toIso8601String());
// //       print('📱 App start time recorded');
// //
// //       // Setup purchase stream listener with auto-restore blocking
// //       _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
// //         _handlePurchaseUpdates,
// //         onDone: () => print('Purchase stream closed'),
// //         onError: (error) => print('Purchase stream error: $error'),
// //       );
// //
// //       _initialized = true;
// //
// //       // Check subscription status immediately
// //       await _checkSubscriptionValidity();
// //
// //       // NEW: Start timer to block initial auto-restore events (10 seconds)
// //       _startRestoreBlockTimer();
// //
// //       return true;
// //     } catch (e) {
// //       print('❌ Error initializing IAP: $e');
// //       return false;
// //     }
// //   }
// //
// //   // NEW: Start timer to block automatic restore events on app start
// //   void _startRestoreBlockTimer() {
// //     print('⏱️ Starting restore block timer (10 seconds)');
// //     _ignoreInitialRestoreEvents = true;
// //
// //     // Clear any existing timer first
// //     _restoreBlockTimer?.cancel();
// //
// //     _restoreBlockTimer = Timer(Duration(seconds: 10), () {
// //       print('✅ Restore block timer expired - now accepting restore events');
// //       _ignoreInitialRestoreEvents = false;
// //       _restoreBlockTimer = null;
// //     });
// //   }
// //
// //   // Main method to check if subscription is valid
// //   Future<void> _checkSubscriptionValidity() async {
// //     print('🔍 CHECKING SUBSCRIPTION VALIDITY');
// //
// //     // Check if subscription was cancelled
// //     final isCancelled = _prefs?.getBool('is_cancelled') ?? false;
// //     final cancelDate = _prefs?.getString(_kCancelDate);
// //
// //     if (isCancelled && cancelDate != null) {
// //       print('❌ SUBSCRIPTION WAS CANCELLED on $cancelDate');
// //       await _setPremiumStatus(false);
// //       return;
// //     }
// //
// //     // Check expiry date
// //     final expiryDateStr = _prefs?.getString(_kPremiumExpiryKey);
// //     if (expiryDateStr != null) {
// //       try {
// //         final expiryDate = DateTime.parse(expiryDateStr);
// //         final now = DateTime.now();
// //
// //         print('📅 Expiry Date: $expiryDate');
// //         print('📅 Current Date: $now');
// //         print('📅 Is Expired: ${now.isAfter(expiryDate)}');
// //
// //         if (now.isAfter(expiryDate)) {
// //           print('❌ SUBSCRIPTION EXPIRED');
// //           await _setPremiumStatus(false);
// //         } else {
// //           print('✅ Subscription still valid');
// //         }
// //       } catch (e) {
// //         print('❌ Error parsing expiry date: $e');
// //       }
// //     } else {
// //       print('📭 No expiry date found - User is not premium');
// //     }
// //   }
// //   // InAppPurchaseService class mein yeh method add karein ya update karein:
// //
// //   // Cancel hone ke baad dobara purchase karne ka method
// //   Future<void> purchaseAfterCancellation(String productId) async {
// //     try {
// //       print('🔄 PURCHASING AFTER CANCELLATION: $productId');
// //
// //       // 1. Clear cancellation marks
// //       await _prefs?.remove('is_cancelled');
// //       await _prefs?.remove(_kCancelDate);
// //
// //       // 2. Clear existing purchase data
// //       await _clearExistingPurchaseData();
// //
// //       // 3. Now purchase new subscription
// //       await buyProduct(productId);
// //     } catch (e) {
// //       print('❌ Error in purchase after cancellation: $e');
// //       rethrow;
// //     }
// //   }
// //
// //   // Existing purchase data clear karne ka method
// //   Future<void> _clearExistingPurchaseData() async {
// //     print('🗑️ Clearing existing purchase data for fresh purchase');
// //
// //     // Local purchase list se remove karein
// //     final current = _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //     current.clear();
// //     await _prefs?.setStringList(_kPrefPurchasedKey, current);
// //
// //     // Premium status clear karein
// //     await _prefs?.remove(_kIsPremiumKey);
// //     await _prefs?.remove(_kPremiumExpiryKey);
// //     await _prefs?.remove(_kPurchaseTokenKey);
// //     await _prefs?.remove('productId');
// //     await _prefs?.remove('purchaseDate');
// //
// //     print('✅ Existing purchase data cleared');
// //   }
// //
// //   // Modified restorePurchases method - cancel hone ke baad restore block karein
// //   // InAppPurchaseService class mein restorePurchases method ko update karein:
// //
// //   Future<void> restorePurchases() async {
// //     try {
// //       print('🔄 USER INITIATED RESTORE PURCHASES');
// //
// //       // Set flag that this is user initiated
// //       _userInitiatedRestore = true;
// //
// //       // Disable ignore flag for user initiated restore
// //       _ignoreInitialRestoreEvents = false;
// //
// //       // Check if subscription was cancelled
// //       final isCancelled = _prefs?.getBool('is_cancelled') ?? false;
// //       if (isCancelled) {
// //         print('❌ CANNOT RESTORE - Subscription was cancelled');
// //         onPurchaseError?.call(
// //           "Your subscription was cancelled. Please purchase a new subscription.",
// //         );
// //         _userInitiatedRestore = false;
// //         return;
// //       }
// //
// //       onPurchasePending?.call();
// //
// //       print('🔍 Calling restorePurchases()...');
// //
// //       // NEW: Timeout add karein
// //       final restoreFuture = _inAppPurchase.restorePurchases();
// //
// //       // Timeout after 15 seconds
// //       await restoreFuture.timeout(
// //         Duration(seconds: 15),
// //         onTimeout: () {
// //           print('⚠️ Restore timeout after 15 seconds');
// //           throw TimeoutException('Restore operation timed out');
// //         },
// //       );
// //
// //       // Wait for stream to process
// //       print('⏳ Waiting for restore events...');
// //       await Future.delayed(Duration(seconds: 2));
// //
// //       // NEW: Check local purchases first
// //       final localPurchases =
// //           _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //       print('📋 Local purchases found: $localPurchases');
// //
// //       // NEW: Also check premium status from other sources
// //       final hasPremium = await hasPremiumAccess();
// //
// //       if (localPurchases.isNotEmpty || hasPremium) {
// //         print('✅ Purchases restored');
// //         onPurchasesRestored?.call();
// //       } else {
// //         print('❌ No previous purchases found');
// //
// //         // NEW: Additional check - if cancelled but not properly marked
// //         final expiryDateStr = _prefs?.getString(_kPremiumExpiryKey);
// //         if (expiryDateStr != null) {
// //           final expiryDate = DateTime.parse(expiryDateStr);
// //           if (DateTime.now().isAfter(expiryDate)) {
// //             onPurchaseError?.call(
// //               "Your subscription has expired. Please renew.",
// //             );
// //           } else {
// //             onPurchaseError?.call(
// //               "No active subscription found. Please purchase.",
// //             );
// //           }
// //         } else {
// //           onPurchaseError?.call("No previous purchases found");
// //         }
// //       }
// //
// //       // Reset flag
// //       _userInitiatedRestore = false;
// //     } on TimeoutException catch (e) {
// //       print('❌ Restore timed out: $e');
// //       onPurchaseError?.call(
// //         "Restore timed out. Please check your connection and try again.",
// //       );
// //       _userInitiatedRestore = false;
// //     } catch (e) {
// //       print("❌ Error restoring purchases: $e");
// //       onPurchaseError?.call("Failed to restore purchases: ${e.toString()}");
// //       _userInitiatedRestore = false;
// //     }
// //   }
// //
// //   // NEW: Add a method to force clear pending loader
// //   void _clearPendingState() {
// //     // Clear any pending state
// //     if (onPurchasePending != null) {
// //       // Send a delayed callback to clear loading state
// //       Future.delayed(Duration(seconds: 1), () {
// //         // This will help UI to clear loading state
// //       });
// //     }
// //   } // Load products
// //   // In your InAppPurchaseService class, update the loadProducts method:
// //
// //   Future<void> loadProducts() async {
// //     try {
// //       print('🛍️ LOADING PRODUCTS...');
// //
// //       if (!_isAvailable) {
// //         print('❌ IAP not available');
// //         onPurchaseError?.call('In-app purchases are not available');
// //         return;
// //       }
// //
// //       print('📋 Product IDs to fetch: $_productIds');
// //       final ProductDetailsResponse response = await _inAppPurchase
// //           .queryProductDetails(_productIds.toSet());
// //
// //       print('📦 Response error: ${response.error}');
// //       print('📦 Products not found: ${response.notFoundIDs}');
// //       print('📦 Products loaded: ${response.productDetails.length}');
// //
// //       if (response.error != null) {
// //         print('❌ Error from store: ${response.error}');
// //         onPurchaseError?.call('Store error: ${response.error}');
// //         return;
// //       }
// //
// //       _products = response.productDetails;
// //
// //       if (_products.isEmpty) {
// //         print('⚠️ WARNING: No products found in store!');
// //         print(
// //           '⚠️ Check if product IDs are configured correctly in App Store/Play Console',
// //         );
// //         print('⚠️ iOS IDs should be in App Store Connect');
// //         print('⚠️ Android IDs should be in Google Play Console');
// //
// //         // Call onProductsLoaded with empty list so UI can handle it
// //         onProductsLoaded?.call(_products);
// //         return;
// //       }
// //
// //       for (var product in _products) {
// //         print(
// //           '💰 Product: ${product.id} - ${product.title} - ${product.price}',
// //         );
// //       }
// //
// //       onProductsLoaded?.call(_products);
// //     } catch (e) {
// //       print('❌ Error loading products: $e');
// //       onPurchaseError?.call('Failed to load products: ${e.toString()}');
// //     }
// //   }
// //
// //   // Get product by ID
// //   ProductDetails? getProductById(String productId) {
// //     try {
// //       return _products.firstWhere((p) => p.id == productId);
// //     } catch (e) {
// //       print('❌ Product not found: $productId');
// //       return null;
// //     }
// //   }
// //
// //   // Get price for product
// //   String getPriceForProduct(String productId) {
// //     final product = getProductById(productId);
// //     if (product != null) {
// //       return product.price;
// //     } else {
// //       print('⚠️ Product $productId not found, using fallback');
// //       if (productId == yearlyProductId || productId == staticYearlyProductId) {
// //         return GetPlatform.isAndroid ? '\$79.99/year' : '\$99.99/year';
// //       }
// //       if (productId == weeklyProductId || productId == staticWeeklyProductId) {
// //         return GetPlatform.isAndroid ? '\$23.99/week' : '\$29.99/week';
// //       }
// //       return 'Not Available';
// //     }
// //   }
// //
// //   // Buy product
// //   Future<void> buyProduct(String productId) async {
// //     try {
// //       print('🛒 BUYING PRODUCT: $productId');
// //
// //       final product = getProductById(productId);
// //       if (product == null) {
// //         print('❌ Product not found: $productId');
// //         throw Exception('Product not found: $productId');
// //       }
// //
// //       print('✅ Found product: ${product.id}');
// //       await _buyProductWithDetails(product);
// //     } catch (e) {
// //       print('❌ Error buying product: $e');
// //       onPurchaseError?.call('Failed to purchase: ${e.toString()}');
// //       rethrow;
// //     }
// //   }
// //
// //   Future<void> _buyProductWithDetails(ProductDetails product) async {
// //     try {
// //       final PurchaseParam purchaseParam = PurchaseParam(
// //         productDetails: product,
// //       );
// //
// //       print('💳 Purchasing: ${product.id} - ${product.price}');
// //
// //       // Add a timeout for the purchase operation
// //       final purchaseFuture = product.id.contains('sub')
// //           ? _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam)
// //           : _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
// //
// //       // Wait for purchase with timeout
// //       await purchaseFuture.timeout(
// //         Duration(seconds: 30),
// //         onTimeout: () {
// //           print('❌ Purchase timeout after 30 seconds');
// //           throw TimeoutException(
// //             'Purchase operation timed out. Please check your internet connection and try again.',
// //           );
// //         },
// //       );
// //     } catch (e) {
// //       print('❌ Error in purchase: $e');
// //
// //       // Handle specific error types
// //       if (e is TimeoutException) {
// //         onPurchaseError?.call(
// //           'Connection timeout. Please check your internet and try again.',
// //         );
// //       } else if (e.toString().contains('network')) {
// //         onPurchaseError?.call('Network error. Please check your connection.');
// //       }
// //
// //       rethrow;
// //     }
// //   }
// //
// //   // Restore purchases - USER INITIATED ONLY
// //   // Future<void> restorePurchases() async {
// //   //   try {
// //   //     print('🔄 USER INITIATED RESTORE PURCHASES');
// //   //
// //   //     // Set flag that this is user initiated
// //   //     _userInitiatedRestore = true;
// //   //
// //   //     // Disable ignore flag for user initiated restore
// //   //     _ignoreInitialRestoreEvents = false;
// //   //
// //   //     // Check if subscription was cancelled
// //   //     final isCancelled = _prefs?.getBool('is_cancelled') ?? false;
// //   //     if (isCancelled) {
// //   //       print('❌ CANNOT RESTORE - Subscription was cancelled');
// //   //       onPurchaseError?.call(
// //   //         "Subscription was cancelled and cannot be restored",
// //   //       );
// //   //       _userInitiatedRestore = false;
// //   //       return;
// //   //     }
// //   //
// //   //     onPurchasePending?.call();
// //   //
// //   //     print('Calling restorePurchases()...');
// //   //     await _inAppPurchase.restorePurchases();
// //   //
// //   //     // Wait for stream to process
// //   //     await Future.delayed(Duration(seconds: 3));
// //   //
// //   //     final localPurchases =
// //   //         _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //   //     print('📋 Local purchases found: $localPurchases');
// //   //
// //   //     if (localPurchases.isNotEmpty) {
// //   //       print('✅ Purchases restored');
// //   //       onPurchasesRestored?.call();
// //   //     } else {
// //   //       print('❌ No previous purchases found');
// //   //       onPurchaseError?.call("No previous purchases found");
// //   //     }
// //   //
// //   //     // Reset flag
// //   //     _userInitiatedRestore = false;
// //   //   } catch (e) {
// //   //     print("❌ Error restoring purchases: $e");
// //   //     onPurchaseError?.call("Failed to restore purchases");
// //   //     _userInitiatedRestore = false;
// //   //   }
// //   // }
// //
// //   // Handle purchase updates - MODIFIED TO BLOCK AUTO-RESTORE
// //   // void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
// //   //   print('📨 PURCHASE UPDATES: ${purchaseDetailsList.length}');
// //   //
// //   //   for (var purchaseDetails in purchaseDetailsList) {
// //   //     print('--- Purchase Details ---');
// //   //     print('Status: ${purchaseDetails.status}');
// //   //     print('Product: ${purchaseDetails.productID}');
// //   //     print('Pending: ${purchaseDetails.pendingCompletePurchase}');
// //   //
// //   //     if (purchaseDetails.error != null) {
// //   //       print('Error: ${purchaseDetails.error?.message}');
// //   //     }
// //   //
// //   //     // NEW: Check if this is an automatic restore on app start
// //   //     final isRestored = purchaseDetails.status == PurchaseStatus.restored;
// //   //     final isOnAppStart =
// //   //         _ignoreInitialRestoreEvents && !_userInitiatedRestore;
// //   //
// //   //     if (isRestored && isOnAppStart) {
// //   //       print('🚫 BLOCKING AUTOMATIC RESTORE ON APP START');
// //   //       print(
// //   //         'ℹ️ This restore event is being ignored because it happened automatically',
// //   //       );
// //   //       print('ℹ️ User must manually tap "Restore" to restore purchases');
// //   //       continue; // Skip this restore event
// //   //     }
// //   //
// //   //     switch (purchaseDetails.status) {
// //   //       case PurchaseStatus.pending:
// //   //         print('⏳ Purchase PENDING');
// //   //         onPurchasePending?.call();
// //   //         break;
// //   //
// //   //       case PurchaseStatus.purchased:
// //   //         print('✅ Purchase SUCCESSFUL');
// //   //         _verifyAndCompletePurchase(purchaseDetails);
// //   //         onPurchaseSuccess?.call(purchaseDetails);
// //   //         break;
// //   //
// //   //       case PurchaseStatus.restored:
// //   //         print('✅ Purchase RESTORED (User initiated)');
// //   //         _verifyAndCompletePurchase(purchaseDetails);
// //   //         onPurchaseSuccess?.call(purchaseDetails);
// //   //         break;
// //   //
// //   //       case PurchaseStatus.error:
// //   //         print('❌ Purchase ERROR');
// //   //         _checkForCancellation(purchaseDetails);
// //   //         onPurchaseError?.call(
// //   //           purchaseDetails.error?.message ?? "Unknown error",
// //   //         );
// //   //         break;
// //   //
// //   //       case PurchaseStatus.canceled:
// //   //         print('🚫 Purchase CANCELLED BY USER');
// //   //         _markAsCancelled(purchaseDetails);
// //   //         onPurchaseError?.call("Purchase cancelled by user");
// //   //         break;
// //   //     }
// //   //   }
// //   // }
// //
// //   // Check if error indicates cancellation
// //   void _checkForCancellation(PurchaseDetails purchaseDetails) {
// //     final errorMessage = purchaseDetails.error?.message?.toLowerCase() ?? '';
// //     print('🔍 Checking error for cancellation: $errorMessage');
// //
// //     if (errorMessage.contains('cancel') ||
// //         errorMessage.contains('expired') ||
// //         errorMessage.contains('refund') ||
// //         errorMessage.contains('revoked') ||
// //         errorMessage.contains('not renewed')) {
// //       print('⚠️ CANCELLATION DETECTED FROM ERROR');
// //       _markAsCancelled(purchaseDetails);
// //     }
// //   }
// //   // InAppPurchaseService class mein yeh method add karein:
// //
// //   // NEW: Check if purchase is cancelled by user
// //   Future<bool> _checkIfPurchaseCancelled(
// //     PurchaseDetails purchaseDetails,
// //   ) async {
// //     try {
// //       print('🔍 CHECKING IF PURCHASE IS CANCELLED');
// //
// //       // Platform-specific checks
// //       if (GetPlatform.isAndroid) {
// //         return await _checkAndroidCancellation(purchaseDetails);
// //       } else if (GetPlatform.isIOS) {
// //         return await _checkIOSCancellation(purchaseDetails);
// //       }
// //
// //       return false;
// //     } catch (e) {
// //       print('❌ Error checking cancellation: $e');
// //       return false;
// //     }
// //   }
// //
// //   // NEW: Android ke liye cancellation check
// //   Future<bool> _checkAndroidCancellation(
// //     PurchaseDetails purchaseDetails,
// //   ) async {
// //     try {
// //       // Android mein purchaseDetails.verificationData check karein
// //       final verificationData = purchaseDetails.verificationData;
// //
// //       if (verificationData.serverVerificationData.isEmpty) {
// //         print('⚠️ No server verification data');
// //         return false;
// //       }
// //
// //       // Parse the JSON response
// //       final jsonResponse = json.decode(verificationData.serverVerificationData);
// //       final purchaseState = jsonResponse['purchaseState'];
// //       final acknowledgementState = jsonResponse['acknowledgementState'];
// //
// //       print('📊 Android Purchase State: $purchaseState');
// //       print('📊 Android Acknowledgement State: $acknowledgementState');
// //
// //       // PurchaseState 1 = Purchased, 2 = Pending, 0 = Cancelled?
// //       // Actually: 0 = Purchased, 1 = Cancelled, 2 = Pending
// //       if (purchaseState == 1) {
// //         print('❌ ANDROID: Purchase is CANCELLED');
// //         return true;
// //       }
// //
// //       // AcknowledgementState 0 = Not acknowledged, 1 = Acknowledged
// //       if (acknowledgementState == 0) {
// //         print('⚠️ ANDROID: Purchase not acknowledged');
// //       }
// //
// //       return false;
// //     } catch (e) {
// //       print('❌ Error in Android cancellation check: $e');
// //       return false;
// //     }
// //   }
// //
// //   // NEW: iOS ke liye cancellation check
// //   // _checkIOSCancellation method ko update karein:
// //
// //   Future<bool> _checkIOSCancellation(PurchaseDetails purchaseDetails) async {
// //     try {
// //       print('📊 iOS Status: ${purchaseDetails.status}');
// //
// //       // Safely check transaction date
// //       try {
// //         if (purchaseDetails.transactionDate != null) {
// //           DateTime? transactionDate;
// //
// //           // Handle different formats of transactionDate
// //           if (purchaseDetails.transactionDate is DateTime) {
// //             transactionDate = purchaseDetails.transactionDate as DateTime;
// //           } else if (purchaseDetails.transactionDate is String) {
// //             final dateString = purchaseDetails.transactionDate as String;
// //             transactionDate = DateTime.tryParse(dateString);
// //           }
// //
// //           if (transactionDate != null) {
// //             final now = DateTime.now();
// //             final daysSincePurchase = now.difference(transactionDate).inDays;
// //
// //             print('📅 Transaction Date: $transactionDate');
// //             print('📅 Days since purchase: $daysSincePurchase');
// //
// //             // Agar 2 din se kam hai, to valid hai
// //             if (daysSincePurchase < 2) {
// //               print('✅ Recent purchase (within 2 days)');
// //               return false;
// //             }
// //
// //             // Agar 30 din se zyada ho gaye, possible cancellation
// //             if (daysSincePurchase > 30) {
// //               print('⚠️ Purchase is older than 30 days');
// //               // Check cancellation status in local storage
// //               final prefs = await SharedPreferences.getInstance();
// //               final isCancelled = prefs.getBool('is_cancelled') ?? false;
// //               return isCancelled;
// //             }
// //           }
// //         }
// //       } catch (e) {
// //         print('⚠️ Error parsing transaction date: $e');
// //       }
// //
// //       // Check if there's an error message indicating cancellation
// //       final errorMsg = purchaseDetails.error?.message?.toLowerCase() ?? '';
// //       if (errorMsg.contains('cancel') ||
// //           errorMsg.contains('refund') ||
// //           errorMsg.contains('revoke') ||
// //           errorMsg.contains('expired')) {
// //         print('❌ iOS: Cancellation detected in error message: $errorMsg');
// //         return true;
// //       }
// //
// //       // Check status for cancellation indicators
// //       if (purchaseDetails.status == PurchaseStatus.error) {
// //         print('⚠️ iOS: Purchase status is ERROR');
// //
// //         // Additional iOS-specific checks
// //         if (errorMsg.contains('subscription') && errorMsg.contains('not')) {
// //           return true;
// //         }
// //       }
// //
// //       return false;
// //     } catch (e) {
// //       print('❌ Error in iOS cancellation check: $e');
// //       return false;
// //     }
// //   }
// //
// //   // Modified _handlePurchaseUpdates method:
// //   void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
// //     print('📨 PURCHASE UPDATES: ${purchaseDetailsList.length}');
// //
// //     for (var purchaseDetails in purchaseDetailsList) {
// //       print('--- Purchase Details ---');
// //       print('Status: ${purchaseDetails.status}');
// //       print('Product: ${purchaseDetails.productID}');
// //       print('Pending: ${purchaseDetails.pendingCompletePurchase}');
// //
// //       if (purchaseDetails.transactionDate != null) {
// //         print('Transaction Date: ${purchaseDetails.transactionDate}');
// //       }
// //
// //       if (purchaseDetails.error != null) {
// //         print('Error: ${purchaseDetails.error?.message}');
// //       }
// //
// //       // NEW: Check if this purchase is cancelled
// //       final isCancelled = await _checkIfPurchaseCancelled(purchaseDetails);
// //       if (isCancelled) {
// //         print('🚫 PURCHASE IS CANCELLED - Skipping');
// //         await _markAsCancelled(purchaseDetails);
// //         onPurchaseError?.call("This purchase has been cancelled");
// //         continue;
// //       }
// //
// //       // Rest of existing code...
// //     }
// //   }
// //
// //   // Immediately mark subscription as cancelled
// //   Future<void> _markAsCancelled(PurchaseDetails purchaseDetails) async {
// //     try {
// //       final productId = purchaseDetails.productID.toLowerCase();
// //       print('🚫 MARKING AS CANCELLED: $productId');
// //
// //       // Clear all premium data
// //       await _prefs?.remove(_kIsPremiumKey);
// //       await _prefs?.remove(_kPremiumExpiryKey);
// //       await _prefs?.remove(_kPurchaseTokenKey);
// //       await _prefs?.remove('productId');
// //       await _prefs?.remove('purchaseDate');
// //
// //       // Remove from purchased list
// //       final current = _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //       current.remove(productId);
// //       if (GetPlatform.isAndroid) {
// //         final upperVariant = productId.replaceAll('sub', 'Sub');
// //         current.remove(upperVariant);
// //       }
// //       await _prefs?.setStringList(_kPrefPurchasedKey, current);
// //
// //       // Mark as cancelled
// //       await _prefs?.setBool('is_cancelled', true);
// //       await _prefs?.setString(_kCancelDate, DateTime.now().toIso8601String());
// //
// //       // Update premium status to false
// //       await _setPremiumStatus(false);
// //
// //       print('✅ Subscription marked as CANCELLED');
// //       print('📋 Purchased list after: $current');
// //     } catch (e) {
// //       print('❌ Error marking as cancelled: $e');
// //     }
// //   }
// //
// //   // Verify + complete purchase
// //   Future<void> _verifyAndCompletePurchase(
// //     PurchaseDetails purchaseDetails,
// //   ) async {
// //     try {
// //       print('🔐 VERIFYING PURCHASE');
// //
// //       bool isValid = await _verifyPurchase(purchaseDetails);
// //       print('Verification result: $isValid');
// //
// //       if (isValid) {
// //         await _storePurchaseLocally(purchaseDetails);
// //
// //         if (purchaseDetails.pendingCompletePurchase) {
// //           print('✅ Completing purchase...');
// //           await _inAppPurchase.completePurchase(purchaseDetails);
// //         }
// //
// //         print('✅ Purchase stored successfully');
// //       } else {
// //         print('❌ Verification failed');
// //         onPurchaseError?.call('Purchase verification failed');
// //       }
// //     } catch (e) {
// //       print("❌ Error completing purchase: $e");
// //       onPurchaseError?.call("Error completing purchase: $e");
// //     }
// //   }
// //
// //   Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
// //     try {
// //       // For testing, return true
// //       if (kDebugMode) {
// //         print('🧪 DEBUG MODE: Skipping verification');
// //         return true;
// //       }
// //
// //       final serverData =
// //           purchaseDetails.verificationData.serverVerificationData;
// //       return serverData.isNotEmpty;
// //     } catch (e) {
// //       print('❌ Verification error: $e');
// //       return false;
// //     }
// //   }
// //
// //   // Store purchase locally
// //   Future<void> _storePurchaseLocally(PurchaseDetails purchaseDetails) async {
// //     try {
// //       final productId = purchaseDetails.productID.toLowerCase();
// //       print('💾 STORING PURCHASE: $productId');
// //
// //       // Clear any previous cancellation marks
// //       await _prefs?.remove('is_cancelled');
// //       await _prefs?.remove(_kCancelDate);
// //
// //       final List<String> current =
// //           _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //
// //       if (!current.contains(productId)) {
// //         current.add(productId);
// //
// //         if (GetPlatform.isAndroid) {
// //           final upperVariant = productId.replaceAll('sub', 'Sub');
// //           if (!current.contains(upperVariant)) {
// //             current.add(upperVariant);
// //           }
// //         }
// //
// //         await _prefs?.setStringList(_kPrefPurchasedKey, current);
// //       }
// //
// //       // Set premium status to TRUE
// //       await _setPremiumStatus(true);
// //
// //       // Set expiry date
// //       await _setSubscriptionExpiryDate(productId);
// //
// //       // Store additional info
// //       await _prefs?.setString('productId', productId);
// //       await _prefs?.setString('purchaseDate', DateTime.now().toIso8601String());
// //
// //       print('✅ Purchase stored: $productId');
// //       print('📅 Expiry set for product');
// //     } catch (e) {
// //       print("❌ Error saving purchase: $e");
// //     }
// //   }
// //
// //   // Set subscription expiry date
// //   Future<void> _setSubscriptionExpiryDate(String productId) async {
// //     final now = DateTime.now();
// //     DateTime expiryDate;
// //
// //     if (productId.contains('weekly') || productId.contains('weeklySub')) {
// //       expiryDate = now.add(Duration(days: 7));
// //       print('📅 Weekly expiry: 7 days');
// //     } else if (productId.contains('yearly') ||
// //         productId.contains('yearlySub')) {
// //       expiryDate = now.add(Duration(days: 365));
// //       print('📅 Yearly expiry: 365 days');
// //     } else {
// //       expiryDate = now.add(Duration(days: 30));
// //       print('📅 Default expiry: 30 days');
// //     }
// //
// //     await _prefs?.setString(_kPremiumExpiryKey, expiryDate.toIso8601String());
// //     print('📅 Expiry Date: $expiryDate');
// //   }
// //
// //   // Set premium status and notify listeners
// //   Future<void> _setPremiumStatus(bool isPremium) async {
// //     final previousStatus = _prefs?.getBool(_kIsPremiumKey) ?? false;
// //
// //     print('🎯 SETTING PREMIUM STATUS');
// //     print('📊 Previous: $previousStatus, New: $isPremium');
// //
// //     await _prefs?.setBool(_kIsPremiumKey, isPremium);
// //
// //     // Update TrialManager
// //     try {
// //       await TrialManager.setPremium(isPremium);
// //     } catch (e) {
// //       print('❌ Error updating TrialManager: $e');
// //     }
// //
// //     // Notify listeners if status changed
// //     if (previousStatus != isPremium) {
// //       _premiumStatusController.add(isPremium);
// //       onPremiumStatusChanged?.call(isPremium);
// //       print('📢 Listeners notified of status change');
// //     }
// //
// //     print('✅ Premium status updated to: $isPremium');
// //   }
// //
// //   // Check if purchased
// //   bool isPurchased(String productId) {
// //     final current = _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
// //     final lowerId = productId.toLowerCase();
// //     final upperId = productId.replaceAll('sub', 'Sub');
// //
// //     return current.contains(productId) ||
// //         current.contains(lowerId) ||
// //         current.contains(upperId);
// //   }
// //
// //   // MAIN METHOD: Check subscription access
// //   Future<bool> hasPremiumAccess() async {
// //     try {
// //       print('🔑 CHECKING PREMIUM ACCESS');
// //
// //       // First check if cancelled
// //       final isCancelled = _prefs?.getBool('is_cancelled') ?? false;
// //       if (isCancelled) {
// //         print('❌ SUBSCRIPTION CANCELLED - No access');
// //         await _setPremiumStatus(false);
// //         return false;
// //       }
// //
// //       // Check expiry
// //       await _checkSubscriptionValidity();
// //
// //       // Get current premium status
// //       final isPremium = _prefs?.getBool(_kIsPremiumKey) ?? false;
// //       print('📊 Current premium status: $isPremium');
// //
// //       return isPremium;
// //     } catch (e) {
// //       print('❌ Error checking premium access: $e');
// //       return false;
// //     }
// //   }
// //
// //   // Get current premium status
// //   bool get isPremiumUser {
// //     return _prefs?.getBool(_kIsPremiumKey) ?? false;
// //   }
// //
// //   // Force check subscription status
// //   Future<void> forceCheckSubscriptionStatus() async {
// //     print('🔄 FORCE CHECKING SUBSCRIPTION STATUS');
// //     await _checkSubscriptionValidity();
// //   }
// //
// //   // NEW: Check if subscription is active without any restore
// //   Future<bool> checkSubscriptionStatusOnly() async {
// //     try {
// //       print('🔍 CHECKING SUBSCRIPTION STATUS (NO RESTORE)');
// //
// //       final isCancelled = _prefs?.getBool('is_cancelled') ?? false;
// //       if (isCancelled) {
// //         print('❌ Subscription was cancelled');
// //         return false;
// //       }
// //
// //       final expiryDateStr = _prefs?.getString(_kPremiumExpiryKey);
// //       if (expiryDateStr != null) {
// //         final expiryDate = DateTime.parse(expiryDateStr);
// //         final now = DateTime.now();
// //
// //         if (now.isAfter(expiryDate)) {
// //           print('❌ Subscription expired on $expiryDate');
// //           return false;
// //         } else {
// //           print('✅ Subscription active until $expiryDate');
// //           return true;
// //         }
// //       }
// //
// //       print('📭 No active subscription found');
// //       return false;
// //     } catch (e) {
// //       print('❌ Error checking subscription status: $e');
// //       return false;
// //     }
// //   }
// //
// //   // Force cancel subscription (for testing)
// //   Future<void> forceCancelSubscription() async {
// //     print('🛑 FORCE CANCELLING SUBSCRIPTION');
// //     await _prefs?.setBool('is_cancelled', true);
// //     await _prefs?.setString(_kCancelDate, DateTime.now().toIso8601String());
// //     await _setPremiumStatus(false);
// //     print('✅ Force cancelled');
// //   }
// //
// //   // Clear cache (for testing)
// //   Future<void> clearPurchaseCache() async {
// //     print('🗑️ CLEARING ALL CACHE');
// //
// //     await _prefs?.remove(_kPrefPurchasedKey);
// //     await _prefs?.remove(_kIsPremiumKey);
// //     await _prefs?.remove(_kPremiumExpiryKey);
// //     await _prefs?.remove(_kPurchaseTokenKey);
// //     await _prefs?.remove('productId');
// //     await _prefs?.remove('purchaseDate');
// //     await _prefs?.remove('is_cancelled');
// //     await _prefs?.remove(_kCancelDate);
// //     await _prefs?.remove(_kAppStartTime);
// //
// //     print('✅ Cache cleared');
// //     _premiumStatusController.add(false);
// //   }
// //
// //   // Dispose
// //   void dispose() {
// //     print('👋 Disposing IAP service');
// //     _purchaseSubscription.cancel();
// //     _restoreBlockTimer?.cancel();
// //     _premiumStatusController.close();
// //     _initialized = false;
// //   }
// //
// //   // Getters
// //   List<ProductDetails> get products => _products;
// //   bool get isAvailable => _isAvailable;
// //   bool get isLoading => _initialized && _products.isEmpty;
// // }
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
// import 'package:get/get.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:in_app_purchase_android/in_app_purchase_android.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../utils/trial_manager.dart';
//
// enum StoreState { loading, available, notAvailable }
//
// class PurchasableProduct {
//   final ProductDetails productDetails;
//   final String id;
//   bool isPurchased;
//
//   PurchasableProduct(this.productDetails)
//     : id = productDetails.id,
//       isPurchased = false;
// }
//
// class InAppPurchaseService {
//   static final InAppPurchaseService _instance =
//       InAppPurchaseService._internal();
//   factory InAppPurchaseService() => _instance;
//   InAppPurchaseService._internal();
//
//   final InAppPurchase _inAppPurchase = InAppPurchase.instance;
//   final _iapHelperConnection = FlutterInappPurchase.instance;
//   late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
//
//   List<ProductDetails> _products = [];
//   final products = <PurchasableProduct>[].obs;
//   bool _isAvailable = false;
//   bool _initialized = false;
//
//   // Observable state variables from controller
//   var storeState = StoreState.loading.obs;
//   var isPaidVersion = false.obs;
//   var isLoading = false.obs;
//   var weeklyPrice = ''.obs;
//   var yearlyPrice = ''.obs;
//   var purchasePending = false.obs;
//   var selectedPlan = 'Annual'.obs;
//
//   // Variables to block automatic restore
//   bool _ignoreInitialRestoreEvents = true;
//   Timer? _restoreBlockTimer;
//   bool _userInitiatedRestore = false;
//   bool _historyValidationCompleted = false;
//
//   // ✅ YOUR PRODUCT IDs HERE - REPLACE THESE WITH YOUR ACTUAL PRODUCT IDs
//   static const _iosWeekly = 'as.emojimaker.weeklySub';
//   static const _iosYearly = 'as.emojimaker.yearlySub';
//   static const _androidWeekly = 'weekly_id';
//   static const _androidYearly = 'yearly_id';
//
//   // ✅ YOUR APPLE SHARED SECRET HERE
//   static const _appleSharedSecret = "YOUR_APPLE_SHARED_SECRET_HERE";
//
//   List<String> get _productIds => Platform.isIOS
//       ? [_iosWeekly, _iosYearly]
//       : [_androidWeekly, _androidYearly];
//
//   // Subscription keys mapping from controller
//   final subscriptionKeys = <int, String>{
//     0: Platform.isIOS ? _iosWeekly : _androidWeekly,
//     1: Platform.isIOS ? _iosYearly : _androidYearly,
//   };
//
//   // Static product ID getters
//   static String get staticWeeklyProductId {
//     return GetPlatform.isIOS ? _iosWeekly : _androidWeekly;
//   }
//
//   static String get staticYearlyProductId {
//     return GetPlatform.isIOS ? _iosYearly : _androidYearly;
//   }
//
//   // Instance property getters
//   String get weeklyProductId => staticWeeklyProductId;
//   String get yearlyProductId => staticYearlyProductId;
//
//   // Add these constants at the top with other constants
//   static const String _kLastPurchaseAttempt = 'last_purchase_attempt';
//   static const String _kPurchaseAttemptCount = 'purchase_attempt_count';
//   static const String _kForceShowBottomsheet = 'force_show_bottomsheet';
//
//   // Storage keys
//   static const String _kPrefPurchasedKey = 'iap_purchased_ids';
//   static const String _kIsPremiumKey = 'isPremium';
//   static const String _kPremiumExpiryKey = 'premium_expiry_date';
//   static const String _kPurchaseTokenKey = 'purchase_token';
//   static const String _kCancelDate = 'cancel_date';
//   static const String _kAppStartTime = 'app_start_time';
//
//   // Sandbox testing keys
//   static const String _kSandboxCancelledPrefix = 'sandbox_cancelled_';
//   static const String _kManualCancelTest = 'manual_cancel_test';
//
//   // Stream controller for premium status updates
//   final StreamController<bool> _premiumStatusController =
//       StreamController<bool>.broadcast();
//   Stream<bool> get premiumStatusStream => _premiumStatusController.stream;
//
//   // Callbacks
//   Function(List<ProductDetails>)? onProductsLoaded;
//   Function(PurchaseDetails)? onPurchaseSuccess;
//   Function(String)? onPurchaseError;
//   Function()? onPurchasePending;
//   Function()? onPurchasesRestored;
//   Function(bool isPremium)? onPremiumStatusChanged;
//
//   SharedPreferences? _prefs;
//
//   // Check if we're in sandbox/testing mode
//   bool get _isSandboxEnvironment {
//     return true; // Force sandbox mode for testing
//   }
//
//   // Check actual sandbox mode (platform detection)
//   bool get _isActualSandbox {
//     return kDebugMode || kProfileMode;
//   }
//
//   // Initialize the service
//   Future<bool> initialize() async {
//     if (_initialized) return _isAvailable;
//
//     try {
//       _prefs = await SharedPreferences.getInstance();
//       _isAvailable = await _inAppPurchase.isAvailable();
//       isAvailable.value = _isAvailable;
//
//       print('🎯 IAP INITIALIZE - Available: $_isAvailable');
//       print('🧪 FORCING Sandbox Environment: $_isSandboxEnvironment');
//       print('📱 Actual Debug Mode: $_isActualSandbox');
//
//       if (!_isAvailable) {
//         print('❌ IAP not available');
//         storeState.value = StoreState.notAvailable;
//         return false;
//       }
//
//       await _prefs?.setString(_kAppStartTime, DateTime.now().toIso8601String());
//       print('📱 App start time recorded');
//
//       // Subscribe to purchases (like controller)
//       _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
//         _handlePurchaseUpdates,
//         onDone: () => print('Purchase stream closed'),
//         onError: (error) => print('Purchase stream error: $error'),
//       );
//
//       _initialized = true;
//
//       // Initialize helper (like controller)
//       await _iapHelperInitialize();
//
//       // Load products (like controller)
//       await _loadProductsFromController();
//
//       // Check history (like controller)
//       await _iapHelperGetSubscriptionHistory();
//
//       // Don't auto-check on initialize to prevent loops
//       _startRestoreBlockTimer();
//
//       return true;
//     } catch (e) {
//       print('❌ Error initializing IAP: $e');
//       storeState.value = StoreState.notAvailable;
//       return false;
//     }
//   }
//
//   // -----------------------------
//   // IAP Helper Functions from Controller
//   // -----------------------------
//
//   Future<void> _iapHelperInitialize() async {
//     print('[IAP][HELPER] initialize()');
//     try {
//       await _iapHelperConnection.initialize();
//       print('[IAP][HELPER] ✅ Initialized');
//     } catch (e) {
//       print('[IAP][HELPER] ❌ Initialize error: $e');
//     }
//   }
//
//   // Load products function from controller
//   Future<void> _loadProductsFromController() async {
//     print('════════════════════════════════════');
//     print('[IAP] _loadProductsFromController()');
//
//     storeState.value = StoreState.loading;
//     isLoading.value = true;
//
//     final response = await _inAppPurchase.queryProductDetails(
//       subscriptionKeys.values.toSet(),
//     );
//
//     if (response.error != null) {
//       print('[IAP] ❌ Product query error: ${response.error}');
//     }
//
//     final loaded = response.productDetails
//         .map((e) => PurchasableProduct(e))
//         .toList();
//     products.assignAll(loaded);
//
//     print('[IAP] Products loaded: ${products.map((e) => e.id).toList()}');
//
//     // Get prices for UI display
//     weeklyPrice.value =
//         products
//             .firstWhereOrNull((p) => p.id.contains('weekly'))
//             ?.productDetails
//             .price ??
//         '';
//     yearlyPrice.value =
//         products
//             .firstWhereOrNull((p) => p.id.contains('yearly'))
//             ?.productDetails
//             .price ??
//         '';
//
//     print('[IAP] Weekly price: ${weeklyPrice.value}');
//     print('[IAP] Yearly price: ${yearlyPrice.value}');
//
//     storeState.value = StoreState.available;
//     isLoading.value = false;
//   }
//
//   // Buy function from controller
//   Future<void> buySubID(int id) async {
//     print('════════════════════════════════════');
//     print('[IAP] buySubID($id)');
//
//     if (!subscriptionKeys.containsKey(id)) {
//       print('[IAP] ❌ Unknown subscription id index: $id');
//       return;
//     }
//
//     final productId = subscriptionKeys[id]!;
//     final product = products.firstWhereOrNull((p) => p.id == productId);
//
//     if (product == null) {
//       print('[IAP] ❌ Product not loaded yet for: $productId');
//       return;
//     }
//
//     await buy(product);
//   }
//
//   Future<void> buy(PurchasableProduct product) async {
//     print('════════════════════════════════════');
//     print('[IAP] buy() -> ${product.id}');
//
//     if (purchasePending.value) {
//       print('[IAP] ⏳ Purchase already pending, skipping');
//       return;
//     }
//
//     purchasePending.value = true;
//
//     try {
//       final purchaseParam = Platform.isAndroid
//           ? GooglePlayPurchaseParam(productDetails: product.productDetails)
//           : PurchaseParam(productDetails: product.productDetails);
//
//       if (subscriptionKeys.values.contains(product.id)) {
//         print('[IAP] Calling buyNonConsumable...');
//         await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
//       } else {
//         throw ArgumentError.value(
//           product.productDetails,
//           '${product.id} is not a known product',
//         );
//       }
//     } catch (e) {
//       print('[IAP] ❌ Buy error: $e');
//       purchasePending.value = false;
//     }
//   }
//
//   // -----------------------------
//   // History check (like controller)
//   // -----------------------------
//   Future<void> _iapHelperGetSubscriptionHistory() async {
//     if (_historyValidationCompleted) {
//       print('[IAP][HELPER] History validation already completed, skipping');
//       return;
//     }
//
//     print('════════════════════════════════════');
//     print('[IAP][HELPER] _iapHelperGetSubscriptionHistory()');
//
//     final available = await _inAppPurchase.isAvailable();
//     print('[IAP][HELPER] Store available: $available');
//
//     if (!available) {
//       storeState.value = StoreState.notAvailable;
//       print('[IAP][HELPER] ❌ Store not available -> NOT premium');
//       await _setNotPremium(reason: 'store_not_available');
//       return;
//     }
//
//     List<PurchasedItem>? purchaseHistory;
//     try {
//       purchaseHistory = await _iapHelperConnection.getAvailablePurchases();
//     } catch (e) {
//       print('[IAP][HELPER] ❌ Error fetching purchase history: $e');
//       purchaseHistory = null;
//     }
//
//     print('[IAP][HELPER] Purchase history: ${purchaseHistory?.length ?? 0}');
//
//     // ✅ REQUIRED: if no history -> user not premium
//     if (purchaseHistory == null || purchaseHistory.isEmpty) {
//       print('[IAP][HELPER] ❌ No receipts / no transactions -> NOT premium');
//       await _setNotPremium(reason: 'no_history');
//       return;
//     }
//
//     for (final p in purchaseHistory) {
//       print(
//         '[IAP][HELPER] item => productId=${p.productId}, date=${p.transactionDate}',
//       );
//     }
//
//     final mostRecent = getMostRecentPurchase(purchaseHistory);
//     if (mostRecent == null) {
//       print('[IAP][HELPER] ❌ Most recent is null -> NOT premium');
//       await _setNotPremium(reason: 'most_recent_null');
//       return;
//     }
//
//     print(
//       '[IAP][HELPER] Most recent => productId=${mostRecent.productId}, date=${mostRecent.transactionDate}',
//     );
//
//     // if mostRecent not one of our ids -> not premium
//     if (mostRecent.productId == null ||
//         !subscriptionKeys.containsValue(mostRecent.productId)) {
//       print(
//         '[IAP][HELPER] ❌ Most recent product not in our subscription keys -> NOT premium',
//       );
//       await _setNotPremium(reason: 'not_our_product');
//       return;
//     }
//
//     // iOS -> validate receipt
//     if (Platform.isIOS) {
//       final receipt = mostRecent.transactionReceipt ?? '';
//       if (receipt.isEmpty) {
//         print('[IAP][HELPER][IOS] ❌ Empty receipt -> NOT premium');
//         await _setNotPremium(reason: 'empty_receipt');
//         return;
//       }
//
//       print('[IAP][HELPER][IOS] Validating Apple receipt...');
//       final validationResult = await validateAppleReceipt(
//         receipt,
//         _appleSharedSecret,
//         true,
//       );
//
//       print('[IAP][HELPER][IOS] Apple validation response: $validationResult');
//
//       final status = validationResult["status"];
//       if (status != 0) {
//         print(
//           '[IAP][HELPER][IOS] ❌ Apple receipt invalid. status=$status -> NOT premium',
//         );
//         await _setNotPremium(reason: 'apple_status_$status');
//         return;
//       }
//
//       // expiry
//       final expiry = _extractAppleExpiry(validationResult);
//       if (expiry == null) {
//         print('[IAP][HELPER][IOS] ❌ Could not extract expiry -> NOT premium');
//         await _setNotPremium(reason: 'no_expiry');
//         return;
//       }
//
//       final nowUtc = DateTime.now().toUtc();
//       print('[IAP][HELPER][IOS] expiryUtc=$expiry nowUtc=$nowUtc');
//
//       final isExpired = nowUtc.isAfter(expiry);
//       if (isExpired) {
//         print('[IAP][HELPER][IOS] ❌ Expired -> NOT premium');
//         await _setNotPremium(reason: 'expired');
//         return;
//       }
//
//       print('[IAP][HELPER][IOS] ✅ Valid subscription -> PREMIUM');
//       await _setPremium(expiry: expiry, reason: 'history_ios_valid');
//       return;
//     }
//
//     // Android -> if history contains our product, mark premium (client-side)
//     if (Platform.isAndroid) {
//       print(
//         '[IAP][HELPER][ANDROID] ✅ Found purchase history for our product -> PREMIUM (client-side)',
//       );
//       await _setPremium(expiry: null, reason: 'history_android_found');
//       return;
//     }
//
//     // fallback
//     await _setNotPremium(reason: 'unknown_platform');
//     _historyValidationCompleted = true;
//   }
//
//   // -----------------------------
//   // Receipt validation functions from controller
//   // -----------------------------
//   Future<Map<String, dynamic>> validateAppleReceipt(
//     String receipt,
//     String sharedSecret,
//     bool isSandbox,
//   ) async {
//     final url = isSandbox
//         ? "https://sandbox.itunes.apple.com/verifyReceipt"
//         : "https://buy.itunes.apple.com/verifyReceipt";
//
//     print('[IAP][APPLE] validateAppleReceipt()');
//     print('[IAP][APPLE] endpoint=$url');
//     print('[IAP][APPLE] receiptLen=${receipt.length}');
//     print('[IAP][APPLE] secretLen=${sharedSecret.length}');
//
//     final response = await _httpJsonPostRequest(Uri.parse(url), {
//       "receipt-data": receipt,
//       "password": sharedSecret,
//       "exclude-old-transactions": true,
//     });
//
//     return response;
//   }
//
//   Future<Map<String, dynamic>> _httpJsonPostRequest(
//     Uri url,
//     Map<String, dynamic> body,
//   ) async {
//     print('[IAP][HTTP] POST $url');
//     print('[IAP][HTTP] Body keys: ${body.keys.toList()}');
//
//     final client = HttpClient();
//
//     try {
//       final request = await client.postUrl(url);
//       request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
//       request.write(jsonEncode(body));
//
//       final response = await request.close();
//       final responseBody = await response.transform(utf8.decoder).join();
//
//       print('[IAP][HTTP] Status=${response.statusCode}');
//       print('[IAP][HTTP] Body=$responseBody');
//
//       final result = jsonDecode(responseBody) as Map<String, dynamic>;
//       result["statusCode"] = response.statusCode;
//       return result;
//     } catch (e) {
//       print('[IAP][HTTP] ❌ Error: $e');
//       rethrow;
//     } finally {
//       client.close();
//     }
//   }
//
//   PurchasedItem? getMostRecentPurchase(List<PurchasedItem> purchases) {
//     if (purchases.isEmpty) return null;
//     if (purchases.length == 1) return purchases[0];
//
//     return purchases.reduce((a, b) {
//       final aDate = a.transactionDate;
//       final bDate = b.transactionDate;
//
//       if (aDate == null && bDate == null) return a;
//       if (aDate == null) return b;
//       if (bDate == null) return a;
//
//       return aDate.isAfter(bDate) ? a : b;
//     });
//   }
//
//   // -----------------------------
//   // Extra helpers from controller (internal)
//   // -----------------------------
//   Future<bool> _validateAndSetPremiumFromPurchase(PurchaseDetails p) async {
//     print('[IAP] _validateAndSetPremiumFromPurchase()');
//
//     if (!_productIds.contains(p.productID)) {
//       print('[IAP] ❌ productID not in our list -> NOT premium');
//       await _setNotPremium(reason: 'not_our_product_stream');
//       return false;
//     }
//
//     final verificationData = p.verificationData.serverVerificationData;
//     if (verificationData.isEmpty) {
//       print('[IAP] ❌ Empty verification data -> NOT premium');
//       await _setNotPremium(reason: 'empty_verification_stream');
//       return false;
//     }
//
//     if (Platform.isIOS) {
//       final res = await validateAppleReceipt(
//         verificationData,
//         _appleSharedSecret,
//         true,
//       );
//       final status = res["status"];
//       if (status != 0) {
//         print('[IAP][IOS] ❌ Apple status=$status -> NOT premium');
//         await _setNotPremium(reason: 'apple_status_stream_$status');
//         return false;
//       }
//
//       final expiry = _extractAppleExpiry(res);
//       if (expiry == null) {
//         print('[IAP][IOS] ❌ No expiry -> NOT premium');
//         await _setNotPremium(reason: 'no_expiry_stream');
//         return false;
//       }
//
//       if (DateTime.now().toUtc().isAfter(expiry)) {
//         print('[IAP][IOS] ❌ Expired -> NOT premium');
//         await _setNotPremium(reason: 'expired_stream');
//         return false;
//       }
//
//       await _setPremium(expiry: expiry, reason: 'stream_ios_valid');
//       return true;
//     }
//
//     if (Platform.isAndroid) {
//       try {
//         final json = jsonDecode(verificationData);
//         print('[IAP][ANDROID] verification json: $json');
//
//         if (!json.containsKey("purchaseToken")) {
//           print('[IAP][ANDROID] ❌ Missing purchaseToken -> NOT premium');
//           await _setNotPremium(reason: 'missing_token_stream');
//           return false;
//         }
//
//         await _setPremium(expiry: null, reason: 'stream_android_token_present');
//         return true;
//       } catch (e) {
//         print('[IAP][ANDROID] ❌ Parse error: $e -> NOT premium');
//         await _setNotPremium(reason: 'android_parse_error');
//         return false;
//       }
//     }
//
//     await _setNotPremium(reason: 'unknown_platform_stream');
//     return false;
//   }
//
//   DateTime? _extractAppleExpiry(Map<String, dynamic> receiptData) {
//     print('[IAP][APPLE] Extracting latest expiry...');
//
//     final list = receiptData["latest_receipt_info"];
//     if (list is! List || list.isEmpty) {
//       print('[IAP][APPLE] ❌ No latest_receipt_info');
//       return null;
//     }
//
//     int bestMs = -1;
//     Map<String, dynamic>? bestItem;
//
//     for (final item in list) {
//       if (item is! Map) continue;
//
//       final pid = item["product_id"]?.toString();
//       if (pid == null || !_productIds.contains(pid)) continue;
//
//       final msStr = item["expires_date_ms"]?.toString();
//       final ms = int.tryParse(msStr ?? "");
//       if (ms == null) continue;
//
//       if (ms > bestMs) {
//         bestMs = ms;
//         bestItem = Map<String, dynamic>.from(item);
//       }
//     }
//
//     if (bestItem == null) {
//       print('[IAP][APPLE] ❌ No valid expiry item found');
//       return null;
//     }
//
//     final expiryUtc = DateTime.fromMillisecondsSinceEpoch(bestMs, isUtc: true);
//
//     print('[IAP][APPLE] Latest expiry UTC: $expiryUtc');
//     print('[IAP][APPLE] Now UTC: ${DateTime.now().toUtc()}');
//
//     return expiryUtc;
//   }
//
//   // Start timer to block automatic restore events on app start
//   void _startRestoreBlockTimer() {
//     print('⏱️ Starting restore block timer (10 seconds)');
//     _ignoreInitialRestoreEvents = true;
//
//     _restoreBlockTimer?.cancel();
//
//     _restoreBlockTimer = Timer(Duration(seconds: 10), () {
//       print('✅ Restore block timer expired - now accepting restore events');
//       _ignoreInitialRestoreEvents = false;
//       _restoreBlockTimer = null;
//     });
//   }
//
//   // ------------------------------------------------------------------
//   // ORIGINAL SERVICE METHODS (keep all existing service functionality)
//   // ------------------------------------------------------------------
//
//   Future<void> _trackPurchaseAttempt(String productId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final now = DateTime.now().toIso8601String();
//     final attemptCount = prefs.getInt(_kPurchaseAttemptCount) ?? 0;
//
//     await prefs.setString(_kLastPurchaseAttempt, now);
//     await prefs.setInt(_kPurchaseAttemptCount, attemptCount + 1);
//     await prefs.setString('last_purchase_product_id', productId);
//
//     print('📝 Purchase attempt tracked:');
//     print('   • Product: $productId');
//     print('   • Attempt #: ${attemptCount + 1}');
//     print('   • Time: $now');
//   }
//
//   Future<int> _getPurchaseAttemptCount(String productId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final lastProductId = prefs.getString('last_purchase_product_id');
//
//     if (lastProductId == productId) {
//       return prefs.getInt(_kPurchaseAttemptCount) ?? 0;
//     }
//
//     await prefs.setInt(_kPurchaseAttemptCount, 0);
//     return 0;
//   }
//
//   // CRITICAL: Reset sandbox before every purchase
//   Future<void> _resetSandboxBeforePurchase(String productId) async {
//     if (!_isSandboxEnvironment) {
//       print('📱 Not in sandbox, skipping reset');
//       return;
//     }
//
//     print('🧹 SANDBOX RESET BEFORE PURCHASE: $productId');
//     print('🔄 Clearing all purchase and cancellation data...');
//
//     final prefs = await SharedPreferences.getInstance();
//
//     print('📊 BEFORE RESET STATE:');
//     print('   • is_cancelled: ${prefs.getBool('is_cancelled')}');
//     print('   • was_ever_cancelled: ${prefs.getBool('was_ever_cancelled')}');
//     print('   • isPremium: ${prefs.getBool(_kIsPremiumKey)}');
//     print('   • Purchased list: ${prefs.getStringList(_kPrefPurchasedKey)}');
//
//     await prefs.remove(_kPrefPurchasedKey);
//     await prefs.remove(_kIsPremiumKey);
//     await prefs.remove(_kPremiumExpiryKey);
//     await prefs.remove(_kPurchaseTokenKey);
//     await prefs.remove('productId');
//     await prefs.remove('purchaseDate');
//
//     await prefs.remove('is_cancelled');
//     await prefs.remove('was_ever_cancelled');
//     await prefs.remove(_kCancelDate);
//     await prefs.remove('cancelled_product_id');
//     await prefs.remove('cancelled_product_name');
//
//     await prefs.remove(_kManualCancelTest);
//     await prefs.remove('${_kSandboxCancelledPrefix}$productId');
//     await prefs.remove('${_kSandboxCancelledPrefix}weekly');
//     await prefs.remove('${_kSandboxCancelledPrefix}yearly');
//     await prefs.remove('${_kSandboxCancelledPrefix}weekly_id');
//     await prefs.remove('${_kSandboxCancelledPrefix}yearly_id');
//     await prefs.remove('${_kSandboxCancelledPrefix}as.emojimaker.weeklySub');
//     await prefs.remove('${_kSandboxCancelledPrefix}as.emojimaker.yearlySub');
//
//     await prefs.remove('fresh_purchase_after_cancel');
//     await prefs.remove('fresh_purchase_date');
//
//     final keysToRemove = <String>[];
//     final keys = prefs.getKeys();
//     for (var key in keys) {
//       if (key.contains('cancelled') ||
//           key.contains('Cancelled') ||
//           key.contains('cancel') ||
//           key.contains('sandbox') ||
//           key.contains('Sandbox') ||
//           key.contains('weekly') ||
//           key.contains('yearly') ||
//           key.contains('purchase') ||
//           key.contains('Purchase') ||
//           key.contains('premium') ||
//           key.contains('Premium') ||
//           key.contains('expiry') ||
//           key.contains('Expiry')) {
//         keysToRemove.add(key);
//       }
//     }
//
//     for (var key in keysToRemove) {
//       await prefs.remove(key);
//     }
//
//     await prefs.setStringList(_kPrefPurchasedKey, []);
//     await prefs.setBool(_kIsPremiumKey, false);
//     await prefs.setBool('is_cancelled', false);
//     await prefs.setBool('was_ever_cancelled', false);
//
//     await prefs.setString(
//       _kLastPurchaseAttempt,
//       DateTime.now().toIso8601String(),
//     );
//     await prefs.setString('current_purchase_product', productId);
//
//     await TrialManager.setPremium(false);
//
//     if (!_premiumStatusController.isClosed) {
//       _premiumStatusController.add(false);
//     }
//     onPremiumStatusChanged?.call(false);
//
//     print('✅ SANDBOX COMPLETELY RESET');
//     print('📊 AFTER RESET STATE:');
//     print('   • is_cancelled: ${prefs.getBool('is_cancelled')}');
//     print('   • was_ever_cancelled: ${prefs.getBool('was_ever_cancelled')}');
//     print('   • isPremium: ${prefs.getBool(_kIsPremiumKey)}');
//     print('   • Purchased list: ${prefs.getStringList(_kPrefPurchasedKey)}');
//     print('🚀 Ready for fresh purchase!');
//   }
//
//   // Main method to check if subscription is valid
//   Future<void> _checkSubscriptionValidity() async {
//     print('🔍 CHECKING SUBSCRIPTION VALIDITY');
//     print('🧪 Sandbox Mode: $_isSandboxEnvironment');
//
//     final isCancelled = _prefs?.getBool('is_cancelled') ?? false;
//     final wasEverCancelled = _prefs?.getBool('was_ever_cancelled') ?? false;
//
//     if (isCancelled || wasEverCancelled) {
//       print('❌ SUBSCRIPTION WAS CANCELLED');
//       await _setPremiumStatus(false);
//       return;
//     }
//
//     final expiryDateStr = _prefs?.getString(_kPremiumExpiryKey);
//     if (expiryDateStr != null) {
//       try {
//         final expiryDate = DateTime.parse(expiryDateStr);
//         final now = DateTime.now();
//
//         print('📅 Expiry Date: $expiryDate');
//         print('📅 Current Date: $now');
//         print('📅 Is Expired: ${now.isAfter(expiryDate)}');
//
//         if (now.isAfter(expiryDate)) {
//           print('❌ SUBSCRIPTION EXPIRED');
//           await _setPremiumStatus(false);
//         } else {
//           print('✅ Subscription still valid');
//         }
//       } catch (e) {
//         print('❌ Error parsing expiry date: $e');
//         await _setPremiumStatus(false);
//       }
//     } else {
//       print('📭 No expiry date found - User is not premium');
//       await _setPremiumStatus(false);
//     }
//   }
//
//   // Method to notify all widgets about status change
//   Future<void> notifyPremiumStatusChanged(bool isPremium) async {
//     print('📢 Notifying premium status change: $isPremium');
//
//     await _prefs?.setBool('isPremium', isPremium);
//
//     try {
//       await TrialManager.setPremium(isPremium);
//     } catch (e) {
//       print('❌ Error updating TrialManager: $e');
//     }
//
//     if (_premiumStatusController.isClosed) {
//       print('⚠️ Stream controller is closed, recreating');
//       _premiumStatusController.add(isPremium);
//     } else {
//       _premiumStatusController.add(isPremium);
//     }
//
//     onPremiumStatusChanged?.call(isPremium);
//   }
//
//   // Purchase after cancellation
//   Future<void> purchaseAfterCancellation(String productId) async {
//     try {
//       print('🔄 PURCHASING AFTER CANCELLATION: $productId');
//
//       await _resetSandboxBeforePurchase(productId);
//
//       await _prefs?.remove('is_cancelled');
//       await _prefs?.remove('was_ever_cancelled');
//       await _prefs?.remove(_kCancelDate);
//       await _prefs?.remove('cancelled_product_id');
//       await _prefs?.remove('cancelled_product_name');
//
//       await _prefs?.remove(_kManualCancelTest);
//       await _prefs?.remove('${_kSandboxCancelledPrefix}$productId');
//       await _prefs?.remove('${_kSandboxCancelledPrefix}weekly');
//       await _prefs?.remove('${_kSandboxCancelledPrefix}yearly');
//
//       await _clearExistingPurchaseData();
//
//       await _prefs?.setBool('fresh_purchase_after_cancel', true);
//       await _prefs?.setString(
//         'fresh_purchase_date',
//         DateTime.now().toIso8601String(),
//       );
//
//       print('🧹 All cancellation flags cleared for fresh purchase');
//
//       await notifyPremiumStatusChanged(false);
//
//       print('📱 Cancellation cleared - Ready for new purchase');
//     } catch (e) {
//       print('❌ Error in purchase after cancellation: $e');
//       rethrow;
//     }
//   }
//
//   // Force cancel subscription locally
//   Future<void> forceCancelSandboxSubscription() async {
//     try {
//       print('🧪 SANDBOX: FORCE CANCELLING SUBSCRIPTION LOCALLY');
//
//       if (!_isActualSandbox) {
//         print('⚠️ This method is only for sandbox testing');
//         onPurchaseError?.call('This feature is only for sandbox testing');
//         return;
//       }
//
//       final prefs = await SharedPreferences.getInstance();
//
//       final productId = prefs.getString('productId');
//       final isPremium = prefs.getBool(_kIsPremiumKey) ?? false;
//       final expiryDate = prefs.getString(_kPremiumExpiryKey);
//
//       print('📊 Current State Before Cancellation:');
//       print('   • productId: $productId');
//       print('   • isPremium: $isPremium');
//       print('   • expiryDate: $expiryDate');
//
//       if (productId == null) {
//         print('⚠️ No active subscription found to cancel');
//         onPurchaseError?.call('No active subscription found');
//         return;
//       }
//
//       print('🧪 Cancelling subscription: $productId');
//
//       await prefs.setBool('is_cancelled', true);
//       await prefs.setBool('was_ever_cancelled', true);
//       await prefs.setString(_kCancelDate, DateTime.now().toIso8601String());
//       await prefs.setString('cancelled_product_id', productId);
//       await prefs.setString(
//         'cancelled_product_name',
//         productId.contains('weekly') ? 'weekly' : 'yearly',
//       );
//       await prefs.setBool(_kManualCancelTest, true);
//       await prefs.setBool('${_kSandboxCancelledPrefix}$productId', true);
//
//       await prefs.remove(_kIsPremiumKey);
//       await prefs.remove(_kPremiumExpiryKey);
//       await prefs.remove('purchaseDate');
//
//       final current = prefs.getStringList(_kPrefPurchasedKey) ?? <String>[];
//       current.remove(productId);
//       if (GetPlatform.isAndroid) {
//         final upperVariant = productId.replaceAll('sub', 'Sub');
//         current.remove(upperVariant);
//       }
//       await prefs.setStringList(_kPrefPurchasedKey, current);
//
//       await notifyPremiumStatusChanged(false);
//
//       print('🧪 SANDBOX: Subscription force cancelled locally');
//       print('📊 State After Cancellation:');
//       print('   • is_cancelled: ${prefs.getBool('is_cancelled')}');
//       print('   • was_ever_cancelled: ${prefs.getBool('was_ever_cancelled')}');
//       print('   • isPremium: ${prefs.getBool(_kIsPremiumKey)}');
//       print('✅ Pro button should now appear');
//
//       onPurchaseError?.call(
//         'Subscription cancelled for testing. Pro button should appear.',
//       );
//     } catch (e) {
//       print('❌ Error force cancelling: $e');
//       onPurchaseError?.call('Error cancelling: $e');
//     }
//   }
//
//   // Test method to simulate sandbox cancellation
//   Future<void> testSandboxCancellation() async {
//     try {
//       print('🧪 SANDBOX: TESTING CANCELLATION FLOW');
//
//       final prefs = await SharedPreferences.getInstance();
//
//       final productId = prefs.getString('productId');
//       final isPremium = prefs.getBool(_kIsPremiumKey) ?? false;
//       final isCancelled = prefs.getBool('is_cancelled') ?? false;
//       final wasEverCancelled = prefs.getBool('was_ever_cancelled') ?? false;
//
//       print('📊 CURRENT STATE:');
//       print('📱 Product ID: $productId');
//       print('💰 Is Premium: $isPremium');
//       print('❌ Is Cancelled: $isCancelled');
//       print('📅 Was Ever Cancelled: $wasEverCancelled');
//
//       await forceCancelSandboxSubscription();
//     } catch (e) {
//       print('❌ Error in test: $e');
//     }
//   }
//
//   // Improved method to check purchases
//   Future<void> checkExistingPurchases() async {
//     try {
//       print('🔍 CHECKING EXISTING PURCHASES');
//
//       final prefs = await SharedPreferences.getInstance();
//       final localPurchases = prefs.getStringList(_kPrefPurchasedKey) ?? [];
//       print('📱 Local purchases: $localPurchases');
//
//       final isPremium = prefs.getBool(_kIsPremiumKey) ?? false;
//       final expiryDateStr = prefs.getString(_kPremiumExpiryKey);
//
//       print('💰 Premium Status: $isPremium');
//       print('📅 Expiry Date: $expiryDateStr');
//
//       if (expiryDateStr != null) {
//         try {
//           final expiryDate = DateTime.parse(expiryDateStr);
//           final now = DateTime.now();
//           final isExpired = now.isAfter(expiryDate);
//
//           print('⏰ Expired: $isExpired');
//           print('⏰ Time remaining: ${expiryDate.difference(now)}');
//         } catch (e) {
//           print('❌ Error parsing expiry: $e');
//         }
//       }
//     } catch (e) {
//       print('❌ Error checking purchases: $e');
//     }
//   }
//
//   Future<void> debugSandboxStatus() async {
//     print('🔍 SANDBOX DEBUG INFORMATION');
//     print('================================');
//
//     final prefs = await SharedPreferences.getInstance();
//
//     print('📱 Platform: ${GetPlatform.isIOS ? 'iOS' : 'Android'}');
//     print('🧪 Sandbox Mode: $_isSandboxEnvironment');
//     print('🔧 Actual Debug Mode: $_isActualSandbox');
//
//     print('🛍️ Products loaded: ${_products.length}');
//     for (var product in _products) {
//       print('   • ${product.id} - ${product.title} - ${product.price}');
//     }
//
//     final productId = prefs.getString('productId');
//     final isPremium = prefs.getBool(_kIsPremiumKey) ?? false;
//     final isCancelled = prefs.getBool('is_cancelled') ?? false;
//     final wasEverCancelled = prefs.getBool('was_ever_cancelled') ?? false;
//     final expiryDate = prefs.getString(_kPremiumExpiryKey);
//     final cancellationDate = prefs.getString(_kCancelDate);
//
//     print('💰 Purchase Status:');
//     print('   • Product ID: $productId');
//     print('   • Is Premium: $isPremium');
//     print('   • Is Cancelled: $isCancelled');
//     print('   • Was Ever Cancelled: $wasEverCancelled');
//     print('   • Expiry Date: $expiryDate');
//     print('   • Cancellation Date: $cancellationDate');
//
//     final purchasedList = prefs.getStringList(_kPrefPurchasedKey) ?? [];
//     print('📋 Purchased List: $purchasedList');
//
//     print('================================');
//   }
//
//   // Restore purchases for sandbox
//   Future<void> restorePurchasesForSandbox() async {
//     try {
//       print('🧪 SANDBOX: Restoring purchases');
//
//       final prefs = await SharedPreferences.getInstance();
//
//       final purchasedList = prefs.getStringList(_kPrefPurchasedKey) ?? [];
//       final productId = prefs.getString('productId');
//       final expiryDateStr = prefs.getString(_kPremiumExpiryKey);
//
//       if (purchasedList.isNotEmpty &&
//           productId != null &&
//           expiryDateStr != null) {
//         print('✅ Sandbox purchases found locally');
//
//         try {
//           final expiryDate = DateTime.parse(expiryDateStr);
//           final now = DateTime.now();
//
//           if (now.isAfter(expiryDate)) {
//             print('⚠️ Subscription expired on $expiryDate');
//             onPurchaseError?.call('Subscription has expired');
//             await _setPremiumStatus(false);
//           } else {
//             print('✅ Subscription active until $expiryDate');
//             await _setPremiumStatus(true);
//             onPurchasesRestored?.call();
//           }
//         } catch (e) {
//           print('❌ Error checking expiry: $e');
//           onPurchaseError?.call('Error restoring purchases');
//         }
//       } else {
//         print('⚠️ No purchases found in sandbox');
//         onPurchaseError?.call('No previous purchases found');
//       }
//     } catch (e) {
//       print('❌ Error in sandbox restore: $e');
//       onPurchaseError?.call('Restore failed: ${e.toString()}');
//     }
//   }
//
//   // Call this after purchase
//   Future<void> checkPurchaseInSandbox() async {
//     if (!_isSandboxEnvironment) return;
//
//     print('🧪 CHECKING PURCHASE IN SANDBOX');
//     await debugSandboxStatus();
//   }
//
//   // Existing purchase data clear karne ka method
//   Future<void> _clearExistingPurchaseData() async {
//     print('🗑️ Clearing existing purchase data for fresh purchase');
//
//     final current = _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
//     current.clear();
//     await _prefs?.setStringList(_kPrefPurchasedKey, current);
//
//     await _prefs?.remove(_kIsPremiumKey);
//     await _prefs?.remove(_kPremiumExpiryKey);
//     await _prefs?.remove(_kPurchaseTokenKey);
//     await _prefs?.remove('productId');
//     await _prefs?.remove('purchaseDate');
//
//     print('✅ Existing purchase data cleared');
//   }
//
//   Future<void> restorePurchases() async {
//     try {
//       print('🔄 USER INITIATED RESTORE PURCHASES');
//       print('🧪 Sandbox Mode: $_isSandboxEnvironment');
//
//       final prefs = await SharedPreferences.getInstance();
//       final wasEverCancelled = prefs.getBool('was_ever_cancelled') ?? false;
//       final isCurrentlyCancelled = prefs.getBool('is_cancelled') ?? false;
//
//       print('📊 Cancellation Status:');
//       print('   • was_ever_cancelled: $wasEverCancelled');
//       print('   • is_cancelled: $isCurrentlyCancelled');
//
//       if (wasEverCancelled || isCurrentlyCancelled) {
//         print('❌ CANNOT RESTORE - Subscription was cancelled');
//         onPurchaseError?.call(
//           "Your subscription was cancelled. Please purchase a new subscription to continue.",
//         );
//         return;
//       }
//
//       _userInitiatedRestore = true;
//       _ignoreInitialRestoreEvents = false;
//
//       onPurchasePending?.call();
//
//       print('🔍 Calling restorePurchases()...');
//
//       final restoreFuture = _inAppPurchase.restorePurchases();
//
//       await restoreFuture.timeout(
//         Duration(seconds: 15),
//         onTimeout: () {
//           print('⚠️ Restore timeout after 15 seconds');
//           throw TimeoutException('Restore operation timed out');
//         },
//       );
//
//       print('⏳ Waiting for restore events...');
//       await Future.delayed(Duration(seconds: 2));
//
//       final hasPremium = await hasPremiumAccess();
//
//       if (hasPremium) {
//         print('✅ Purchases restored successfully');
//         onPurchasesRestored?.call();
//       } else {
//         print('❌ No previous purchases found');
//         onPurchaseError?.call("No previous purchases found");
//       }
//
//       _userInitiatedRestore = false;
//     } on TimeoutException catch (e) {
//       print('❌ Restore timed out: $e');
//       onPurchaseError?.call(
//         "Restore timed out. Please check your connection and try again.",
//       );
//       _userInitiatedRestore = false;
//     } catch (e) {
//       print("❌ Error restoring purchases: $e");
//       onPurchaseError?.call("Failed to restore purchases: ${e.toString()}");
//       _userInitiatedRestore = false;
//     }
//   }
//
//   // Load products
//   Future<void> loadProducts() async {
//     try {
//       print('🛍️ LOADING PRODUCTS...');
//
//       if (!_isAvailable) {
//         print('❌ IAP not available');
//         onPurchaseError?.call('In-app purchases are not available');
//         return;
//       }
//
//       print('📋 Product IDs to fetch: $_productIds');
//       final ProductDetailsResponse response = await _inAppPurchase
//           .queryProductDetails(_productIds.toSet());
//
//       print('📦 Response error: ${response.error}');
//       print('📦 Products not found: ${response.notFoundIDs}');
//       print('📦 Products loaded: ${response.productDetails.length}');
//
//       if (response.error != null) {
//         print('❌ Error from store: ${response.error}');
//         onPurchaseError?.call('Store error: ${response.error}');
//         return;
//       }
//
//       _products = response.productDetails;
//
//       if (_products.isEmpty) {
//         print('⚠️ WARNING: No products found in store!');
//         print(
//           '⚠️ Check if product IDs are configured correctly in App Store/Play Console',
//         );
//         print('⚠️ iOS IDs should be in App Store Connect');
//         print('⚠️ Android IDs should be in Google Play Console');
//
//         onProductsLoaded?.call(_products);
//         return;
//       }
//
//       for (var product in _products) {
//         print(
//           '💰 Product: ${product.id} - ${product.title} - ${product.price}',
//         );
//       }
//
//       onProductsLoaded?.call(_products);
//     } catch (e) {
//       print('❌ Error loading products: $e');
//       onPurchaseError?.call('Failed to load products: ${e.toString()}');
//     }
//   }
//
//   // Get product by ID
//   ProductDetails? getProductById(String productId) {
//     try {
//       return _products.firstWhere((p) => p.id == productId);
//     } catch (e) {
//       print('❌ Product not found: $productId');
//       return null;
//     }
//   }
//
//   // Get price for product
//   String getPriceForProduct(String productId) {
//     final product = getProductById(productId);
//     if (product != null) {
//       return product.price;
//     } else {
//       print('⚠️ Product $productId not found, using fallback');
//       if (productId == yearlyProductId || productId == staticYearlyProductId) {
//         return GetPlatform.isAndroid ? '\$79.99/year' : '\$99.99/year';
//       }
//       if (productId == weeklyProductId || productId == staticWeeklyProductId) {
//         return GetPlatform.isAndroid ? '\$23.99/week' : '\$29.99/week';
//       }
//       return 'Not Available';
//     }
//   }
//
//   Future<void> buyProduct(
//     String productId, {
//     bool fromCancelledFlow = false,
//     bool forcePurchase = false,
//   }) async {
//     try {
//       print('🛒 BUY PRODUCT CALLED: $productId');
//       print('🧪 Sandbox Mode: $_isSandboxEnvironment');
//       print('🔄 fromCancelledFlow: $fromCancelledFlow');
//
//       final prefs = await SharedPreferences.getInstance();
//       final wasEverCancelled = prefs.getBool('was_ever_cancelled') ?? false;
//       final isCurrentlyCancelled = prefs.getBool('is_cancelled') ?? false;
//       final cancelledProductId = prefs.getString('cancelled_product_id');
//
//       print('📊 Current State:');
//       print('   • was_ever_cancelled: $wasEverCancelled');
//       print('   • is_cancelled: $isCurrentlyCancelled');
//       print('   • cancelled_product_id: $cancelledProductId');
//       print('   • fromCancelledFlow: $fromCancelledFlow');
//
//       if ((wasEverCancelled || isCurrentlyCancelled) &&
//           cancelledProductId == productId) {
//         print('🚫 SAME PRODUCT CANCELLED - Should show bottomsheet');
//
//         await prefs.setBool('force_show_bottomsheet', true);
//
//         onPurchaseError?.call(
//           "Your subscription was cancelled. Please choose a new plan.",
//         );
//         return;
//       }
//
//       if (fromCancelledFlow) {
//         print('🔄 Processing purchase from cancelled flow');
//         await purchaseAfterCancellation(productId);
//
//         await Future.delayed(Duration(milliseconds: 300));
//       }
//
//       await _trackPurchaseAttempt(productId);
//
//       if (prefs.getBool('force_show_bottomsheet') == true) {
//         print('⚠️ Force showing bottomsheet flag is set');
//         await prefs.remove('force_show_bottomsheet');
//
//         onPurchaseError?.call(
//           "Your subscription was cancelled. Please choose a new plan.",
//         );
//         return;
//       }
//
//       final product = getProductById(productId);
//       if (product == null) {
//         print('❌ Product not found: $productId');
//         onPurchaseError?.call('Product not found');
//         return;
//       }
//
//       await _buyProductWithDetails(product);
//     } catch (e) {
//       print('❌ Error in buyProduct: $e');
//       onPurchaseError?.call('Failed to purchase: ${e.toString()}');
//       rethrow;
//     }
//   }
//
//   Future<void> _buyProductWithDetails(ProductDetails product) async {
//     try {
//       print('💳 Purchasing: ${product.id} - ${product.price}');
//       print('🧪 Sandbox Mode: $_isSandboxEnvironment');
//       print('📱 Platform: ${GetPlatform.isAndroid ? 'Android' : 'iOS'}');
//
//       final PurchaseParam purchaseParam = PurchaseParam(
//         productDetails: product,
//       );
//
//       final int timeoutSeconds = _isSandboxEnvironment ? 60 : 30;
//       print('⏰ Using timeout: $timeoutSeconds seconds');
//
//       final purchaseFuture = product.id.contains('sub')
//           ? _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam)
//           : _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
//
//       await purchaseFuture.timeout(
//         Duration(seconds: timeoutSeconds),
//         onTimeout: () {
//           print('❌ Purchase timeout after $timeoutSeconds seconds');
//           throw TimeoutException(
//             'Purchase operation timed out after $timeoutSeconds seconds. Please check your internet connection and try again.',
//           );
//         },
//       );
//
//       print('✅ Purchase initiated successfully');
//     } catch (e) {
//       print('❌ Error in purchase: $e');
//
//       if (e is TimeoutException) {
//         onPurchaseError?.call(
//           'Purchase is taking longer than expected. Please wait and check again in a few moments.',
//         );
//       } else if (e.toString().contains('network')) {
//         onPurchaseError?.call('Network error. Please check your connection.');
//       } else {
//         onPurchaseError?.call('Failed to purchase: ${e.toString()}');
//       }
//
//       rethrow;
//     }
//   }
//
//   // Handle purchase updates - SIMPLIFIED VERSION
//   void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
//     print('📨 PURCHASE UPDATES: ${purchaseDetailsList.length}');
//     print('🧪 Sandbox Mode: $_isSandboxEnvironment');
//
//     for (var purchaseDetails in purchaseDetailsList) {
//       print('--- Purchase Details ---');
//       print('Status: ${purchaseDetails.status}');
//       print('Product: ${purchaseDetails.productID}');
//       print('Pending: ${purchaseDetails.pendingCompletePurchase}');
//
//       if (purchaseDetails.transactionDate != null) {
//         print('Transaction Date: ${purchaseDetails.transactionDate}');
//       }
//
//       if (purchaseDetails.error != null) {
//         print('Error: ${purchaseDetails.error?.message}');
//       }
//
//       final isRestored = purchaseDetails.status == PurchaseStatus.restored;
//       final prefs = await SharedPreferences.getInstance();
//       final wasEverCancelled = prefs.getBool('was_ever_cancelled') ?? false;
//       final isCurrentlyCancelled = prefs.getBool('is_cancelled') ?? false;
//       final cancelledProductId = prefs.getString('cancelled_product_id');
//
//       print('🔍 RESTORE CHECK:');
//       print('   • Status: $isRestored');
//       print('   • Product: ${purchaseDetails.productID}');
//       print('   • Cancelled Product: $cancelledProductId');
//       print('   • was_ever_cancelled: $wasEverCancelled');
//       print('   • is_cancelled: $isCurrentlyCancelled');
//
//       if (isRestored && (wasEverCancelled || isCurrentlyCancelled)) {
//         print('🚫 BLOCKING RESTORE - This subscription was cancelled');
//
//         await _markAsCancelled(purchaseDetails);
//
//         if (purchaseDetails.pendingCompletePurchase) {
//           await _inAppPurchase.completePurchase(purchaseDetails);
//         }
//
//         onPurchaseError?.call(
//           "This subscription was cancelled. Please choose a new plan.",
//         );
//         continue;
//       }
//
//       final isOnAppStart =
//           _ignoreInitialRestoreEvents && !_userInitiatedRestore;
//
//       if (isRestored && isOnAppStart) {
//         print('🚫 BLOCKING AUTOMATIC RESTORE ON APP START');
//         print('ℹ️ This restore event is being ignored');
//
//         if (purchaseDetails.pendingCompletePurchase) {
//           await _inAppPurchase.completePurchase(purchaseDetails);
//         }
//         continue;
//       }
//
//       // Call controller's validation method
//       await _handlePurchaseFromController(purchaseDetails);
//
//       // Original service logic
//       switch (purchaseDetails.status) {
//         case PurchaseStatus.pending:
//           print('⏳ Purchase PENDING');
//           onPurchasePending?.call();
//           break;
//
//         case PurchaseStatus.purchased:
//           print('✅ Purchase SUCCESSFUL');
//           await _verifyAndCompletePurchase(purchaseDetails);
//           onPurchaseSuccess?.call(purchaseDetails);
//           break;
//
//         case PurchaseStatus.restored:
//           if (_userInitiatedRestore &&
//               !wasEverCancelled &&
//               !isCurrentlyCancelled) {
//             print('✅ Purchase RESTORED (User initiated)');
//             await _verifyAndCompletePurchase(purchaseDetails);
//             onPurchaseSuccess?.call(purchaseDetails);
//           } else {
//             print(
//               '🚫 BLOCKING RESTORE - Not user initiated or subscription cancelled',
//             );
//
//             if (purchaseDetails.pendingCompletePurchase) {
//               await _inAppPurchase.completePurchase(purchaseDetails);
//             }
//           }
//           break;
//
//         case PurchaseStatus.error:
//           print('❌ Purchase ERROR');
//           final errorMsg = purchaseDetails.error?.message ?? 'Unknown error';
//
//           if (errorMsg.toLowerCase().contains('cancel') ||
//               errorMsg.toLowerCase().contains('expired') ||
//               errorMsg.toLowerCase().contains('refund') ||
//               errorMsg.toLowerCase().contains('revoked')) {
//             print('⚠️ CANCELLATION DETECTED FROM ERROR');
//             await _markAsCancelled(purchaseDetails);
//           }
//
//           onPurchaseError?.call(errorMsg);
//           break;
//
//         case PurchaseStatus.canceled:
//           print('🚫 Purchase CANCELLED BY USER');
//           await _markAsCancelled(purchaseDetails);
//           onPurchaseError?.call("Purchase cancelled by user");
//           break;
//       }
//     }
//   }
//
//   // Handle purchase from controller
//   Future<void> _handlePurchaseFromController(
//     PurchaseDetails purchaseDetails,
//   ) async {
//     print('════════════════════════════════════');
//     print('[IAP] 🔥 _handlePurchaseFromController');
//     print('[IAP] status: ${purchaseDetails.status}');
//     print('[IAP] productID: ${purchaseDetails.productID}');
//     print(
//       '[IAP] pendingCompletePurchase: ${purchaseDetails.pendingCompletePurchase}',
//     );
//
//     if (purchaseDetails.status == PurchaseStatus.purchased) {
//       final ok = await _validateAndSetPremiumFromPurchase(purchaseDetails);
//     }
//
//     if (purchaseDetails.status == PurchaseStatus.restored) {
//       print('[IAP] Restore event received (ignored for entitlement)');
//     }
//
//     if (purchaseDetails.pendingCompletePurchase) {
//       print('[IAP] Completing purchase...');
//       await _inAppPurchase.completePurchase(purchaseDetails);
//     }
//   }
//
//   // Immediately mark subscription as cancelled
//   Future<void> _markAsCancelled(PurchaseDetails purchaseDetails) async {
//     try {
//       final productId = purchaseDetails.productID.toLowerCase();
//       print('🚫 MARKING AS CANCELLED: $productId');
//       print('🧪 Sandbox Mode: $_isSandboxEnvironment');
//
//       await _prefs?.remove(_kIsPremiumKey);
//       await _prefs?.remove(_kPremiumExpiryKey);
//       await _prefs?.remove(_kPurchaseTokenKey);
//       await _prefs?.remove('productId');
//       await _prefs?.remove('purchaseDate');
//
//       final current = _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
//       current.remove(productId);
//       if (GetPlatform.isAndroid) {
//         final upperVariant = productId.replaceAll('sub', 'Sub');
//         current.remove(upperVariant);
//       }
//       await _prefs?.setStringList(_kPrefPurchasedKey, current);
//
//       await _prefs?.setBool('is_cancelled', true);
//       await _prefs?.setBool('was_ever_cancelled', true);
//       await _prefs?.setString('cancel_date', DateTime.now().toIso8601String());
//
//       await _prefs?.setString('cancelled_product_id', productId);
//       await _prefs?.setString(
//         'cancelled_product_name',
//         productId.contains('weekly') ? 'weekly' : 'yearly',
//       );
//
//       if (_isSandboxEnvironment) {
//         await _prefs?.setBool('manual_cancel_test', true);
//         await _prefs?.setBool('sandbox_cancelled_$productId', true);
//         print('🧪 SANDBOX: Set cancellation flags');
//       }
//
//       await _prefs?.setBool('force_show_bottomsheet', true);
//
//       await _prefs?.setInt('purchase_attempt_count', 0);
//
//       await notifyPremiumStatusChanged(false);
//
//       print('✅ Subscription marked as CANCELLED (permanently)');
//       print('📋 Purchased list after: $current');
//       print('📝 Cancelled product: $productId');
//       print('⚠️ Next purchase will show bottomsheet');
//     } catch (e) {
//       print('❌ Error marking as cancelled: $e');
//     }
//   }
//
//   // Verify + complete purchase
//   Future<void> _verifyAndCompletePurchase(
//     PurchaseDetails purchaseDetails,
//   ) async {
//     try {
//       print('🔐 VERIFYING PURCHASE');
//
//       bool isValid = await _verifyPurchase(purchaseDetails);
//       print('Verification result: $isValid');
//
//       if (isValid) {
//         await _storePurchaseLocally(purchaseDetails);
//
//         if (purchaseDetails.pendingCompletePurchase) {
//           print('✅ Completing purchase...');
//           await _inAppPurchase.completePurchase(purchaseDetails);
//         }
//
//         print('✅ Purchase stored successfully');
//       } else {
//         print('❌ Verification failed');
//         onPurchaseError?.call('Purchase verification failed');
//       }
//     } catch (e) {
//       print("❌ Error completing purchase: $e");
//       onPurchaseError?.call("Error completing purchase: $e");
//     }
//   }
//
//   Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
//     try {
//       if (kDebugMode) {
//         print('🧪 DEBUG MODE: Skipping verification');
//         return true;
//       }
//
//       final serverData =
//           purchaseDetails.verificationData.serverVerificationData;
//       return serverData.isNotEmpty;
//     } catch (e) {
//       print('❌ Verification error: $e');
//       return false;
//     }
//   }
//
//   // Store purchase locally
//   Future<void> _storePurchaseLocally(PurchaseDetails purchaseDetails) async {
//     try {
//       final productId = purchaseDetails.productID.toLowerCase();
//       print('💾 STORING PURCHASE: $productId');
//       print('🧪 Sandbox Mode: $_isSandboxEnvironment');
//
//       final prefs = await SharedPreferences.getInstance();
//
//       await prefs.remove('is_cancelled');
//       await prefs.remove(_kCancelDate);
//       await prefs.remove(_kManualCancelTest);
//       await prefs.remove('${_kSandboxCancelledPrefix}$productId');
//
//       final List<String> current =
//           prefs.getStringList(_kPrefPurchasedKey) ?? <String>[];
//
//       if (!current.contains(productId)) {
//         current.add(productId);
//
//         if (GetPlatform.isAndroid) {
//           final upperVariant = productId.replaceAll('sub', 'Sub');
//           if (!current.contains(upperVariant)) {
//             current.add(upperVariant);
//           }
//         }
//
//         await prefs.setStringList(_kPrefPurchasedKey, current);
//       }
//
//       await _setPremiumStatus(true);
//
//       await _setSubscriptionExpiryDate(productId);
//
//       await prefs.setString('productId', productId);
//       await prefs.setString('purchaseDate', DateTime.now().toIso8601String());
//
//       print('✅ Purchase stored: $productId');
//     } catch (e) {
//       print("❌ Error saving purchase: $e");
//     }
//   }
//
//   // Set subscription expiry date (Same for both sandbox and production)
//   Future<void> _setSubscriptionExpiryDate(String productId) async {
//     final now = DateTime.now();
//     DateTime expiryDate;
//
//     if (productId.contains('weekly') || productId.contains('weeklySub')) {
//       expiryDate = now.add(Duration(days: 7));
//       print('📅 Weekly expiry: 7 days');
//     } else if (productId.contains('yearly') ||
//         productId.contains('yearlySub')) {
//       expiryDate = now.add(Duration(days: 365));
//       print('📅 Yearly expiry: 365 days');
//     } else {
//       expiryDate = now.add(Duration(days: 30));
//       print('📅 Default expiry: 30 days');
//     }
//
//     await _prefs?.setString(_kPremiumExpiryKey, expiryDate.toIso8601String());
//     print('📅 Expiry Date: $expiryDate');
//   }
//
//   // Set premium status and notify listeners
//   Future<void> _setPremiumStatus(bool isPremium) async {
//     final previousStatus = _prefs?.getBool(_kIsPremiumKey) ?? false;
//
//     print('🎯 SETTING PREMIUM STATUS');
//     print('📊 Previous: $previousStatus, New: $isPremium');
//
//     await _prefs?.setBool(_kIsPremiumKey, isPremium);
//
//     try {
//       await TrialManager.setPremium(isPremium);
//     } catch (e) {
//       print('❌ Error updating TrialManager: $e');
//     }
//
//     if (previousStatus != isPremium) {
//       if (!_premiumStatusController.isClosed) {
//         _premiumStatusController.add(isPremium);
//       }
//       onPremiumStatusChanged?.call(isPremium);
//       print('📢 Listeners notified of status change');
//     }
//
//     print('✅ Premium status updated to: $isPremium');
//   }
//
//   // From controller
//   Future<void> _setPremium({DateTime? expiry, required String reason}) async {
//     if (_historyValidationCompleted && reason.startsWith('stream')) {
//       print('[IAP] Ignoring stream result after history validation');
//       return;
//     }
//
//     print('[IAP] ✅ SET PREMIUM (reason=$reason)');
//     isPaidVersion.value = true;
//     await _prefs?.write('isPremiumUser', true);
//
//     if (expiry != null) {
//       await _prefs?.write('premiumExpiry', expiry.toIso8601String());
//       print('[IAP] Stored expiry: $expiry');
//     } else {
//       print('[IAP] No expiry stored (android/client-side or unknown)');
//     }
//
//     // Also update service premium status
//     await _setPremiumStatus(true);
//   }
//
//   Future<void> _setNotPremium({required String reason}) async {
//     if (_historyValidationCompleted && reason.startsWith('stream')) {
//       print('[IAP] Ignoring stream result after history validation');
//       return;
//     }
//
//     print('[IAP] ❌ SET NOT PREMIUM (reason=$reason)');
//     isPaidVersion.value = false;
//     await _prefs?.write('isPremiumUser', false);
//     await _prefs?.remove('premiumExpiry');
//
//     // Also update service premium status
//     await _setPremiumStatus(false);
//   }
//
//   // Check if purchased
//   bool isPurchased(String productId) {
//     final current = _prefs?.getStringList(_kPrefPurchasedKey) ?? <String>[];
//     final lowerId = productId.toLowerCase();
//     final upperId = productId.replaceAll('sub', 'Sub');
//
//     return current.contains(productId) ||
//         current.contains(lowerId) ||
//         current.contains(upperId);
//   }
//
//   // MAIN METHOD: Check subscription access - FIXED
//   Future<bool> hasPremiumAccess() async {
//     try {
//       final wasEverCancelled = _prefs?.getBool('was_ever_cancelled') ?? false;
//       final isCurrentlyCancelled = _prefs?.getBool('is_cancelled') ?? false;
//
//       if (wasEverCancelled || isCurrentlyCancelled) {
//         print('🚫 SUBSCRIPTION CANCELLED - No premium access');
//         await _setPremiumStatus(false);
//         return false;
//       }
//
//       final expiryDateStr = _prefs?.getString(_kPremiumExpiryKey);
//       if (expiryDateStr != null) {
//         try {
//           final expiryDate = DateTime.parse(expiryDateStr);
//           final now = DateTime.now();
//
//           if (now.isAfter(expiryDate)) {
//             print('❌ SUBSCRIPTION EXPIRED');
//             await _setPremiumStatus(false);
//             return false;
//           } else {
//             print('✅ Subscription valid until $expiryDate');
//             await _setPremiumStatus(true);
//             return true;
//           }
//         } catch (e) {
//           print('❌ Error parsing expiry date: $e');
//         }
//       }
//
//       print('📭 No active subscription found');
//       await _setPremiumStatus(false);
//       return false;
//     } catch (e) {
//       print('❌ Error checking premium access: $e');
//       await _setPremiumStatus(false);
//       return false;
//     }
//   }
//
//   // Get current premium status
//   bool get isPremiumUser {
//     return _prefs?.getBool(_kIsPremiumKey) ?? false;
//   }
//
//   // Force check subscription status
//   Future<void> forceCheckSubscriptionStatus() async {
//     print('🔄 FORCE CHECKING SUBSCRIPTION STATUS');
//     await _checkSubscriptionValidity();
//   }
//
//   // Safe date parsing helper
//   DateTime? _safeParseDate(dynamic dateValue) {
//     if (dateValue == null) return null;
//
//     try {
//       if (dateValue is DateTime) {
//         return dateValue;
//       } else if (dateValue is String) {
//         final parsed = DateTime.tryParse(dateValue);
//         if (parsed != null) return parsed;
//
//         final cleaned = dateValue.replaceAll('T', ' ').replaceAll('Z', '');
//         final parsed2 = DateTime.tryParse(cleaned);
//         if (parsed2 != null) return parsed2;
//       } else if (dateValue is int) {
//         return DateTime.fromMillisecondsSinceEpoch(dateValue);
//       }
//     } catch (e) {
//       print('⚠️ Error parsing date: $e');
//     }
//
//     return null;
//   }
//
//   // Reset for sandbox testing
//   Future<void> resetForFreshPurchase() async {
//     try {
//       print('🔄 RESETTING FOR FRESH PURCHASE');
//
//       final prefs = await SharedPreferences.getInstance();
//
//       await prefs.remove('is_cancelled');
//       await prefs.remove(_kPremiumExpiryKey);
//       await prefs.remove(_kPurchaseTokenKey);
//       await prefs.remove('productId');
//       await prefs.remove('purchaseDate');
//       await prefs.remove(_kPrefPurchasedKey);
//       await prefs.remove(_kCancelDate);
//       await prefs.remove(_kIsPremiumKey);
//
//       await prefs.remove(_kManualCancelTest);
//       await prefs.remove('${_kSandboxCancelledPrefix}weekly_id');
//       await prefs.remove('${_kSandboxCancelledPrefix}yearly_id');
//       await prefs.remove('${_kSandboxCancelledPrefix}as.emojimaker.weeklySub');
//       await prefs.remove('${_kSandboxCancelledPrefix}as.emojimaker.yearlySub');
//
//       _ignoreInitialRestoreEvents = true;
//       _userInitiatedRestore = false;
//
//       _startRestoreBlockTimer();
//
//       print('✅ Successfully reset for fresh purchase');
//     } catch (e) {
//       print('❌ Error resetting: $e');
//       rethrow;
//     }
//   }
//
//   // Force cancel subscription (for testing)
//   Future<void> forceCancelSubscription() async {
//     print('🛑 FORCE CANCELLING SUBSCRIPTION');
//     await _prefs?.setBool('is_cancelled', true);
//     await _prefs?.setString(_kCancelDate, DateTime.now().toIso8601String());
//     if (_isSandboxEnvironment) {
//       await _prefs?.setBool(_kManualCancelTest, true);
//     }
//     await _setPremiumStatus(false);
//     print('✅ Force cancelled');
//   }
//
//   // Clear cache (for testing)
//   Future<void> clearPurchaseCache() async {
//     print('🗑️ CLEARING ALL CACHE');
//
//     await _prefs?.remove(_kPrefPurchasedKey);
//     await _prefs?.remove(_kIsPremiumKey);
//     await _prefs?.remove(_kPremiumExpiryKey);
//     await _prefs?.remove(_kPurchaseTokenKey);
//     await _prefs?.remove('productId');
//     await _prefs?.remove('purchaseDate');
//     await _prefs?.remove('is_cancelled');
//     await _prefs?.remove(_kCancelDate);
//     await _prefs?.remove(_kAppStartTime);
//
//     await _prefs?.remove(_kManualCancelTest);
//     await _prefs?.remove('${_kSandboxCancelledPrefix}weekly_id');
//     await _prefs?.remove('${_kSandboxCancelledPrefix}yearly_id');
//     await _prefs?.remove('${_kSandboxCancelledPrefix}as.emojimaker.weeklySub');
//     await _prefs?.remove('${_kSandboxCancelledPrefix}as.emojimaker.yearlySub');
//
//     print(' Cache cleared');
//     if (!_premiumStatusController.isClosed) {
//       _premiumStatusController.add(false);
//     }
//   }
//
//   // Public method to manually reset sandbox
//   Future<void> manualResetSandbox() async {
//     print('🔄 MANUAL SANDBOX RESET');
//     await resetForFreshPurchase();
//     print('✅ Sandbox manually reset - Ready for fresh testing');
//   }
//
//   // UI Helper Methods from controller
//   void selectPlan(String plan) {
//     print('[IAP] Plan selected: $plan');
//     selectedPlan.value = plan;
//   }
//
//   // Check if premium features should be available
//   bool isPremiumActive() {
//     if (isPaidVersion.value) {
//       return true;
//     }
//
//     final expiryStr = _prefs?.read('premiumExpiry');
//     if (expiryStr != null) {
//       try {
//         final expiry = DateTime.parse(expiryStr);
//         return DateTime.now().toUtc().isBefore(expiry);
//       } catch (e) {
//         return false;
//       }
//     }
//
//     return false;
//   }
//
//   // Dispose
//   void dispose() {
//     print(' Disposing IAP service');
//     _purchaseSubscription.cancel();
//     _restoreBlockTimer?.cancel();
//
//     _iapHelperConnection.finalize();
//
//     if (!_premiumStatusController.isClosed) {
//       _premiumStatusController.close();
//     }
//
//     _initialized = false;
//   }
//
//   // Getters
//   List<ProductDetails> get productDetailsList => _products;
//   bool get isAvailable => _isAvailable;
//   bool get isStoreAvailable => _isAvailable;
//   List<PurchasableProduct> get purchasableProducts => products;
//
//   // Observable getters
//   Rx<StoreState> get storeStateRx => storeState;
//   RxBool get isPaidVersionRx => isPaidVersion;
//   RxBool get isLoadingRx => isLoading;
//   RxString get weeklyPriceRx => weeklyPrice;
//   RxString get yearlyPriceRx => yearlyPrice;
//   RxBool get purchasePendingRx => purchasePending;
//   RxString get selectedPlanRx => selectedPlan;
// }
