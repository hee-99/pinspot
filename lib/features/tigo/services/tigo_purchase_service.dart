import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../data/tigo_items.dart';
import '../models/tigo_model.dart';
import 'tigo_service.dart';

/// 티고 프리미엄 아이템의 실제 스토어 결제(Google Play Billing)를 담당.
///
/// Play Console(수익 창출 > 제품 > 인앱 상품)에 [kTigoPremiumProductIds]와
/// 동일한 상품 ID가 등록되어 있어야 [productFor]가 값을 찾고 실제 결제가 가능해짐.
/// 아직 등록 전이거나 스토어를 쓸 수 없는 환경(에뮬레이터 등)에서는
/// [productFor]가 null을 반환하므로, 호출부(도감 화면)에서 개발용 폴백으로 처리함.
class TigoPurchaseService extends ChangeNotifier {
  static final instance = TigoPurchaseService._();
  TigoPurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Map<String, ProductDetails> _products = {};
  bool _storeAvailable = false;
  String? _lastError;

  bool get storeAvailable => _storeAvailable;
  String? get lastError => _lastError;

  Future<void> init() async {
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (Object e) {
      _lastError = '$e';
      notifyListeners();
    });

    _storeAvailable = await _iap.isAvailable();
    if (_storeAvailable && kTigoPremiumProductIds.isNotEmpty) {
      final response = await _iap.queryProductDetails(kTigoPremiumProductIds.toSet());
      _products = {for (final p in response.productDetails) p.id: p};
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// 스토어에서 조회된 상품 정보(가격 표시 등). 미등록/미조회 상태면 null.
  ProductDetails? productFor(TigoItem item) {
    final id = item.productId;
    if (id == null) return null;
    return _products[id];
  }

  /// 실제 스토어 결제 창을 띄운다. 결과 반영은 purchaseStream 콜백(비동기)에서 처리됨.
  /// 상품이 스토어에 없으면(폴백 필요) false를 반환.
  Future<bool> buy(TigoItem item) async {
    final product = productFor(item);
    if (product == null) return false;
    final param = PurchaseParam(productDetails: product);
    // 스킨/모자 등은 한 번 사면 계속 쓰는 비소모성(non-consumable) 상품.
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // TODO: 프로덕션 출시 전에는 purchase.verificationData로 서버 영수증 검증을 먼저 붙일 것.
          final item = tigoItemByProductId(purchase.productID);
          if (item != null) {
            TigoService.instance.purchaseItem(item.id);
          }
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          _lastError = purchase.error?.message;
          notifyListeners();
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
          break;
      }
    }
  }
}
