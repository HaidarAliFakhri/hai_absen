import 'package:flutter/material.dart';
import 'package:hai_absen/pages/Riwayat_list_page.dart';
import 'package:hai_absen/pages/dashboard_page.dart';
import 'package:hai_absen/pages/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    // gunakan DashboardPage() biasa; jika Anda ingin Dashboard tanpa AppBar,
    // tambahkan parameter opsional di DashboardPage kemudian ubah di sini.
    const DashboardPage(),
    const DetailListPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // agar floating navbar smooth
      body: SafeArea(top: false, child: _pages[_currentIndex]),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: PhysicalModel(
          color: Theme.of(context).cardColor,
          elevation: 8,
          borderRadius: BorderRadius.circular(30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              elevation: 0,
              backgroundColor: Theme.of(context).cardColor,
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_rounded),
                  label: "Riwayat",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: "Profil",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
