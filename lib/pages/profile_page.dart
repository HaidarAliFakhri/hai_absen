import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/absen_provider.dart';
import '../core/shared_prefs.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final prov = Provider.of<AbsenProvider>(context, listen: false);
    final p = prov.profile;
    if (p != null) {
      _name.text = p["name"] ?? "";
      _phone.text = p["phone"] ?? "";
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickPhoto(AbsenProvider prov) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);

    if (img == null) return;

    final success = await prov.uploadPhoto(File(img.path));

    if (success) _toast("Foto berhasil diperbarui");
    else _toast("Gagal upload foto");
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AbsenProvider>(context);
    final p = prov.profile;

    if (p == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              LocalStorage.saveToken("");
              Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            
            // FOTO PROFIL (HERO)
            Center(
              child: GestureDetector(
                onTap: () => _pickPhoto(prov),
                child: Hero(
                  tag: "profile-photo",
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: p["profile_photo_url"] != null
                        ? NetworkImage(p["profile_photo_url"])
                        : null,
                    child: p["profile_photo_url"] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              p["name"] ?? "-",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("Batch ${p["batch_ke"] ?? '-'} • ${p["training_title"] ?? '-'}"),

            const SizedBox(height: 30),

            // FORM EDIT
            TextField(
              controller: _name,
              enabled: _editing,
              decoration: const InputDecoration(
                labelText: "Nama Lengkap",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _phone,
              enabled: _editing,
              decoration: const InputDecoration(
                labelText: "Nomor HP",
              ),
            ),

            const SizedBox(height: 25),

            // BUTTON UBAH DATA
            _editing
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Simpan Perubahan"),
                    onPressed: () async {
                      final body = {
                        "name": _name.text.trim(),
                        "phone": _phone.text.trim(),
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
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profil"),
                    onPressed: () => setState(() => _editing = true),
                  ),

            const SizedBox(height: 40),

            // INFO LAIN
            Card(
              child: ListTile(
                leading: const Icon(Icons.info),
                title: const Text("Email"),
                subtitle: Text(p["email"] ?? "-"),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.badge),
                title: const Text("ID Peserta"),
                subtitle: Text(p["id"].toString()),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
