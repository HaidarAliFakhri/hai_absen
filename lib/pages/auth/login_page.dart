import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.access_time_filled, size: 80, color: Colors.blue),

              SizedBox(height: 20),

              Text(
                "Hai Absen",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                "Silakan login untuk melanjutkan",
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              SizedBox(height: 30),

              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: email,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),

                      SizedBox(height: 15),

                      TextField(
                        controller: pass,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),

                      SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: auth.loading
                              ? null
                              : () async {
                                  final success = await auth.login(
                                    email.text.trim(),
                                    pass.text.trim(),
                                  );

                                  if (success) {
                                    Navigator.pushReplacementNamed(context, '/main');

                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Email atau password salah",
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: auth.loading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text("Login", style: TextStyle(fontSize: 16)),
                        ),
                      ),

                      SizedBox(height: 10),

                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          "Belum punya akun? Daftar",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
