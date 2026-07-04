import "package:flutter/material.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'homepage.dart';
import 'create_event_page.dart';
import 'profile_page.dart';
import '../providers/event_provider.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentIndexAsync = ref.watch(mainPageIndexProvider);
    final currentIndex = currentIndexAsync.value ?? _currentIndex;
    final List<Widget> pages = [
      const HomePage(),
      const CreateEventPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(mainPageIndexProvider.notifier).setIndex(index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add), label: 'Create Event'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
