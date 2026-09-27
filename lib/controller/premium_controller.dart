import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:flutter/widgets.dart';

enum StoreState { loading, available, notAvailable }

class PurchasableProduct {
  final ProductDetails productDetails;
  final String id;
  bool isPurchased;

  PurchasableProduct(this.productDetails)
      : id = productDetails.id,
        isPurchased = false;
}

class PremiumController extends GetxController with WidgetsBindingObserver {
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final iapConnection = InAppPurchase.instance;
  final iapHelperConnection = FlutterInappPurchase.instance;
  final box = GetStorage();

  static const _iosWeekly = 'as.emojimaker.weeklySub';
  static const _iosYearly = 'as.emojimaker.yearlySub';
  static const _androidWeekly = 'weekly_id';
  static const _androidYearly = 'yearly_id';

  static const _appleSharedSecret = "13fab366114d4fd0964948b7a4d205c8";

  List<String> get _productIds =>
      Platform.isIOS ? [_iosWeekly, _iosYearly] : [_androidWeekly, _androidYearly];

  final subscriptionKeys = <int, String>{
    0: Platform.isIOS ? _iosWeekly : _androidWeekly,
    1: Platform.isIOS ? _iosYearly : _androidYearly,
  };

  var storeState = StoreState.loading.obs;
  var isAvailable = false.obs;
  var isPaidVersion = false.obs;
  var isLoading = false.obs;
  var products = <PurchasableProduct>[].obs;
  var weeklyPrice = ''.obs;
  var yearlyPrice = ''.obs;
  var selectedPlan = 'Annual'.obs;
  var purchasePending = false.obs;

  bool _historyValidationCompleted = false;
  Timer? _purchaseTimeoutTimer;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    if (kDebugMode) {
      debugPrint("🚀 PremiumController initialized");
    }

    // SYNC CACHE FIRST
    _syncCacheWithController();
    _subscribeToPurchaseStream();
    _loadProducts();
    _startPeriodicRefresh();

