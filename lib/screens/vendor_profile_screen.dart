import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vendor_support_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  final String vendorId;

  const VendorProfileScreen({
    super.key,
    required this.vendorId,
  });

  @override
  State<VendorProfileScreen> createState() =>
      _VendorProfileScreenState();
}

class _VendorProfileScreenState
    extends State<VendorProfileScreen> {
  final nameController =
      TextEditingController();

  final fssaiController =
      TextEditingController();

  // ✅ GST
  final gstController =
      TextEditingController();

  final addressController =
      TextEditingController();

  final cityController =
      TextEditingController();

  // ✅ PHONE
  final phoneController =
      TextEditingController();

  bool isActive = true;

  // ✅ OPEN/CLOSE
  bool isCurrentlyOpen = true;

  String imageUrl = "";

  XFile? imageFile;

  // ─────────────────────────────────────
  // Pick Image
  // ─────────────────────────────────────
  Future<void> pickImage() async {
    final picked = await ImagePicker()
        .pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        imageFile = picked;
      });
    }
  }

  // ─────────────────────────────────────
  // Upload Image
  // ─────────────────────────────────────
  Future<String> uploadImage(
    XFile file,
  ) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child(
          'vendor_images/${DateTime.now().millisecondsSinceEpoch}.png',
        );

    final bytes =
        await file.readAsBytes();

    await ref.putData(bytes);

    return await ref.getDownloadURL();
  }

  // ─────────────────────────────────────
  // Load Data
  // ─────────────────────────────────────
  Future<void> loadData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(widget.vendorId)
            .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    setState(() {
      // ─────────────────────────────
      // IDENTITY
      // ─────────────────────────────
      final identity =
          data['identity']
              as Map<String, dynamic>?;

      nameController.text =
          identity?['business_name']
                  ?.toString() ??
              data['businessName']
                  ?.toString() ??
              "";

      fssaiController.text =
          identity?['fssai']
                  ?.toString() ??
              data['fssaiLicense']
                  ?.toString() ??
              "";

      // ✅ GST LOAD
      gstController.text =
          data['gstin']
                  ?.toString() ??
              "";

      // ─────────────────────────────
      // IMAGE
      // ─────────────────────────────
      imageUrl =
          data['imageUrl']
                  ?.toString() ??
              identity?['imageUrl']
                  ?.toString() ??
              "";

      // ─────────────────────────────
      // PHONE
      // ─────────────────────────────
      phoneController.text =
          data['phoneNumber']
                  ?.toString() ??
              "";

      // ─────────────────────────────
      // LOCATION
      // ─────────────────────────────
      final location =
          data['location']
              as Map<String, dynamic>?;

      addressController.text =
          location?['full_address']
                  ?.toString() ??
              data['fullAddress']
                  ?.toString() ??
              "";

      cityController.text =
          location?['city']
                  ?.toString() ??
              data['city']
                  ?.toString() ??
              "";

      // ─────────────────────────────
      // OPERATIONS
      // ─────────────────────────────
      final operations =
          data['operations']
              as Map<String, dynamic>?;

      isActive =
          operations?['is_active'] ??
              data['isActive'] ??
              true;

      isCurrentlyOpen =
          operations?[
                  'is_currently_open'] ??
              data['isCurrentlyOpen'] ??
              true;
    });
  }

  // ─────────────────────────────────────
  // Save Data
  // ─────────────────────────────────────
  Future<void> saveData() async {
    try {
      String finalImage = imageUrl;

      // ─────────────────────────────
      // Upload New Image
      // ─────────────────────────────
      if (imageFile != null) {
        finalImage =
            await uploadImage(
          imageFile!,
        );
      }

      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.vendorId)
          .set({
        // ─────────────────────────────
        // ROOT LEVEL
        // ─────────────────────────────
        "businessName":
            nameController.text.trim(),

        "category":
            "restaurant",

        "fullAddress":
            addressController.text.trim(),

        "city":
            cityController.text.trim(),

        "imageUrl": finalImage,

        "phoneNumber":
            phoneController.text.trim(),

        "isActive":
            isActive,

        "isCurrentlyOpen":
            isCurrentlyOpen,

        "fssaiLicense":
            fssaiController.text.trim(),

        // ✅ GST SAVE
        "gstin":
            gstController.text.trim(),

        // ─────────────────────────────
        // IDENTITY MAP
        // FIXED ✅
        // ─────────────────────────────
        "identity": {
          "business_name":
              nameController.text
                  .trim(),

          "fssai":
              fssaiController.text
                  .trim(),

          "imageUrl":
              finalImage,
        },

        // ─────────────────────────────
        // LOCATION MAP
        // FIXED ✅
        // ─────────────────────────────
        "location": {
          "full_address":
              addressController.text
                  .trim(),

          "city":
              cityController.text
                  .trim(),
        },

        // ─────────────────────────────
        // OPERATIONS MAP
        // FIXED ✅
        // ─────────────────────────────
        "operations": {
          "is_active":
              isActive,

          "is_currently_open":
              isCurrentlyOpen,

          "is_accepting_orders":
              true,
        },

        // ─────────────────────────────
        // UPDATED TIME
        // ─────────────────────────────
        "updatedAt":
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ─────────────────────────────
      // REMOVE OLD BROKEN FIELDS
      // VERY IMPORTANT ✅
      // ─────────────────────────────
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.vendorId)
          .update({
        "identity.business_name":
            FieldValue.delete(),

        "identity.fssai":
            FieldValue.delete(),

        "identity.imageUrl":
            FieldValue.delete(),

        "location.full_address":
            FieldValue.delete(),

        "location.city":
            FieldValue.delete(),

        "operations.is_active":
            FieldValue.delete(),

        "operations.is_currently_open":
            FieldValue.delete(),
      });

      // ─────────────────────────────
      // RELOAD DATA
      // ─────────────────────────────
      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Profile Updated"),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    nameController.dispose();

    fssaiController.dispose();

    // ✅ GST
    gstController.dispose();

    addressController.dispose();

    cityController.dispose();

    phoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Vendor Profile"),
        backgroundColor:
            const Color(0xFFFF5A5F),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─────────────────────────
            // LOGO
            // ─────────────────────────
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    imageFile != null
                        ? FileImage(
                            File(
                              imageFile!
                                  .path,
                            ),
                          )
                        : imageUrl
                                .isNotEmpty
                            ? NetworkImage(
                                imageUrl,
                              )
                            : null,
                child:
                    imageUrl.isEmpty &&
                            imageFile ==
                                null
                        ? const Icon(
                            Icons.camera_alt,
                          )
                        : null,
              ),
            ),

            const SizedBox(height: 20),

            // ─────────────────────────
            // NAME
            // ─────────────────────────
            TextField(
              controller:
                  nameController,
              decoration:
                  const InputDecoration(
                labelText:
                    "Restaurant Name",
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // ─────────────────────────
            // FSSAI
            // ─────────────────────────
            TextField(
              controller:
                  fssaiController,
              decoration:
                  const InputDecoration(
                labelText:
                    "FSSAI License",
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // ─────────────────────────
            // GST NUMBER
            // ─────────────────────────
            TextField(
              controller:
                  gstController,
              decoration:
                  const InputDecoration(
                labelText:
                    "GST Number",
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // ─────────────────────────
            // PHONE
            // ─────────────────────────
            TextField(
              controller:
                  phoneController,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                labelText:
                    "Phone Number",
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // ─────────────────────────
            // ADDRESS
            // ─────────────────────────
            TextField(
              controller:
                  addressController,
              maxLines: 2,
              decoration:
                  const InputDecoration(
                labelText:
                    "Full Address",
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // ─────────────────────────
            // CITY
            // ─────────────────────────
            TextField(
              controller:
                  cityController,
              decoration:
                  const InputDecoration(
                labelText: "City",
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ─────────────────────────
            // ACTIVE / INACTIVE
            // ─────────────────────────
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Text(
                  isActive
                      ? "🟢 Vendor Active"
                      : "🔴 Vendor Disabled",
                  style:
                      const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (val) {
                    setState(() {
                      isActive = val;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ─────────────────────────
            // OPEN/CLOSE
            // ─────────────────────────
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Text(
                  isCurrentlyOpen
                      ? "🟢 Restaurant Open"
                      : "🔴 Restaurant Closed",
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                Switch(
                  value:
                      isCurrentlyOpen,
                  activeColor:
                      Colors.green,
                  onChanged: (val) {
                    setState(() {
                      isCurrentlyOpen =
                          val;
                    });
                  },
                ),
              ],
            ),
            
            const Divider(),

            ListTile(
  leading: const Icon(
    Icons.support_agent,
    color: Color(0xFFFF5A5F),
  ),

  title: const Text(
    "Support",
  ),

  subtitle: const Text(
    "Contact Biteo Support",
  ),

  trailing: const Icon(
    Icons.arrow_forward_ios,
    size: 16,
  ),

  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VendorSupportScreen(
          vendorId:
              widget.vendorId,
        ),
      ),
    );
  },
),

            const SizedBox(height: 24),



            // ─────────────────────────
            // SAVE BUTTON
            // ─────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveData,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFFFF5A5F,
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  "Save Changes",
                ),
              ),
            ),

            const SizedBox(height: 14),
            
            // ─────────────────────────
// LOGOUT
// ─────────────────────────
SizedBox(
  width: double.infinity,

  child: OutlinedButton.icon(
    onPressed: () async {
      await FirebaseAuth.instance
          .signOut();

      if (!context.mounted) {
        return;
      }

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    },

    icon: const Icon(
      Icons.logout,
      color: Colors.red,
    ),

    label: const Text(
      "Logout",
      style: TextStyle(
        color: Colors.red,
      ),
    ),
  ),
),

const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}