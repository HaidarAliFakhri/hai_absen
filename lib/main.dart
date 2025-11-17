import 'package:flutter/material.dart';
import 'package:hai_absen/pages/dashboard_page.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/absen_provider.dart';

import 'pages/auth/login_page.dart';


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
        debugShowCheckedModeBanner: false,
        home: LoginPage(),
        routes: {
          '/dashboard': (_) => DashboardPage(),
        },
      ),
    );
  }
}
