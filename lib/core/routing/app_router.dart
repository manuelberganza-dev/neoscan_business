import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_viewmodel.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/inventory/models/inventory_item.dart';
import '../../features/inventory/ui/adjustment_screen.dart';
import '../../features/inventory/ui/inventory_screen.dart';
import '../../features/inventory/ui/transfer_screen.dart';
import '../../features/more/ui/more_screen.dart';
import '../../features/notifications/ui/notifications_screen.dart';
import '../../features/pos/ui/close_cash_screen.dart';
import '../../features/pos/ui/open_cash_screen.dart';
import '../../features/pos/ui/payment_screen.dart';
import '../../features/pos/ui/pos_screen.dart';
import '../../features/scanner/ui/barcode_scanner_screen.dart';
import '../../features/scanner/ui/ocr_scanner_screen.dart';
import '../../shared/theme/app_theme.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefresh(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final location = state.matchedLocation;

      if (authState.isLoading) return null;

      final isAuthenticated = authState.value?.isAuthenticated ?? false;
      final isLoginRoute = location == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (ctx, _) => const LoginScreen()),
      GoRoute(
        path: '/inventory/adjustment',
        builder: (ctx, state) =>
            AdjustmentScreen(preselectedItem: state.extra as InventoryItem?),
      ),
      GoRoute(
        path: '/inventory/transfer',
        builder: (ctx, _) => const TransferScreen(),
      ),
      GoRoute(
        path: '/pos/open-cash',
        builder: (ctx, _) => const OpenCashScreen(),
      ),
      GoRoute(path: '/pos/payment', builder: (ctx, _) => const PaymentScreen()),
      GoRoute(
        path: '/pos/close-cash',
        builder: (ctx, _) => const CloseCashScreen(),
      ),
      GoRoute(
        path: '/scanner/barcode',
        builder: (ctx, _) => const BarcodeScannerScreen(),
      ),
      GoRoute(
        path: '/scanner/ocr',
        builder: (ctx, _) => const OcrScannerScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (ctx, _) => const NotificationsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            _MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', builder: (ctx, _) => const HomeScreen()),
          GoRoute(path: '/pos', builder: (ctx, _) => const PosScreen()),
          GoRoute(
            path: '/inventory',
            builder: (ctx, _) => const InventoryScreen(),
          ),
          GoRoute(path: '/more', builder: (ctx, _) => const MoreScreen()),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authViewModelProvider, (prev, next) => notifyListeners());
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell({required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/pos')) return 1;
    if (location.startsWith('/inventory')) return 2;
    if (location.startsWith('/more')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          elevation: 0,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go('/home');
              case 1:
                context.go('/pos');
              case 2:
                context.go('/inventory');
              case 3:
                context.go('/more');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_outlined),
              activeIcon: Icon(Icons.point_of_sale_rounded),
              label: 'POS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Inventario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              label: 'Más',
            ),
          ],
        ),
      ),
    );
  }
}
