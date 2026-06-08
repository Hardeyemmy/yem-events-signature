import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/Pages/login.dart';
import '../features/auth/presentation/Pages/homepage.dart';
import '../features/auth/presentation/providers/auth_providers.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Events Signature Project',
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      home: authState.when(
        data: (user) => user != null ? const HomePage() : const Login(),
        error: (e, _) =>
            Scaffold(body: Center(child: Text('An error occurred'))),
        loading: () =>
            Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
