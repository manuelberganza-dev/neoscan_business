import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';

void main() {
  runApp(const ProviderScope(child: NeoscanBusinessApp()));
}

class NeoscanBusinessApp extends ConsumerWidget {
  const NeoscanBusinessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'NeoScan Business',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