    if (kDebugMode) {
      debugPrint("📊 Premium status from cache: ${isPaidVersion.value}");
    }
  }

  // =============================
  // LIFECYCLE DETECTION (FOR CREDENTIAL MODAL)
  // =============================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        debugPrint("📱 App resumed - checking for stuck purchase loader");
      }

      // If we are resumed and there's a purchase pending,
      // it might mean the user cancelled a system modal (like login).
      // We wait 1 second to see if a purchase update arrives.
      if (purchasePending.value) {
        if (kDebugMode) {
          debugPrint("⏳ Purchase/Restore pending during resume - starting recovery timers");
        }
        // Multi-stage check to handle different system settling times
        for (int delay in [1, 2, 5]) {
          Future.delayed(Duration(seconds: delay), () {
            if (purchasePending.value) {
              purchasePending.value = false;
              _purchaseTimeoutTimer?.cancel();
              if (kDebugMode) {
                debugPrint("Force-resetting stuck loader after app resume + ${delay}s delay");
              }
            }
          });
        }
      } else {
        if (kDebugMode) {
          debugPrint("App resumed - no purchase pending");
        }
      }
    }
  }

  // =============================
  // PERIODIC REFRESH
  // =============================
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    // Refresh every 10 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (kDebugMode) {
        debugPrint("Periodic subscription refresh triggered");
      }
      _validateHistory();
    });
  }

  // =============================
  // SYNC CACHE WITH CONTROLLER
  // =============================
  void _syncCacheWithController() {
    final cachedPremium = box.read('isPremiumUser') ?? false;
    final expiryStr = box.read('premiumExpiry');

    isPaidVersion.value = cachedPremium;
    if (kDebugMode) {
      debugPrint("🔄 Synced: Cache Premium = $cachedPremium, isPaidVersion = ${isPaidVersion.value}");
    }

    // If the cached value is true but the subscription is expired, reset it
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().toUtc().isAfter(expiry)) {
        isPaidVersion.value = false;
        box.write('isPremiumUser', false);
        box.remove('premiumExpiry');
        if (kDebugMode) {
          debugPrint("❌ Premium state expired, resetting to non-premium");
        }
      }
    }
  }

  // PUBLIC METHOD FOR SYNC
  void syncPremiumStatus() {
    _syncCacheWithController();
  }

  // =============================
  // STORE PRODUCTS
  // =============================
  Future<void> _loadProducts() async {
    isLoading.value = true;
    if (kDebugMode) {
      debugPrint("📦 Loading products...");
    }

    final available = await iapConnection.isAvailable();
    isAvailable.value = available;
    if (kDebugMode) {
      debugPrint("🛒 IAP available: $isAvailable");
    }

    if (!available) {
      storeState.value = StoreState.notAvailable;
      isLoading.value = false;
      if (kDebugMode) {
        debugPrint("❌ Store not available");
      }
      return;
    }

    final response = await iapConnection.queryProductDetails(
      subscriptionKeys.values.toSet(),
    );

    products.assignAll(
      response.productDetails.map((e) => PurchasableProduct(e)),
    );

    weeklyPrice.value =
        products.firstWhereOrNull((p) => p.id.contains('weekly'))?.productDetails.price ?? '';
    yearlyPrice.value =
        products.firstWhereOrNull((p) => p.id.contains('yearly'))?.productDetails.price ?? '';

    storeState.value = StoreState.available;
    isLoading.value = false;

    if (kDebugMode) {
      debugPrint("✅ Products loaded: ${products.length} items");
      debugPrint("💰 Weekly price: $weeklyPrice");
      debugPrint("💰 Yearly price: $yearlyPrice");
    }
  }

  // =============================
  // BUY - FIXED WITH PROPER TIMEOUT
  // =============================
  Future<void> buySubID(int index) async {
    // First sync cache
    _syncCacheWithController();

    // If the user is already premium, prevent purchasing again
    if (isPaidVersion.value) {
      if (kDebugMode) {
        debugPrint("✅ User is already a premium user. No need to buy again.");
      }
      return;
    }

    final productId = subscriptionKeys[index];
    final product = products.firstWhereOrNull((p) => p.id == productId);

    if (product == null || purchasePending.value) return;

    purchasePending.value = true;
    if (kDebugMode) {
      debugPrint("🛒 Attempting to purchase: $productId");
    }

    // Cancel any existing timeout timer
    _purchaseTimeoutTimer?.cancel();

    final param = Platform.isAndroid
        ? GooglePlayPurchaseParam(productDetails: product.productDetails)
        : PurchaseParam(productDetails: product.productDetails);

    // START TIMEOUT TIMER BEFORE THE ASYNC CALL
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = Timer(const Duration(seconds: 45), () {
      if (purchasePending.value) {
        purchasePending.value = false;
        if (kDebugMode) {
          debugPrint("⏰ [TIMEOUT] Purchase safety timeout after 45 seconds");
        }
      }
    });

    try {
      if (kDebugMode) {
        debugPrint("🚀 Calling buyNonConsumable for: $productId");
      }
      
      await iapConnection.buyNonConsumable(
        purchaseParam: param,
      );

      if (kDebugMode) {
        debugPrint("✅ iapConnection.buyNonConsumable returned for: $productId");
      }
    } catch (e) {
      purchasePending.value = false;
      _purchaseTimeoutTimer?.cancel();
      if (kDebugMode) {
        debugPrint('❌ [IAP] Buy failed with error: $e');
      }
    }
  }

  // =============================
  // PURCHASE STREAM - FIXED WITH PROPER RESET
  // =============================
  void _subscribeToPurchaseStream() {
    _subscription = iapConnection.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) {
        purchasePending.value = false; // Reset on stream error
        _purchaseTimeoutTimer?.cancel();
        if (kDebugMode) {
          debugPrint('❌ [IAP] Stream error: $e');
        }
      },
      onDone: () {
        purchasePending.value = false; // Reset when stream completes
        _purchaseTimeoutTimer?.cancel();
        _subscription.cancel();
      },
    );
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    if (kDebugMode) {
      debugPrint("📥 Purchase update received: ${purchases.length} purchases");
    }

    bool purchaseProcessed = false;
    bool purchaseCancelled = false;
    bool purchaseErrored = false;

    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (kDebugMode) {
          debugPrint("✅ Processing purchased/restored purchase: ${p.productID}");
        }

        // First sync cache
        _syncCacheWithController();

        // Only process the purchase if it hasn't been processed before
        if (!isPaidVersion.value) {
          final isValid = await _validateAndSetPremiumFromPurchase(p);

          if (isValid) {
            // CRITICAL: Update both controller AND cache
            isPaidVersion.value = true;
            await box.write('isPremiumUser', true);

            if (kDebugMode) {
              debugPrint("✅ Premium status updated: Controller=true, Cache=true");
            }

            // Force UI update
            update();

            purchaseProcessed = true;

            // Cancel timeout timer
            _purchaseTimeoutTimer?.cancel();

            // Navigate to home after successful purchase
            Future.delayed(const Duration(milliseconds: 800), () {
              Get.offAllNamed('/home');
            });
          }
        }
      }

      // ✅ FIX: Reset loader when purchase is cancelled
      if (p.status == PurchaseStatus.canceled) {
        purchaseCancelled = true;
        if (kDebugMode) {
          debugPrint('❌ [IAP] User cancelled purchase');
        }
      }

      // ✅ FIX: Reset loader when purchase has error
      if (p.status == PurchaseStatus.error) {
        purchaseErrored = true;
        if (kDebugMode) {
          debugPrint('❌ [IAP] Purchase error: ${p.error}');
        }
      }

      if (p.pendingCompletePurchase) {
        try {
          await iapConnection.completePurchase(p);
          if (kDebugMode) {
            debugPrint('✅ [IAP] Complete purchase called!');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ [IAP] Complete purchase failed: $e');
          }
        }
      }
    }

    // REVISED RESET LOGIC
    // If we receive a cancellation or error, we MUST reset the loader immediately 
    // to provide a responsive UI, even if other transactions are pending in the background.
    // If we processed a success, the success block handles the navigation/loader.
    
    if (purchaseCancelled || purchaseErrored) {
      purchasePending.value = false;
      _purchaseTimeoutTimer?.cancel();
      if (kDebugMode) {
        debugPrint("🔄 Purchase cancelled or errored - resetting loader immediately");
      }
    } else if (purchaseProcessed) {
      // Success is handled in the Loop, but as a safety:
      purchasePending.value = false;
      _purchaseTimeoutTimer?.cancel();
    } else if (purchases.isNotEmpty) {
      // If none are pending in the current update, ensure loader is off
      bool anyPending = purchases.any((p) => p.status == PurchaseStatus.pending);
      if (!anyPending) {
        purchasePending.value = false;
        _purchaseTimeoutTimer?.cancel();
        if (kDebugMode) {
          debugPrint("🔄 No pending transactions in update - resetting loader");
        }
      }
    }

    if (kDebugMode) {
      debugPrint("🔄 Purchase update completed");
    }
  }

  // =============================
  // HISTORY VALIDATION (MANUAL RESTORE ONLY)
  // =============================
  Future<void> _initAndValidateHistory() async {
    if (kDebugMode) {
      debugPrint("🔄 Initializing history validation...");
    }
    await FlutterInappPurchase.instance.initialize();
    await _validateHistory();
  }

  Future<void> _validateHistory() async {
    if (_historyValidationCompleted) return;

    if (kDebugMode) {
      debugPrint("🔍 Validating purchase history...");
    }

    final history = await iapHelperConnection.getAvailablePurchases();

    if (history == null || history.isEmpty) {
      await _setNotPremium();
      _historyValidationCompleted = true;
      if (kDebugMode) {
        debugPrint("❌ No purchase history found, user set to non-premium.");
      }
      return;
    }

    final latest = history.reduce((a, b) =>
    (a.transactionDate ?? DateTime(0))
        .isAfter(b.transactionDate ?? DateTime(0))
        ? a
        : b);

    if (kDebugMode) {
      debugPrint("📅 Latest purchase: $latest");
    }

    if (Platform.isIOS) {
      final receipt = latest.transactionReceipt ?? '';
      final res = await _validateAppleReceipt(receipt);
      final expiry = _extractAppleExpiry(res);

      if (expiry != null &&
          DateTime.now().toUtc().isBefore(expiry)) {
        await _setPremium(expiry: expiry);
        if (kDebugMode) {
          debugPrint("✅ User is premium, subscription valid until $expiry");
        }
      } else {
        await _setNotPremium();
        if (kDebugMode) {
          debugPrint("❌ User is not premium, subscription expired or invalid.");
        }
      }
    } else {
      await _setPremium();
      if (kDebugMode) {
        debugPrint("✅ Non-iOS user, set to premium.");
      }
    }

    _historyValidationCompleted = true;
  }

  // =============================
  // VALIDATION
  // =============================
  Future<bool> _validateAndSetPremiumFromPurchase(PurchaseDetails p) async {
    if (!_productIds.contains(p.productID)) return false;

    final data = p.verificationData.serverVerificationData;
    if (data.isEmpty) return false;

    if (kDebugMode) {
      debugPrint("🔍 Validating purchase: ${p.productID}");
    }

    if (Platform.isIOS) {
      final res = await _validateAppleReceipt(data);
      final expiry = _extractAppleExpiry(res);

      if (expiry != null &&
          DateTime.now().toUtc().isBefore(expiry)) {
        await _setPremium(expiry: expiry);
        if (kDebugMode) {
          debugPrint("✅ Subscription is valid, expiry: $expiry");
        }
        return true;
      }
    } else {
      await _setPremium();
      if (kDebugMode) {
        debugPrint("✅ Non-iOS purchase validated.");
      }
      return true;
    }

    return false;
  }

  // =============================
  // APPLE
  // =============================
  Future<Map<String, dynamic>> _validateAppleReceipt(String receipt) async {
    if (kDebugMode) {
      debugPrint("🍎 Validating Apple receipt...");
    }

    final url = "https://sandbox.itunes.apple.com/verifyReceipt";

    final client = HttpClient();
    final req = await client.postUrl(Uri.parse(url));
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.write(jsonEncode({
      "receipt-data": receipt,
      "password": _appleSharedSecret,
      "exclude-old-transactions": true,
    }));

    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();

    if (kDebugMode) {
      debugPrint("🍎 Apple receipt validated");
    }

    return jsonDecode(body);
  }

  DateTime? _extractAppleExpiry(Map<String, dynamic> data) {
    final list = data["latest_receipt_info"];
    if (list is! List) return null;

    int best = -1;
    for (final item in list) {
      final ms = int.tryParse(item["expires_date_ms"] ?? '');
      if (ms != null && ms > best) best = ms;
    }

    final expiry = best > 0
        ? DateTime.fromMillisecondsSinceEpoch(best, isUtc: true)
        : null;

    if (kDebugMode) {
      debugPrint("📅 Apple expiry date: $expiry");
    }

    return expiry;
  }

  // =============================
  // CACHE UPDATE
  Future<void> _setPremium({DateTime? expiry}) async {
    isPaidVersion.value = true;
    await box.write('isPremiumUser', true);

    if (expiry != null) {
      await box.write('premiumExpiry', expiry.toIso8601String());
      if (kDebugMode) {
        debugPrint("✅ Premium expiry updated in cache: $expiry");
      }
    } else {
      if (kDebugMode) {
        debugPrint("✅ User set to premium. Cache updated.");
      }
    }

    // Force UI update
    update();
  }

  Future<void> _setNotPremium() async {
    isPaidVersion.value = false;
    await box.write('isPremiumUser', false);
    await box.remove('premiumExpiry');
    if (kDebugMode) {
      debugPrint("✅ User set to non-premium.");
    }
    update();
  }

  /// 🔁 Called from PremiumView "Restore" button
  Future<void> iapHelperGetSubscriptionHistory() async {
    if (purchasePending.value) return;

    purchasePending.value = true;
    
    // Safety timeout for restore flow
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = Timer(const Duration(seconds: 45), () {
      if (purchasePending.value) {
        purchasePending.value = false;
        if (kDebugMode) {
          debugPrint("⏰ Restore timeout after 45 seconds - resetting loader");
        }
      }
    });

    try {
      await _validateHistory();
      if (kDebugMode) {
        debugPrint("✅ Subscription history restored.");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [IAP] Restore failed: $e');
      }
    } finally {
      purchasePending.value = false;
      _purchaseTimeoutTimer?.cancel();
    }
  }

  // =============================
  // UI
  // =============================
  void selectPlan(String plan) {
    selectedPlan.value = plan;
    if (kDebugMode) {
      debugPrint("📋 Selected plan: $selectedPlan");
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    _purchaseTimeoutTimer?.cancel();
    _refreshTimer?.cancel();
    FlutterInappPurchase.instance.finalize();
    super.onClose();
    if (kDebugMode) {
      debugPrint("✅ PremiumController cleaned up.");
    }
  }
}