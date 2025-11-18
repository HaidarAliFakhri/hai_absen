import 'package:flutter/material.dart';
import 'package:hai_absen/pages/auth/register_page.dart';
import 'package:hai_absen/pages/dashboard_page.dart';
import 'package:hai_absen/pages/splash_page.dart';
import 'package:provider/provider.dart';

import 'pages/auth/login_page.dart';
import 'providers/absen_provider.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AbsenProvider()), // WAJIB
      ],
      child: MaterialApp(
        themeMode: ThemeMode.system, // otomatis mengikuti device
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: SplashPage(),
        routes: {
          '/dashboard': (_) => DashboardPage(),
          '/register': (context) => RegisterPage(),
          '/login': (context) => LoginPage(),
        },
      ),
    );
  }
}
