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

  // jenis kelamin as dropdown L / P
  String gender = "L";

  // batch & training selected id (int)
  int? selectedBatchId;
  int? selectedTrainingId;

  // training options for selected batch
  List<Map<String, dynamic>> trainingOptions = [];

  @override
  void initState() {
    super.initState();

    // fetch batches when opening register page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.fetchBatches().then((ok) {
        // optionally set default batch if any
        if (ok && auth.batches.isNotEmpty) {
          setState(() {
            selectedBatchId = auth.batches.first['id'] as int?;
            // populate trainingOptions from selected batch
            _populateTrainingsForBatch(auth.batches.first);
          });
        }
      });
    });
  }

  void _populateTrainingsForBatch(dynamic batch) {
    trainingOptions = [];
    if (batch != null && batch['trainings'] != null) {
      final list = batch['trainings'] as List<dynamic>;
      trainingOptions = list.map<Map<String, dynamic>>((t) {
        return {
          "id": t['id'],
          "title": t['title'],
        };
      }).toList();
      // set default training id if any
      if (trainingOptions.isNotEmpty) {
        selectedTrainingId = trainingOptions.first['id'] as int?;
      } else {
        selectedTrainingId = null;
      }
    } else {
      trainingOptions = [];
      selectedTrainingId = null;
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(title: const Text("Register"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Name
                TextField(
                  controller: name,
                  decoration: _field("Nama", Icons.person),
                ),
                const SizedBox(height: 12),
                // Email
                TextField(
                  controller: email,
                  decoration: _field("Email", Icons.email),
                ),
                const SizedBox(height: 12),
                // Password
                TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: _field("Password", Icons.lock),
                ),
                const SizedBox(height: 12),
                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: _fieldDecoration("Jenis Kelamin"),
                  items: const [
                    DropdownMenuItem(value: "L", child: Text("Laki-laki")),
                    DropdownMenuItem(value: "P", child: Text("Perempuan")),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => gender = v);
                  },
                ),
                const SizedBox(height: 12),
                // Batch Dropdown
                auth.loadingBatches
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        value: selectedBatchId,
                        decoration: _fieldDecoration("Pilih Batch"),
                        items: auth.batches.map<DropdownMenuItem<int>>((b) {
                          final id = b['id'] as int;
                          final label = b['batch_ke'] ?? "Batch $id";
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text("Batch ${label.toString()}"),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedBatchId = v;
                            // populate trainings for selected batch
                            final batch = auth.batches.firstWhere(
                                (e) => e['id'] == v,
                                orElse: () => null);
                            _populateTrainingsForBatch(batch);
                          });
                        },
                      ),
                const SizedBox(height: 12),
                // Training Dropdown (dependent on batch)
                if (trainingOptions.isEmpty)
                  // if empty try load global trainings (fallback)
                  auth.loadingTrainings
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () async {
                            final ok = await auth.fetchTrainings();
                            if (ok) {
                              setState(() {
                                trainingOptions = auth.trainings
                                    .map<Map<String, dynamic>>((t) => {
                                          "id": t['id'],
                                          "title": t['title'],
                                        })
                                    .toList();
                                if (trainingOptions.isNotEmpty) {
                                  selectedTrainingId =
                                      trainingOptions.first['id'] as int?;
                                }
                              });
                            } else {
                              _toast("Gagal mengambil daftar training");
                            }
                          },
                          child: const Text("Muat daftar training"),
                        )
                else
                  DropdownButtonFormField<int>(
  value: selectedTrainingId,
  decoration: _fieldDecoration("Pilih Pelatihan"),
  isExpanded: true, // <- WAJIB agar dropdown tidak overflow
  items: trainingOptions.map<DropdownMenuItem<int>>((t) {
    return DropdownMenuItem<int>(
      value: t['id'] as int,
      child: Row(
        children: [
          Expanded(
            child: Text(
              t['title'].toString(),
              overflow: TextOverflow.ellipsis,   // <- Mencegah overflow
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }).toList(),
  onChanged: (v) {
    setState(() {
      selectedTrainingId = v;
    });
  },
),


                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: auth.loading
                        ? null
                        : () async {
                            // validation
                            if (name.text.trim().isEmpty ||
                                email.text.trim().isEmpty ||
                                pass.text.trim().isEmpty) {
                              _toast("Lengkapi semua field penting");
                              return;
                            }
                            if (selectedBatchId == null ||
                                selectedTrainingId == null) {
                              _toast("Pilih batch dan pelatihan");
                              return;
                            }

                            final data = {
                              "name": name.text.trim(),
                              "email": email.text.trim(),
                              "password": pass.text.trim(),
                              "jenis_kelamin": gender,
                              "profile_photo": "",
                              "batch_id": selectedBatchId,
                              "training_id": selectedTrainingId,
                            };

                            final result = await auth.register(data);

                            if (result["status"] == 200 ||
                                result["status"] == 201) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Berhasil daftar")),
                              );
                              // sesuai pilihan: after register go back to login
                              Navigator.pop(context);
                            } else {
                              final msg = result["body"] is Map
                                  ? (result["body"]["message"] ??
                                      "Registrasi gagal")
                                  : "Registrasi gagal";
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                ),
                              );
                            }
                          },
                    child: auth.loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Daftar", style: TextStyle(fontSize: 16)),
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

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
