// // import 'dart:async';
// // import 'dart:io';
// //
// // import 'package:flutter/material.dart';
// // import 'package:in_app_purchase/in_app_purchase.dart';
// //
// // enum StoreState { loading, available, notAvailable }
// //
// // class PurchasableProduct {
// //   final ProductDetails productDetails;
// //   final String id;
// //   bool isPurchased;
// //
// //   PurchasableProduct(this.productDetails)
// //     : id = productDetails.id,
// //       isPurchased = false;
// // }
// //
// // class PaidVersionCheckNotifier extends ChangeNotifier {
// //   late StreamSubscription<List<PurchaseDetails>> _subscription;
// //   final iapConnection = InAppPurchase.instance;
// //
// //   // ✅ FIXED: Added better subscription keys
// //   final Map<int, String> subscriptionKeys = {
// //     0: 'as.emojimaker.weeklySub',
// //     1: 'as.emojimaker.yearlySub',
// //   };
// //
// //   // ✅ FIXED: Add weekly and yearly IDs for easy access
// //   String get weeklyProductId => 'as.emojimaker.weeklySub';
// //   String get yearlyProductId => 'as.emojimaker.yearlySub';
// //
// //   List<PurchasableProduct> products = [];
// //   StoreState storeState = StoreState.loading;
// //
// //   bool isPaidVersion = false;
// //
// //   // ✅ NEW: Track user's purchase flow
// //   bool _isUserInPurchaseFlow = false;
// //   bool _ignoreInitialRestore = true;
// //   Timer? _restoreBlockTimer;
// //
// //   PaidVersionCheckNotifier() {
// //     _initializeService();
// //   }
// //
// //   // ✅ FIXED: Proper initialization
// //   Future<void> _initializeService() async {
// //     print('🎯 IAP SERVICE INITIALIZING...');
// //
// //     // Subscribe to purchase stream FIRST
// //     _subscribeToPurchases();
// //
// //     // Check availability
// //     final isAvailable = await iapConnection.isAvailable();
// //     print('📱 IAP Available: $isAvailable');
// //
// //     if (!isAvailable) {
// //       storeState = StoreState.notAvailable;
// //       notifyListeners();
// //       return;
// //     }
// //
// //     // Load products
// //     await _loadProducts();
// //
// //     // Check existing purchases
// //     await _checkExistingPurchases();
// //
// //     // Start restore block timer (3 seconds)
// //     _startRestoreBlockTimer();
// //
// //     storeState = StoreState.available;
// //     notifyListeners();
// //   }
// //
// //   void _startRestoreBlockTimer() {
// //     print('⏱️ Starting restore block timer (3 seconds)');
// //     _ignoreInitialRestore = true;
// //
// //     _restoreBlockTimer = Timer(Duration(seconds: 3), () {
// //       print('✅ Restore block timer expired');
// //       _ignoreInitialRestore = false;
// //       _restoreBlockTimer?.cancel();
// //     });
// //   }
// //
// //   // ✅ FIXED: Subscribe to purchase stream
// //   void _subscribeToPurchases() {
// //     print('🔗 Subscribing to purchase stream');
// //
// //     final purchaseUpdated = iapConnection.purchaseStream;
// //     _subscription = purchaseUpdated.listen(
// //       _onPurchaseUpdate,
// //       onDone: () {
// //         print('✅ Purchase stream closed');
// //         _subscription.cancel();
// //       },
// //       onError: (error) {
// //         print('❌ Purchase stream error: $error');
// //       },
// //     );
// //   }
// //
// //   @override
// //   void dispose() {
// //     print('👋 Disposing IAP service');
// //     _subscription.cancel();
// //     _restoreBlockTimer?.cancel();
// //     super.dispose();
// //   }
// //
// //   // ✅ IMPROVED: Buy subscription by ID
// //   Future<void> buySubID(int id) async {
// //     print('🛒 BUYING SUBSCRIPTION ID: $id');
// //
// //     if (!await iapConnection.isAvailable()) {
// //       print('❌ IAP not available');
// //       throw Exception('In-app purchases not available');
// //     }
// //
// //     final productId = subscriptionKeys[id];
// //     if (productId == null) {
// //       print('❌ Invalid subscription ID: $id');
// //       throw Exception('Invalid subscription ID');
// //     }
// //
// //     // Find the product
// //     final product = products.firstWhere(
// //       (p) => p.id == productId,
// //       orElse: () => throw Exception('Product not found: $productId'),
// //     );
// //
// //     await _buyProduct(product);
// //   }
// //
// //   // ✅ FIXED: Buy product method
// //   Future<void> _buyProduct(PurchasableProduct product) async {
// //     try {
// //       print('🚀 STARTING PURCHASE FLOW FOR: ${product.id}');
// //
// //       // Set user in purchase flow
// //       _isUserInPurchaseFlow = true;
// //
// //       // Clear auto-restore block during purchase flow
// //       _ignoreInitialRestore = false;
// //
// //       final purchaseParam = PurchaseParam(
// //         productDetails: product.productDetails,
// //       );
// //
// //       print('💳 Purchasing: ${product.id} - ${product.productDetails.price}');
// //
// //       // Buy non-consumable (subscription)
// //       await iapConnection.buyNonConsumable(purchaseParam: purchaseParam);
// //     } catch (e) {
// //       print('❌ Error in purchase: $e');
// //       _isUserInPurchaseFlow = false;
// //       rethrow;
// //     }
// //   }
// //
// //   // ✅ IMPROVED: Handle purchase updates
// //   Future<void> _onPurchaseUpdate(
// //     List<PurchaseDetails> purchaseDetailsList,
// //   ) async {
// //     print('📨 PURCHASE UPDATES: ${purchaseDetailsList.length}');
// //     print('User in purchase flow: $_isUserInPurchaseFlow');
// //     print('Ignore initial restore: $_ignoreInitialRestore');
// //
// //     for (var purchaseDetails in purchaseDetailsList) {
// //       print('--- Purchase Details ---');
// //       print('Status: ${purchaseDetails.status}');
// //       print('Product: ${purchaseDetails.productID}');
// //       print('Pending: ${purchaseDetails.pendingCompletePurchase}');
// //
// //       if (purchaseDetails.error != null) {
// //         print('Error: ${purchaseDetails.error?.message}');
// //       }
// //
// //       // ✅ CRITICAL FIX: Handle auto-restore blocking
// //       if (purchaseDetails.status == PurchaseStatus.restored) {
// //         if (_ignoreInitialRestore && !_isUserInPurchaseFlow) {
// //           print('🚫 BLOCKING AUTO-RESTORE ON APP START');
// //           print('This restore event is being ignored');
// //           continue; // Skip auto-restore
// //         }
// //
// //         if (_isUserInPurchaseFlow) {
// //           print('⚠️ Restore during purchase flow - showing subscribe dialog');
// //           // Don't process as purchase, let Apple show subscribe dialog
// //           continue;
// //         }
// //       }
// //
// //       await _handlePurchase(purchaseDetails);
// //     }
// //
// //     // Reset purchase flow flag
// //     _isUserInPurchaseFlow = false;
// //
// //     // Reload products to update UI
// //     await _loadProducts();
// //
// //     notifyListeners();
// //   }
// //
// //   // ✅ FIXED: Handle individual purchase
// //   Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
// //     try {
// //       print('🔐 PROCESSING PURCHASE: ${purchaseDetails.productID}');
// //
// //       switch (purchaseDetails.status) {
// //         case PurchaseStatus.pending:
// //           print('⏳ Purchase PENDING');
// //           break;
// //
// //         case PurchaseStatus.purchased:
// //           print('✅ Purchase SUCCESSFUL');
// //           await _completeSuccessfulPurchase(purchaseDetails);
// //           break;
// //
// //         case PurchaseStatus.restored:
// //           print('✅ Purchase RESTORED (Manual)');
// //           await _completeSuccessfulPurchase(purchaseDetails);
// //           break;
// //
// //         case PurchaseStatus.error:
// //           print('❌ Purchase ERROR: ${purchaseDetails.error?.message}');
// //           _isUserInPurchaseFlow = false;
// //           break;
// //
// //         case PurchaseStatus.canceled:
// //           print('🚫 Purchase CANCELLED BY USER');
// //           _isUserInPurchaseFlow = false;
// //           break;
// //       }
// //
// //       // Complete purchase if needed
// //       if (purchaseDetails.pendingCompletePurchase) {
// //         print('✅ Completing purchase with store...');
// //         await iapConnection.completePurchase(purchaseDetails);
// //       }
// //     } catch (e) {
// //       print('❌ Error handling purchase: $e');
// //       _isUserInPurchaseFlow = false;
// //     }
// //   }
// //
// //   // ✅ NEW: Complete successful purchase
// //   Future<void> _completeSuccessfulPurchase(
// //     PurchaseDetails purchaseDetails,
// //   ) async {
// //     try {
// //       final productId = purchaseDetails.productID.toLowerCase();
// //       print('💾 STORING PURCHASE: $productId');
// //
// //       // Set as paid version
// //       isPaidVersion = true;
// //
// //       // Update product purchased status
// //       for (var product in products) {
// //         if (product.id.toLowerCase() == productId) {
// //           product.isPurchased = true;
// //           break;
// //         }
// //       }
// //
// //       // Store purchase locally (simplified)
// //       await _storePurchaseLocally(productId);
// //
// //       print('✅ Premium access granted for: $productId');
// //     } catch (e) {
// //       print('❌ Error completing purchase: $e');
// //     }
// //   }
// //
// //   // ✅ NEW: Store purchase locally
// //   Future<void> _storePurchaseLocally(String productId) async {
// //     try {
// //       // You would use shared preferences here
// //       print('📝 Storing purchase in local storage: $productId');
// //
// //       // Set subscription expiry date
// //       final expiryDate = _calculateExpiryDate(productId);
// //       print('📅 Subscription expires: $expiryDate');
// //     } catch (e) {
// //       print('❌ Error storing purchase locally: $e');
// //     }
// //   }
// //
// //   // ✅ NEW: Calculate expiry date
// //   DateTime _calculateExpiryDate(String productId) {
// //     final now = DateTime.now();
// //
// //     if (productId.contains('weekly') || productId.contains('weeklySub')) {
// //       return now.add(Duration(days: 7));
// //     } else if (productId.contains('yearly') ||
// //         productId.contains('yearlySub')) {
// //       return now.add(Duration(days: 365));
// //     }
// //
// //     return now.add(Duration(days: 30)); // Default
// //   }
// //
// //   // ✅ FIXED: Load products
// //   Future<void> _loadProducts() async {
// //     try {
// //       print('🛍️ LOADING PRODUCTS...');
// //
// //       if (!await iapConnection.isAvailable()) {
// //         storeState = StoreState.notAvailable;
// //         notifyListeners();
// //         return;
// //       }
// //
// //       final Set<String> productIds = subscriptionKeys.values.toSet();
// //       print('🔍 Querying products: $productIds');
// //
// //       final response = await iapConnection.queryProductDetails(productIds);
// //
// //       print('📦 Products not found: ${response.notFoundIDs}');
// //       print('📦 Products loaded: ${response.productDetails.length}');
// //
// //       products = response.productDetails
// //           .map((e) => PurchasableProduct(e))
// //           .toList();
// //
// //       // Log loaded products
// //       for (var product in products) {
// //         print(
// //           '💰 Product: ${product.id} - ${product.productDetails.title} - ${product.productDetails.price}',
// //         );
// //       }
// //     } catch (e) {
// //       print('❌ Error loading products: $e');
// //       storeState = StoreState.notAvailable;
// //     }
// //
// //     notifyListeners();
// //   }
// //
// //   // ✅ FIXED: Check existing purchases
// //   Future<void> _checkExistingPurchases() async {
// //     try {
// //       print('🔍 CHECKING EXISTING PURCHASES...');
// //
// //       // For iOS, we need to restore purchases to check
// //       if (Platform.isIOS) {
// //         print('📱 iOS detected - restoring purchases to check status');
// //         await _restorePurchases();
// //       } else {
// //         // For Android, query purchase history
// //         print('🤖 Android detected - checking purchase status');
// //         await _checkAndroidPurchases();
// //       }
// //     } catch (e) {
// //       print('❌ Error checking existing purchases: $e');
// //     }
// //   }
// //
// //   // ✅ NEW: Restore purchases
// //   Future<void> _restorePurchases() async {
// //     try {
// //       print('🔄 RESTORING PURCHASES...');
// //
// //       // Set user initiated restore
// //       _ignoreInitialRestore = false;
// //
// //       await iapConnection.restorePurchases();
// //
// //       // Wait for stream to process
// //       await Future.delayed(Duration(seconds: 2));
// //
// //       print('✅ Restore completed');
// //     } catch (e) {
// //       print('❌ Error restoring purchases: $e');
// //     }
// //   }
// //
// //   // ✅ NEW: Check Android purchases
// //   // ❌ OLD (deprecated):
// //   // final QueryPurchaseDetailsResponse purchaseResponse = await iapConnection
// //   //     .queryPastPurchases();
// //
// //   // ✅ NEW:
// //   Future<void> _checkAndroidPurchases() async {
// //     try {
// //       print('🤖 Android detected - checking purchase status');
// //
// //       // Use restorePurchases instead of queryPastPurchases
// //       await _restorePurchases();
// //     } catch (e) {
// //       print('❌ Error checking Android purchases: $e');
// //     }
// //   }
// //
// //   // ✅ NEW: Manual restore purchases (user initiated)
// //   Future<void> restorePurchases() async {
// //     try {
// //       print('👤 USER INITIATED RESTORE');
// //
// //       // Clear auto-restore block
// //       _ignoreInitialRestore = false;
// //
// //       // Set loading state
// //       storeState = StoreState.loading;
// //       notifyListeners();
// //
// //       await _restorePurchases();
// //
// //       // Reload products
// //       await _loadProducts();
// //
// //       storeState = StoreState.available;
// //       notifyListeners();
// //     } catch (e) {
// //       print('❌ Error in user restore: $e');
// //       storeState = StoreState.available;
// //       notifyListeners();
// //     }
// //   }
// //
// //   // ✅ NEW: Check if product is available
// //   bool isProductAvailable(String productId) {
// //     return products.any((product) => product.id == productId);
// //   }
// //
// //   // ✅ NEW: Get product price
// //   String getProductPrice(String productId) {
// //     try {
// //       final product = products.firstWhere((p) => p.id == productId);
// //       return product.productDetails.price;
// //     } catch (e) {
// //       return 'Not Available';
// //     }
// //   }
// //
// //   // ✅ NEW: Check if product is purchased
// //   bool isProductPurchased(String productId) {
// //     try {
// //       final product = products.firstWhere((p) => p.id == productId);
// //       return product.isPurchased;
// //     } catch (e) {
// //       return false;
// //     }
// //   }
// //
// //   // ✅ NEW: Clear purchase cache (for testing)
// //   Future<void> clearPurchaseCache() async {
// //     print('🗑️ CLEARING PURCHASE CACHE');
// //     isPaidVersion = false;
// //
// //     for (var product in products) {
// //       product.isPurchased = false;
// //     }
// //
// //     notifyListeners();
// //   }
// // }
//
// import 'dart:async';
//
// import '../../controller/premium_controller.dart';
//
// class PurchaseHandler {
//   static Future<void> handlePurchase(
//     PremiumController controller,
//     int productIndex,
//     Function(bool) onLoaderUpdate,
//   ) async {
//     try {
//       onLoaderUpdate(true);
//
//       final completer = Completer<void>();
//
//       // Listen for purchase state changes
//       StreamSubscription? subscription;
//       subscription = controller.purchasePending.listen((isPending) {
//         if (!isPending) {
//           onLoaderUpdate(false);
//           completer.complete();
//           subscription?.cancel();
//         }
//       });
//
//       // Start purchase
//       await controller.buySubID(productIndex);
//
//       // Wait for purchase to complete or timeout after 60 seconds
//       await completer.future.timeout(
//         const Duration(seconds: 60),
//         onTimeout: () {
//           onLoaderUpdate(false);
//           controller.purchasePending.value = false;
//           throw TimeoutException('Purchase timeout');
//         },
//       );
//     } catch (e) {
//       onLoaderUpdate(false);
//       controller.purchasePending.value = false;
//       rethrow;
//     }
//   }
// }
