import 'package:flutter/material.dart';
import 'package:hai_absen/pages/auth/register_page.dart';
import 'package:hai_absen/pages/dashboard_page.dart';
import 'package:hai_absen/pages/splash_page.dart';
import 'package:hai_absen/providers/thame_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
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
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // THEME PROVIDER
      ],

      // >>>>>>> FIX: Bungkus MaterialApp dengan Consumer <<<<<<<<
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            // TERAPKAN MODE GELAP / TERANG
            themeMode: themeProv.isDark ? ThemeMode.dark : ThemeMode.light,

            theme: ThemeData(brightness: Brightness.light, useMaterial3: true),

            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
            ),

            home: const SplashPage(),
            routes: {
              '/dashboard': (_) => DashboardPage(),
              '/register': (_) => RegisterPage(),
              '/login': (_) => LoginPage(),
            },
          );
        },
      ),
    );
  }
}
