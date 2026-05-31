import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/cart_item.dart';
import 'models/cash_session.dart';
import 'models/product.dart';
import 'models/sale.dart';
import 'pos_repository.dart';

// ── Cash session ─────────────────────────────────────────────────────────────

final cashSessionProvider =
    AsyncNotifierProvider<CashSessionViewModel, CashSession?>(
      CashSessionViewModel.new,
    );

class CashSessionViewModel extends AsyncNotifier<CashSession?> {
  @override
  Future<CashSession?> build() =>
      ref.read(posRepositoryProvider).getActiveSession();

  Future<void> open(double initialAmount, {String? notes}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(posRepositoryProvider)
          .openSession(initialAmount: initialAmount, notes: notes),
    );
  }

  Future<CashSession?> close({String? notes}) async {
    final session = state.value;
    if (session == null) return null;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(posRepositoryProvider)
          .closeSession(session.id, notes: notes),
    );
    state = const AsyncData(null);
    return result.value;
  }
}

// ── Cart ──────────────────────────────────────────────────────────────────────

class CartState {
  final List<CartItem> items;
  final bool isProcessing;
  final String? error;

  const CartState({
    this.items = const [],
    this.isProcessing = false,
    this.error,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  double get tax => subtotal * 0.13;
  double get total => subtotal + tax;

  CartState copyWith({
    List<CartItem>? items,
    bool? isProcessing,
    String? error,
  }) => CartState(
    items: items ?? this.items,
    isProcessing: isProcessing ?? this.isProcessing,
    error: error,
  );
}

final cartProvider = NotifierProvider<CartViewModel, CartState>(
  CartViewModel.new,
);

class CartViewModel extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addProduct(Product product, int quantity) {
    final existing = state.items.indexWhere((i) => i.product.id == product.id);
    if (existing >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[existing] = CartItem(
        product: product,
        quantity: state.items[existing].quantity + quantity,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(product: product, quantity: quantity),
        ],
      );
    }
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = state.copyWith(
      items: state.items
          .map(
            (i) =>
                i.product.id == productId ? i.copyWith(quantity: quantity) : i,
          )
          .toList(),
    );
  }

  void removeItem(int productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void clear() => state = const CartState();

  Future<bool> processSale({
    required int cashSessionId,
    required List<SalePayment> payments,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      await ref
          .read(posRepositoryProvider)
          .processSale(
            SaleRequest(
              cashSessionId: cashSessionId,
              items: state.items,
              payments: payments,
            ),
          );
      state = const CartState();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

// ── Scanner helper ────────────────────────────────────────────────────────────

final scannerLoadingProvider = NotifierProvider<ScannerLoadingViewModel, bool>(
  ScannerLoadingViewModel.new,
);

class ScannerLoadingViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool value) {
    state = value;
  }
}

Future<Product?> lookupBarcode(WidgetRef ref, String barcode) async {
  ref.read(scannerLoadingProvider.notifier).setLoading(true);
  try {
    return await ref.read(posRepositoryProvider).scanProduct(barcode);
  } catch (_) {
    return null;
  } finally {
    ref.read(scannerLoadingProvider.notifier).setLoading(false);
  }
}
