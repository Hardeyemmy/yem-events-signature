import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yem_events_signature/features/auth/presentation/Pages/login.dart';
import 'package:yem_events_signature/features/auth/presentation/Pages/homepage.dart';
import 'package:yem_events_signature/features/auth/presentation/Pages/main_page.dart';
import 'package:yem_events_signature/features/auth/presentation/providers/auth_providers.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Events Signature Project',
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      home: authState.when(
        data: (user) => user != null ? const MainPage() : const Login(),
        error: (e, _) => const Login(),
        loading: () =>
            Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
