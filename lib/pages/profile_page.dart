import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/shared_prefs.dart';
import '../providers/absen_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  String? _gender;

  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final prov = Provider.of<AbsenProvider>(context, listen: false);
    final p = prov.profile;
    if (p != null) {
      _name.text = p["name"] ?? "";
      _gender = p["jenis_kelamin"];
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickPhoto(AbsenProvider prov) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);

    if (img == null) return;

    final bytes = await File(img.path).readAsBytes();
    final base64Img = "data:image/png;base64,${base64Encode(bytes)}";

    final success = await prov.updatePhoto(base64Img);

    if (success) {
      _toast("Foto berhasil diperbarui");
    } else {
      _toast("Gagal upload foto");
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AbsenProvider>(context);
    final p = prov.profile;

    if (p == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String? photoUrl = p["profile_photo_url"];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Profil Saya"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await LocalStorage.clear();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),

      // BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ===========================
            //           AVATAR
            // ===========================
            Center(
              child: GestureDetector(
                onTap: () => _pickPhoto(prov),
                child: Hero(
                  tag: "profileAvatar",
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===========================
            //          NAME + TAG
            // ===========================
            Text(
              p["name"] ?? "-",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "Batch ${p["batch_ke"] ?? '-'} • ${p["training_title"] ?? '-'}",
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 30),

            // ===========================
            //      GLASS FORM CARD
            // ===========================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white24),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // NAME FIELD
                  TextField(
                    controller: _name,
                    enabled: _editing,
                    decoration: InputDecoration(
                      labelText: "Nama Lengkap",
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  // SAVE / EDIT BUTTON
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _editing
                        ? ElevatedButton.icon(
                            key: const ValueKey("save-btn"),
                            icon: const Icon(Icons.save),
                            label: const Text("Simpan Perubahan"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              final body = {
                                "name": _name.text.trim(),
                                "jenis_kelamin": _gender,
                              };

                              final ok = await prov.updateProfile(body);
                              if (ok) {
                                setState(() => _editing = false);
                                _toast("Profil berhasil diperbarui");
                              } else {
                                _toast("Gagal memperbarui profil");
                              }
                            },
                          )
                        : ElevatedButton.icon(
                            key: const ValueKey("edit-btn"),
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit Profil"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => setState(() => _editing = true),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ===========================
            //        INFO CARD STATIC
            // ===========================
            _infoTile(Icons.email_rounded, "Email", p["email"] ?? "-"),
            _infoTile(Icons.badge, "ID Peserta", p["id"].toString()),
            _infoTile(Icons.people_alt, "Jenis Kelamin", _gender ?? "-"),
            const SizedBox(height: 20),

            Text(
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
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade400),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
