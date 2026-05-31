import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/offline/connectivity_status.dart';
import 'core/routing/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/offline_status_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: NeoscanBusinessApp()));
}

class NeoscanBusinessApp extends ConsumerWidget {
  const NeoscanBusinessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(offlineSyncBootstrapProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'NeoScan Business',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return OfflineStatusBanner(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
