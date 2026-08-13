import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class OrdersScreen extends StatefulWidget {
  final String vendorId;

  const OrdersScreen({
    super.key,
    required this.vendorId,
  });

  @override
  State<OrdersScreen> createState() =>
      _OrdersScreenState();
}

class _OrdersScreenState
    extends State<OrdersScreen> {
  final player = AudioPlayer();

  int lastOrderCount = 0;

  bool firstLoad = true;

  double todayEarnings = 0;
  int todayOrders = 0;

  // ─────────────────────────────────────
  // UPDATE STATUS
  // ─────────────────────────────────────
  Future<void> updateStatus(
    String orderId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        "status": status,

        // ✅ helpful timestamps
        "updated_at":
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Order marked $status",
          ),
        ),
      );
    } catch (e) {
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

  // ─────────────────────────────────────
  // STATUS COLOR
  // ─────────────────────────────────────
  Color _getStatusColor(
    String status,
  ) {
    return orderStatusColor(status);
  }

  // ─────────────────────────────────────
  // STATUS TEXT
  // ─────────────────────────────────────
  String _getStatusEmoji(
    String status,
  ) {
    return orderStatusLabel(status);
  }

  // ─────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────
  @override
  Widget build(
    BuildContext context,
  ) {
    debugPrint(
      "🔥 VENDOR ID: ${widget.vendorId}",
    );

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      appBar: AppBar(
        title:
            const Text("Orders"),

        backgroundColor:
            const Color(
          0xFFFF5A5F,
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot>(
        stream:
            FirebaseFirestore
                .instance
                .collection('orders')

                // ✅ SUPPORT BOTH FIELDS
                .where(
                  'vendor_id',
                  isEqualTo:
                      widget.vendorId,
                )

                .orderBy(
                  'created_at',
                  descending: true,
                )

                .snapshots(),

        builder: (
          context,
          snapshot,
        ) {
          // ─────────────────────────
          // LOADING
          // ─────────────────────────
          if (snapshot
                  .connectionState ==
              ConnectionState
                  .waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // ─────────────────────────
          // ERROR
          // ─────────────────────────
          if (snapshot.hasError) {
            debugPrint(
              "❌ ERROR: ${snapshot.error}",
            );

            return Center(
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(20),
                child: Text(
                  "Error loading orders\n\n${snapshot.error}",
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          // ─────────────────────────
          // EMPTY
          // ─────────────────────────
          if (!snapshot.hasData ||
              snapshot.data!.docs
                  .isEmpty) {
            return const Center(
              child: Text(
                "No Orders Yet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            );
          }

          final orders =
              snapshot.data!.docs;
              todayEarnings = 0;
todayOrders = 0;

for (final order in orders) {
  final data =
      order.data()
          as Map<String, dynamic>;

  final status =
      data['status'] ?? "";

  final createdAt =
      data['created_at']
          as Timestamp?;

  if (createdAt == null) {
    continue;
  }

  final orderDate =
      createdAt.toDate();

  final now = DateTime.now();

  final isToday =
      orderDate.year == now.year &&
      orderDate.month == now.month &&
      orderDate.day == now.day;

  if (status == "completed" &&
      isToday) {

    todayOrders++;

    todayEarnings +=
        ((data['amount'] ?? 0)
                as num)
            .toDouble() /
        100;
  }
}

          // ─────────────────────────
          // SOUND LOGIC
          // ─────────────────────────
          if (firstLoad) {
            lastOrderCount =
                orders.length;

            firstLoad = false;
          } else {
            if (orders.length >
                lastOrderCount) {
              player.play(
                AssetSource(
                  'sounds/alert.mp3',
                ),
              );
            }

            lastOrderCount =
                orders.length;
          }

          // ─────────────────────────
          // LIST
          // ─────────────────────────
          return Column(
  children: [

    Container(
      margin:
          const EdgeInsets.all(12),

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Row(
        children: [

          Expanded(
            child: Column(
              children: [

                const Text(
                  "Today's Orders",
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  todayOrders.toString(),

                  style:
                      const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [

                const Text(
                  "Today's Earnings",
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  "₹${todayEarnings.toStringAsFixed(0)}",

                  style:
                      const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),

    Expanded(
  child: RefreshIndicator(
    onRefresh: () async {},

    child: ListView.builder(
      padding: const EdgeInsets.all(
        10,
      ),

      itemCount: orders.length,

      itemBuilder:
          (context, index) {

        final doc =
            orders[index];

        final data =
            doc.data()
                as Map<String, dynamic>;

        final status =
            data['status'] ??
                "pending";

        final total =
            ((data['amount'] ?? 0)
                        as num)
                    .toDouble() /
                100;

        final items =
            data['items']
                    as List<dynamic>? ??
                [];

        final customerName =
            data['customer_name'] ??
                "Customer";

        final customerPhone =
            data['customer_phone'] ??
                "";

        final address =
            data['delivery_address'] ??
                "";

        return Card(
          margin:
              const EdgeInsets.only(
            bottom: 14,
          ),

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
              14,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Row(
                  children: [

                    Expanded(
                      child: Text(
                        "Order #${doc.id.substring(0, 6).toUpperCase()}",

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            _getStatusColor(
                          status,
                        ).withOpacity(
                          0.12,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),

                      child: Text(
                        _getStatusEmoji(
                          status,
                        ),

                        style: TextStyle(
                          color:
                              _getStatusColor(
                            status,
                          ),

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Text(
                  "👤 $customerName",

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                if (customerPhone
                    .toString()
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 4,
                    ),

                    child: Text(
                      "📞 $customerPhone",
                    ),
                  ),

                if (address
                    .toString()
                    .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 4,
                    ),

                    child: Text(
                      "📍 $address",
                    ),
                  ),

                const SizedBox(
                  height: 12,
                ),

                const Text(
                  "Items",

                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                ...items.map(
                  (item) {

                    final itemData =
                        item
                            as Map<String,
                                dynamic>;

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 4,
                      ),

                      child: Row(
                        children: [

                          Expanded(
                            child: Text(
                              itemData['name'] ??
                                  "",
                            ),
                          ),

                          Text(
                            "x${itemData['quantity'] ?? 1}",
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Divider(
                  height: 24,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    const Text(
                      "Total Amount",

                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text(
                      "₹ ${total.toStringAsFixed(0)}",

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 18,
                        color: Color(
                          0xFFFF5A5F,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                if (status ==
                    "pending") ...[
                  Row(
                    children: [

                      Expanded(
                        child:
                            ElevatedButton(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.green,
                          ),

                          onPressed: () {
                            updateStatus(
                              doc.id,
                              "accepted",
                            );
                          },

                          child:
                              const Text(
                            "Accept",
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child:
                            ElevatedButton(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red,
                          ),

                          onPressed: () {
                            updateStatus(
                              doc.id,
                              "rejected",
                            );
                          },

                          child:
                              const Text(
                            "Reject",
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (status ==
                    "accepted") ...[
                  SizedBox(
                    width:
                        double.infinity,

                    child:
                        ElevatedButton(
                      onPressed: () {
                        updateStatus(
                          doc.id,
                          "preparing",
                        );
                      },

                      child: const Text(
                        "Start Preparing",
                      ),
                    ),
                  ),
                ],

                if (status ==
                    "preparing") ...[
                  SizedBox(
                    width:
                        double.infinity,

                    child:
                        ElevatedButton(
                      onPressed: () {
                        updateStatus(
                          doc.id,
                          "ready",
                        );
                      },

                      child: const Text(
                        "Mark Ready",
                      ),
                    ),
                  ),
                ],

                if (status ==
                    "ready") ...[
                  SizedBox(
                    width:
                        double.infinity,

                    child:
                        ElevatedButton(
                      onPressed:
                          () async {

                        await updateStatus(
                          doc.id,
                          "completed",
                        );

                       if (status != "completed") {

  await FirebaseFirestore
      .instance
      .collection('vendors')
      .doc(widget.vendorId)
      .update({

    "total_orders":
        FieldValue.increment(
      1,
    ),

    "total_earnings":
        FieldValue.increment(
      data['amount'] ?? 0,
    ),
  });
}
},

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green,
                      ),

                      child: const Text(
                        "Complete Order",
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  ),
),
          ],
        );
      },
    ),
  );
}

@override
void dispose() {
  player.dispose();
  super.dispose();
}
}