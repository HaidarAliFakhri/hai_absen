import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final gender = TextEditingController(text: "L");
  final batch = TextEditingController(text: "1");
  final training = TextEditingController(text: "1");

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(title: Text("Register"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: _field("Nama", Icons.person),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: email,
                  decoration: _field("Email", Icons.email),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: _field("Password", Icons.lock),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: gender,
                  decoration: _field("Jenis Kelamin (L/P)", Icons.wc),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: batch,
                  decoration: _field("Batch ID", Icons.confirmation_number),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: training,
                  decoration: _field("Training ID", Icons.class_),
                ),

                SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: auth.loading
                        ? null
                        : () async {
                            final data = {
                              "name": name.text.trim(),
                              "email": email.text.trim(),
                              "password": pass.text.trim(),
                              "jenis_kelamin": gender.text.trim(),
                              "profile_photo": "",
                              "batch_id": int.parse(batch.text),
                              "training_id": int.parse(training.text),
                            };

                            final result = await auth.register(data);

                            if (result["status"] == 200 ||
                                result["status"] == 201) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Berhasil daftar")),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result["body"]["message"] ??
                                        "Registrasi gagal",
                                  ),
                                ),
                              );
                            }
                          },
                    child: auth.loading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Daftar", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _field(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
