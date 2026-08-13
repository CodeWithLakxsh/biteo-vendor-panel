import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_screen.dart';
import 'orders_screen.dart';
import 'vendor_profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String vendorId;

  const DashboardScreen({
    super.key,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        title:
            const Text("Biteo Partner"),

        backgroundColor:
            const Color(0xFFFF5A5F),

        actions: [
          // ✅ PROFILE BUTTON
          IconButton(
            icon: const Icon(
              Icons.person,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      VendorProfileScreen(
                    vendorId: vendorId,
                  ),
                ),
              );
            },
          ),

          // ✅ LOGOUT BUTTON
          IconButton(
            icon: const Icon(
              Icons.logout,
            ),
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
          ),
        ],
      ),

      // ✅ LIVE FIRESTORE STREAM
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore
            .instance
            .collection('vendors')
            .doc(vendorId)
            .snapshots(),

        builder: (
          context,
          snapshot,
        ) {
          // ✅ LOADING
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          bool isOpen = true;

          bool isActive = true;

          String restaurantName =
              "Restaurant";

          String imageUrl = "";

          double totalEarnings = 0;

          int totalOrders = 0;

          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.exists) {
            final data =
                snapshot.data!.data();

            if (data != null) {
              // ✅ SAFE OPEN STATUS
              isOpen =
                  data['isCurrentlyOpen'] ??
                      data['operations']
                              ?[
                              'is_currently_open'] ??
                      true;

              // ✅ SAFE ACTIVE STATUS
              isActive =
                  data['isActive'] ??
                      data['operations']
                              ?[
                              'is_active'] ??
                      true;

              // ✅ SAFE BUSINESS NAME
              restaurantName =
                  data['businessName'] ??
                      data['identity']
                              ?[
                              'business_name'] ??
                      "Restaurant";

              // ✅ SAFE IMAGE
              imageUrl =
    data['imageUrl'] ??
        data['identity']
                ?[
                'imageUrl'] ??
        "";

totalEarnings =
    ((data['total_earnings'] ?? 0)
            as num)
        .toDouble() /
    100;

totalOrders =
    data['total_orders'] ?? 0;
            }
          }

          return Column(
            children: [
              // ─────────────────────
              // STATUS HEADER
              // ─────────────────────
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.all(
                  16,
                ),
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color: isOpen
                      ? Colors.green
                          .withOpacity(
                          0.1,
                        )
                      : Colors.red
                          .withOpacity(
                          0.1,
                        ),

                  borderRadius:
                      BorderRadius
                          .circular(18),

                  border: Border.all(
                    color: isOpen
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    // ✅ LOGO
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Colors.white,

                      backgroundImage:
                          imageUrl.isNotEmpty
                              ? NetworkImage(
                                  imageUrl,
                                )
                              : null,

                      child:
                          imageUrl.isEmpty
                              ? const Icon(
                                  Icons
                                      .restaurant,
                                  color: Color(
                                    0xFFFF5A5F,
                                  ),
                                )
                              : null,
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            restaurantName,

                            maxLines: 1,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            isOpen
                                ? "🟢 Restaurant is LIVE"
                                : "🔴 Restaurant is CLOSED",

                            style:
                                TextStyle(
                              color: isOpen
                                  ? Colors
                                      .green
                                  : Colors
                                      .red,

                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            isActive
                                ? "Vendor Account Active"
                                : "Vendor Account Disabled",

                            style:
                                TextStyle(
                              color: isActive
                                  ? Colors
                                      .green
                                  : Colors
                                      .red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─────────────────────
              // DASHBOARD GRID
              // ─────────────────────
              Padding(
  padding:
      const EdgeInsets.symmetric(
    horizontal: 16,
  ),

  child: Row(
    children: [

      Expanded(
        child: Container(
          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
          ),

          child: Column(
            children: [

              const Text(
                "Total Orders",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                totalOrders.toString(),

                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: Container(
          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
          ),

          child: Column(
            children: [

              const Text(
                "Earnings",
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                "₹${totalEarnings.toStringAsFixed(0)}",

                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 14),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets
                          .all(16),

                  child: GridView.count(
                    crossAxisCount:
                        2,

                    crossAxisSpacing:
                        16,

                    mainAxisSpacing:
                        16,

                    childAspectRatio:
                        1.05,

                    children: [
                      // 🔥 MENU CARD
                      _card(
                        context,

                        "Manage Menu",

                        Icons
                            .restaurant_menu,

                        () async {
                          try {
                            final user =
                                FirebaseAuth
                                    .instance
                                    .currentUser;

                            if (user ==
                                null) {
                              ScaffoldMessenger.of(
                                      context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Not logged in",
                                  ),
                                ),
                              );

                              return;
                            }

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                    MenuScreen(
                                  vendorId:
                                      vendorId,
                                ),
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
                          }
                        },
                      ),

                      // ─────────────────
                      // ORDERS
                      // ─────────────────
                      _card(
                        context,

                        "Orders",

                        Icons
                            .receipt_long,

                        () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) =>
                                  OrdersScreen(
                                vendorId:
                                    vendorId,
                              ),
                            ),
                          );
                        },
                      ),

                      // ─────────────────
                      // PROFILE
                      // ─────────────────
                      _card(
                        context,

                        "Profile",

                        Icons.person,

                        () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) =>
                                  VendorProfileScreen(
                                vendorId:
                                    vendorId,
                              ),
                            ),
                          );
                        },
                      ),

                      // ─────────────────
                      // COMPLAINTS
                      // ─────────────────
                      _card(
                        context,

                        "Complaints",

                        Icons
                            .report_problem,

                        () {
                          ScaffoldMessenger.of(
                                  context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Coming Soon",
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────
  // CARD
  // ─────────────────────────────────────
  Widget _card(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(20),

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            20,
          ),

          boxShadow: [
            BoxShadow(
              blurRadius: 10,

              color: Colors.black
                  .withOpacity(
                0.05,
              ),

              offset: const Offset(
                0,
                4,
              ),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              icon,

              size: 40,

              color: const Color(
                0xFFFF5A5F,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
              ),
              child: Text(
                title,

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}