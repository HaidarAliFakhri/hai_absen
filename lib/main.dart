import 'package:flutter/material.dart';
import 'package:hai_absen/pages/auth/main_navigation.dart';
import 'package:hai_absen/pages/auth/register_page.dart';
import 'package:hai_absen/pages/splash_page.dart';
import 'package:hai_absen/providers/thame_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'pages/auth/login_page.dart';
import 'providers/absen_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AbsenProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],

      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            themeMode: themeProv.isDark ? ThemeMode.dark : ThemeMode.light,

            theme: ThemeData(brightness: Brightness.light, useMaterial3: true),

            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
            ),

            // Mulai dari splash
            home: const SplashPage(),

            routes: {
              // NOTE: agar semua navigasi yang menuju "dashboard" menampilkan
              // MainNavigation (dengan bottom nav) — sehingga bottom nav tidak hilang.
              '/dashboard': (_) => const MainNavigation(),
              '/main': (_) => const MainNavigation(),

              // ROUTE REGISTER & LOGIN
              '/register': (_) => const RegisterPage(),
              '/login': (_) => LoginPage(),
            },
          );
        },
      ),
    );
  }
}
