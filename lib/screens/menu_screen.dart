import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../utils/formatters.dart';
import 'orders_screen.dart';

class MenuScreen extends StatefulWidget {
  final String vendorId;

  const MenuScreen({
    super.key,
    required this.vendorId,
  });

  @override
  State<MenuScreen> createState() =>
      _MenuScreenState();
}

class _MenuScreenState
    extends State<MenuScreen> {
  final nameController =
      TextEditingController();

  final priceController =
      TextEditingController();

  final categoryController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  final searchController =
    TextEditingController();

String searchQuery = "";   

  XFile? imageFile;

  bool isVeg = true;
  bool isRecommended = false;

  int quantity = 10;

  bool isLoading = false;

  // ─────────────────────────────────────
  // PICK IMAGE
  // ─────────────────────────────────────
  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        imageFile = picked;
      });
    }
  }

  // ─────────────────────────────────────
  // UPLOAD IMAGE
  // ─────────────────────────────────────
  Future<String> uploadImage(
    XFile file,
  ) async {
    final ref =
        FirebaseStorage.instance
            .ref()
            .child(
              'menu_images/${DateTime.now().millisecondsSinceEpoch}.png',
            );

    final bytes =
        await file.readAsBytes();

    await ref.putData(bytes);

    return await ref.getDownloadURL();
  }

  // ─────────────────────────────────────
  // ADD ITEM
  // ─────────────────────────────────────
  Future<void> addItem() async {
    try {
      if (nameController.text
              .trim()
              .isEmpty ||
          priceController.text
              .trim()
              .isEmpty) {
        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Fill required fields",
            ),
          ),
        );

        return;
      }

      setState(() {
        isLoading = true;
      });

      String imageUrl = "";

      if (imageFile != null) {
        imageUrl =
            await uploadImage(
          imageFile!,
        );
      }

      final price =
          double.tryParse(
                priceController.text
                    .trim(),
              ) ??
              0;

      await FirebaseFirestore
          .instance
          .collection('vendors')
          .doc(widget.vendorId)
          .collection('menu')
          .add({
        // ✅ OLD SUPPORT
        "name":
            nameController.text
                .trim(),

        "price_paise":
            (price * 100).toInt(),

        "category":
            categoryController.text
                .trim(),

        "description":
            descriptionController
                .text
                .trim(),

        "image_url": imageUrl,

        "is_available": quantity > 0,

        "available_quantity":
         quantity,

        "is_veg": isVeg,

        "is_recommended":
         isRecommended,

        "rating": 0,

        "total_orders": 0,

        // ✅ NEW SUPPORT
        "createdAt":
            FieldValue
                .serverTimestamp(),

        "vendorId":
            widget.vendorId,
      });

      nameController.clear();

      priceController.clear();

      categoryController.clear();

      descriptionController.clear();

      setState(() {
  imageFile = null;

  isVeg = true;

  isRecommended = false;

  quantity = 10;
});

      ScaffoldMessenger.of(
              context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Item Added"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
              context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────
  // EDIT DIALOG
  // ─────────────────────────────────────
  void showEditDialog(
    BuildContext context,
    String id,
    QueryDocumentSnapshot data,
  ) {
    final map =
        data.data()
            as Map<String, dynamic>;

    final nameCtrl =
        TextEditingController(
      text: map['name'] ?? "",
    );

    final priceCtrl =
        TextEditingController(
      text:
          (((map['price_paise'] ??
                              0)
                          as num)
                      .toDouble() /
                  100)
              .toStringAsFixed(0),
    );

    final categoryCtrl =
        TextEditingController(
      text:
          map['category'] ?? "",
    );

    final descriptionCtrl =
        TextEditingController(
      text:
          map['description'] ??
              "",
    );

    bool editVeg =
        map.containsKey(
                  'is_veg',
                )
            ? map['is_veg'] ==
                true
            : true;

    showDialog(
      context: context,
      builder: (_) =>
          StatefulBuilder(
        builder: (
          context,
          setState,
        ) {
          return AlertDialog(
            title:
                const Text(
              "Edit Item",
            ),

            content:
                SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        nameCtrl,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Item Name",
                    ),
                  ),

                  TextField(
                    controller:
                        priceCtrl,
                    keyboardType:
                        TextInputType
                            .number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Price",
                    ),
                  ),

                  TextField(
                    controller:
                        categoryCtrl,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Category",
                    ),
                  ),

                  TextField(
                    controller:
                        descriptionCtrl,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Description",
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // ✅ VEG / NON VEG
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        editVeg
                            ? "🥦 Veg"
                            : "🍗 Non-Veg",
                      ),

                      Switch(
                        value:
                            editVeg,
                        onChanged:
                            (val) {
                          setState(() {
                            editVeg =
                                val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                child:
                    const Text(
                  "Cancel",
                ),

                onPressed: () =>
                    Navigator.pop(
                  context,
                ),
              ),

              ElevatedButton(
                child:
                    const Text(
                  "Save",
                ),

                onPressed:
                    () async {
                  try {
                    final price =
                        double.tryParse(
                              priceCtrl
                                  .text
                                  .trim(),
                            ) ??
                            0;

                    await FirebaseFirestore
                        .instance
                        .collection(
                            'vendors')
                        .doc(widget
                            .vendorId)
                        .collection(
                            'menu')
                        .doc(id)
                        .update({
                      "name":
                          nameCtrl.text
                              .trim(),

                      "price_paise":
                          (price *
                                  100)
                              .toInt(),

                      "category":
                          categoryCtrl
                              .text
                              .trim(),

                      "description":
                          descriptionCtrl
                              .text
                              .trim(),

                      "is_veg":
                          editVeg,
                    });

                    if (!context
                        .mounted) {
                      return;
                    }

                    Navigator.pop(
                      context,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          "Error: $e",
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────
  // ADD ITEM UI
  // ─────────────────────────────────────
  Widget _buildAddItem() {
    return Padding(
      padding:
          const EdgeInsets.all(
        16,
      ),
      child: Card(
        elevation: 3,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),

        child: Padding(
          padding:
              const EdgeInsets.all(
            16,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              const Center(
                child: Text(
                  "Add Item",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ✅ IMAGE PREVIEW
              Center(
                child:
                    GestureDetector(
                  onTap: pickImage,

                  child: Container(
                    width: 120,
                    height: 120,

                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),

                      border:
                          Border.all(
                        color: Colors
                            .grey
                            .shade300,
                      ),
                    ),

                    child: imageFile !=
                            null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),

                            child:
                                Image.file(
                              File(
                                imageFile!
                                    .path,
                              ),

                              fit: BoxFit
                                  .cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons
                                    .image,
                                size:
                                    40,
                              ),

                              SizedBox(
                                height:
                                    8,
                              ),

                              Text(
                                "Upload Image",
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              TextField(
                controller:
                    nameController,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Item Name",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    priceController,

                keyboardType:
                    TextInputType
                        .number,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Price",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    categoryController,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Category",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    descriptionController,

                maxLines: 3,

                decoration:
                    const InputDecoration(
                  labelText:
                      "Description",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ✅ VEG + RECOMMENDED
Column(
  children: [
    Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,

      children: [
        Text(
          isVeg
              ? "🥦 Veg"
              : "🍗 Non-Veg",

          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        Switch(
          value: isVeg,

          onChanged: (val) {
            setState(() {
              isVeg = val;
            });
          },
        ),
      ],
    ),

    const SizedBox(height: 10),

    Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,

      children: [
        const Text(
          "⭐ Recommended",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        Switch(
          value: isRecommended,

          onChanged: (val) {
            setState(() {
              isRecommended = val;
            });
          },
        ),
      ],
    ),
  ],
),

const SizedBox(height: 16),

// ✅ QUANTITY
Row(
  mainAxisAlignment:
      MainAxisAlignment.spaceBetween,

  children: [
    const Text(
      "Available Quantity",
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    Row(
      children: [
        IconButton(
          onPressed: () {
            if (quantity > 1) {
              setState(() {
                quantity--;
              });
            }
          },
          icon: const Icon(
            Icons.remove_circle,
          ),
        ),

        Text(
          quantity.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        IconButton(
          onPressed: () {
            setState(() {
              quantity++;
            });
          },
          icon: const Icon(
            Icons.add_circle,
          ),
        ),
      ],
    ),
  ],
),

const SizedBox(height: 20),

              SizedBox(
                width:
                    double.infinity,

                child:
                    ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : addItem,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFFF5A5F,
                    ),

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,

                          child:
                              CircularProgressIndicator(
                            color: Colors
                                .white,
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Text(
                          "Add Item",
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // MENU LIST UI
  // ─────────────────────────────────────
  Widget _buildMenuList() {
    return StreamBuilder<
        QuerySnapshot>(
      stream:
          FirebaseFirestore
              .instance
              .collection(
                  'vendors')
              .doc(widget.vendorId)
              .collection('menu')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .snapshots(),

      builder: (
        context,
        snapshot,
      ) {
        if (snapshot
                .connectionState ==
            ConnectionState
                .waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              "No menu items",
            ),
          );
        }

        final items =
            snapshot.data!.docs;

        if (items.isEmpty) {
          return const Center(
            child: Text(
              "No menu items yet",
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,

          physics:
              const NeverScrollableScrollPhysics(),

          itemCount:
              items.length,

          itemBuilder:
              (context, index) {
            final data =
                items[index];

            final map =
                data.data()
                    as Map<String,
                        dynamic>;

            final isVeg =
                map.containsKey(
                          'is_veg',
                        )
                    ? map['is_veg'] ==
                        true
                    : true;

            final quantity =
    map['available_quantity'] ?? 0;

final isAvailable =
    map.containsKey(
              'is_available',
            )
        ? map['is_available'] ==
            true
        : true;

            final imageUrl =
                map['image_url'] ??
                    "";

            return Card(
              margin:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: ListTile(
                contentPadding:
                    const EdgeInsets.all(
                  10,
                ),

                leading:
                    imageUrl != ""
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                              8,
                            ),

                            child:
                                Image.network(
                              imageUrl,

                              width: 60,
                              height: 60,

                              fit: BoxFit
                                  .cover,

                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Icon(
                                  Icons
                                      .fastfood,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons
                                .fastfood,
                          ),

                title: Text(
                  map['name'] ??
                      "",
                ),

                subtitle: Column(
  crossAxisAlignment:
      CrossAxisAlignment.start,

  children: [
    Text(
      formatRupeesFromPaise((map['price_paise'] ?? 0) as num),
    ),

    Text(
      isVeg
          ? "🥦 Veg"
          : "🍗 Non-Veg",

      style: TextStyle(
        color: isVeg
            ? Colors.green
            : Colors.red,

        fontWeight:
            FontWeight.bold,
      ),
    ),

    Text(
      quantity <= 0
          ? "Out Of Stock"
          : isAvailable
              ? "Available"
              : "Unavailable",

      style: TextStyle(
        color: quantity <= 0
            ? Colors.orange
            : isAvailable
                ? Colors.green
                : Colors.red,
      ),
    ),

    const SizedBox(height: 4),

    Text(
      "Qty: $quantity",
    ),

    if (map['is_recommended'] ==
        true)
      const Text(
        "⭐ Recommended",
        style: TextStyle(
          color: Colors.orange,
          fontWeight:
              FontWeight.bold,
        ),
      ),
  ],
),

                trailing:
                    SizedBox(
                  width: 170,

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .end,

                    children: [
                      IconButton(
                        icon:
                            const Icon(
                          Icons.edit,
                        ),

                        onPressed: () {
                          showEditDialog(
                            context,
                            data.id,
                            data,
                          );
                        },
                      ),

                      IconButton(
                        icon:
                            const Icon(
                          Icons.delete,
                          color:
                              Colors.red,
                        ),

                        onPressed:
                            () async {
                          await FirebaseFirestore
                              .instance
                              .collection(
                                  'vendors')
                              .doc(widget
                                  .vendorId)
                              .collection(
                                  'menu')
                              .doc(data.id)
                              .delete();
                        },
                      ),

                      Switch(
                        value:
                            isAvailable,

                        onChanged:
                            (val) async {
                          await FirebaseFirestore
                              .instance
                              .collection(
                                  'vendors')
                              .doc(widget
                                  .vendorId)
                              .collection(
                                  'menu')
                              .doc(data.id)
                              .update({
                            "is_available":
                                val,
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────
  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Menu"),

        backgroundColor:
            const Color(
          0xFFFF5A5F,
        ),

        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OrdersScreen(
                    vendorId:
                        widget.vendorId,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.receipt_long,
            ),
          ),
        ],
      ),

      backgroundColor:
          const Color(0xFFF5F5F5),

      body: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          // ✅ MOBILE
          if (constraints.maxWidth <
              700) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  _buildAddItem(),

                  const SizedBox(
                    height: 20,
                  ),

                  _buildMenuList(),
                ],
              ),
            );
          }

          // ✅ TABLET / WEB
          return Row(
            children: [
              Expanded(
                child:
                    SingleChildScrollView(
                  child:
                      _buildAddItem(),
                ),
              ),

              Expanded(
                child:
                    _buildMenuList(),
              ),
            ],
          );
        },
      ),
    );
  }
}