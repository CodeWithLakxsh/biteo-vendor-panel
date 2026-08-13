import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VendorSupportScreen
    extends StatefulWidget {
  final String vendorId;

  const VendorSupportScreen({
    super.key,
    required this.vendorId,
  });

  @override
  State<VendorSupportScreen>
      createState() =>
          _VendorSupportScreenState();
}

class _VendorSupportScreenState
    extends State<
        VendorSupportScreen> {
  final titleController =
      TextEditingController();

  final messageController =
      TextEditingController();

  bool isLoading = false;

  Future<void> sendTicket() async {
    try {
      if (titleController.text
              .trim()
              .isEmpty ||
          messageController.text
              .trim()
              .isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Fill all fields",
            ),
          ),
        );

        return;
      }

      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore
          .instance
          .collection(
              'support_tickets')
          .add({
        "title":
            titleController.text
                .trim(),

        "message":
            messageController.text
                .trim(),

        "vendorId":
            widget.vendorId,

        "type": "vendor",

        "status": "open",

        "createdAt":
            FieldValue
                .serverTimestamp(),
      });

      titleController.clear();

      messageController.clear();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Ticket Sent"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text("Error: $e"),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      appBar: AppBar(
        title:
            const Text("Support"),

        backgroundColor:
            const Color(
          0xFFFF5A5F,
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller:
                  titleController,

              decoration:
                  const InputDecoration(
                labelText:
                    "Issue Title",

                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller:
                  messageController,

              maxLines: 6,

              decoration:
                  const InputDecoration(
                labelText:
                    "Describe your issue",

                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : sendTicket,

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
                    ? const CircularProgressIndicator(
                        color:
                            Colors.white,
                      )
                    : const Text(
                        "Send Ticket",
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}