import 'package:flutter/material.dart';
import 'package:geridonusum/pages/camera_page.dart';
import 'package:geridonusum/pages/profil_page.dart';
import 'home_page.dart';
import 'map_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    MapPage(),
    CameraPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Anasayfa'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Konteyner'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Ekle'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
