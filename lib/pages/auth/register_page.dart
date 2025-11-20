import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();

  String gender = "L";
  int? selectedBatchId;
  int? selectedTrainingId;
  List<Map<String, dynamic>> trainingOptions = [];

  late AnimationController animCtrl;
  late Animation<double> iconScale;

  @override
  void initState() {
    super.initState();

    animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    iconScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animCtrl, curve: Curves.easeOutBack));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.fetchBatches().then((ok) {
        if (ok && auth.batches.isNotEmpty) {
          setState(() {
            selectedBatchId = auth.batches.first['id'];
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
      trainingOptions = list
          .map<Map<String, dynamic>>(
            (t) => {"id": t["id"], "title": t["title"]},
          )
          .toList();

      selectedTrainingId = trainingOptions.isNotEmpty
          ? trainingOptions.first["id"]
          : null;
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // ===========================
          //       CURVED WAVE HEADER
          // ===========================
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: ScaleTransition(
                    scale: iconScale,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_alt_1,
                          size: 70,
                          color: Colors.white,
                        ),

                        const Text(
                          "Registrasi Akun",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ===========================
          //           FORM
          // ===========================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _inputField("Nama", Icons.person, controller: name),
                        _gap(),
                        _inputField("Email", Icons.email, controller: email),
                        _gap(),
                        _inputField(
                          "Password",
                          Icons.lock,
                          controller: pass,
                          obscure: true,
                        ),
                        _gap(),

                        // Gender
                        DropdownButtonFormField<String>(
                          initialValue: gender,
                          decoration: _dropdownField("Jenis Kelamin"),
                          items: const [
                            DropdownMenuItem(
                              value: "L",
                              child: Text("Laki-laki"),
                            ),
                            DropdownMenuItem(
                              value: "P",
                              child: Text("Perempuan"),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) gender = v;
                            setState(() {});
                          },
                        ),
                        _gap(),

                        // Batch dropdown
                        auth.loadingBatches
                            ? const CircularProgressIndicator()
                            : DropdownButtonFormField<int>(
                                initialValue: selectedBatchId,
                                decoration: _dropdownField("Pilih Batch"),
                                items: auth.batches.map<DropdownMenuItem<int>>((
                                  b,
                                ) {
                                  return DropdownMenuItem(
                                    value: b["id"],
                                    child: Text("Batch ${b['batch_ke']}"),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  selectedBatchId = v;
                                  final batch = auth.batches.firstWhere(
                                    (e) => e["id"] == v,
                                    orElse: () => null,
                                  );
                                  _populateTrainingsForBatch(batch);
                                  setState(() {});
                                },
                              ),

                        _gap(),

                        // Training
                        DropdownButtonFormField<int>(
                          initialValue: selectedTrainingId,
                          isExpanded: true, // <-- WAJIB untuk mencegah overflow
                          decoration: _dropdownField("Pilih Pelatihan"),
                          items: trainingOptions.map<DropdownMenuItem<int>>((
                            t,
                          ) {
                            return DropdownMenuItem(
                              value: t["id"],
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t["title"],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: auth.loading
                          ? null
                          : () async {
                              if (name.text.isEmpty ||
                                  email.text.isEmpty ||
                                  pass.text.isEmpty) {
                                _toast("Lengkapi semua field");
                                return;
                              }

                              if (selectedBatchId == null ||
                                  selectedTrainingId == null) {
                                _toast("Pilih Batch dan Pelatihan");
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
                                _toast("Berhasil daftar");
                                Navigator.pop(context);
                              } else {
                                final msg =
                                    result["body"]?["message"] ??
                                    "Registrasi gagal";
                                _toast(msg);
                              }
                            },
                      child: auth.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Daftar",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Sudah punya akun? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // kembali ke login page
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Create by: Haidar Ali Fakhri",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    IconData icon, {
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 14);

  InputDecoration _dropdownField(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

// ---------------------------
// CUSTOM WAVE CLIPPER
// ---------------------------
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 60);

    p.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 40,
    );

    p.quadraticBezierTo(
      size.width * 0.75,
      size.height - 80,
      size.width,
      size.height - 20,
    );

    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
