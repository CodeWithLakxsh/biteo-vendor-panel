// ============================================================
// Biteo Razorpay Backend (FINAL CLEAN WORKING VERSION)
// ============================================================

const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

const admin = require("firebase-admin");
const crypto = require("crypto");
const Razorpay = require("razorpay");
const cors = require("cors")({ origin: true });

admin.initializeApp();
const db = admin.firestore();

// ============================================================
// 🔔 NOTIFICATION (VENDOR)
// ============================================================
exports.sendOrderNotification = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    try {
      const order = event.data.data();
      const vendorId = order.vendor_id;

      if (!vendorId) {
        console.log("❌ No vendor_id");
        return;
      }

      const vendorDoc = await db.collection("vendors").doc(vendorId).get();

      if (!vendorDoc.exists) {
        console.log("❌ Vendor not found");
        return;
      }

      const token = vendorDoc.data().fcm_token;

      if (!token) {
        console.log("❌ No FCM token");
        return;
      }

      await admin.messaging().send({
        token: token,
        notification: {
          title: "🔥 New Order Received",
          body: `Order from ${order.vendorName || "Customer"}`,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "orders_channel",
            sound: "default",
            priority: "max",
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      console.log("✅ Notification sent successfully");
    } catch (e) {
      console.log("❌ Notification error:", e);
    }
  }
);

// ============================================================
// 💳 CREATE ORDER
// ============================================================
exports.createOrder = onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const data =
        typeof req.body === "string" ? JSON.parse(req.body) : req.body;

      const { userId, amount, mode = "pickup" } = data;

      if (!userId) {
        return res.status(400).json({ message: "UserId required" });
      }

      let finalAmount = amount;

      const cartSnap = await db
        .collection("active_carts")
        .doc(userId)
        .get();

      if (cartSnap.exists) {
        const cart = cartSnap.data();
        finalAmount = cart?.pricing?.total ?? amount;
      }

      if (!finalAmount) {
        return res.status(400).json({ message: "Invalid amount" });
      }

      const razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
      });

      const order = await razorpay.orders.create({
        amount: finalAmount,
        currency: "INR",
        receipt: `rcpt_${Date.now()}`,
      });

      console.log("✅ Razorpay order created");

      return res.json({
        success: true,
        order,
        mode,
      });
    } catch (e) {
      console.error("❌ CREATE ORDER ERROR:", e);
      return res.status(500).json({ error: e.message });
    }
  });
});

// ============================================================
// ✅ VERIFY PAYMENT + CREATE ORDER
// ============================================================
exports.verifyPayment = onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const data =
        typeof req.body === "string" ? JSON.parse(req.body) : req.body;

      const {
        razorpay_order_id,
        razorpay_payment_id,
        razorpay_signature,
        userId,
        orderData,
        mode = "pickup",
      } = data;

      // 🔐 VALIDATE PAYMENT
      if (!razorpay_payment_id) {
        return res.status(400).json({
          success: false,
          message: "Payment not completed",
        });
      }

      const body = razorpay_order_id + "|" + razorpay_payment_id;

      const expectedSignature = crypto
        .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
        .update(body)
        .digest("hex");

      if (expectedSignature !== razorpay_signature) {
        return res.status(400).json({
          success: false,
          message: "Invalid signature",
        });
      }

      // 🔥 FETCH CART
      const cartRef = db.collection("active_carts").doc(userId);
      const cartSnap = await cartRef.get();

      let items = [];
      let amount = 0;
      let vendorName = "Biteo Vendor";
      let vendorId = null;

      if (cartSnap.exists) {
        const cart = cartSnap.data();

        items = cart.items ?? [];
        amount = cart?.pricing?.total ?? 0;
        vendorName = cart?.vendorName ?? "Biteo Vendor";

        // support both formats
        vendorId = cart?.vendorId ?? cart?.vendor_id ?? null;
      }

      // 🚨 FINAL CHECK
      if (!vendorId) {
        console.log("❌ vendorId missing - order NOT created");
        return res.status(400).json({
          success: false,
          message: "Vendor ID missing",
        });
      }

      // 🔥 OTP
      let otpCode = null;
      if (mode === "pickup") {
        otpCode = Math.floor(1000 + Math.random() * 9000).toString();
      }

      // 🔥 CREATE ORDER
      const orderRef = db.collection("orders").doc();

      await orderRef.set({
        id: orderRef.id,
        user_id: userId,
        vendor_id: vendorId,
        vendorName,
        items,
        amount,
        mode,
        otpCode,
        razorpay_order_id,
        razorpay_payment_id,
        status: "pending",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 🔥 DELETE CART
      if (cartSnap.exists) {
        await cartRef.delete();
      }

      console.log("✅ Order created in Firestore");

      return res.json({
        success: true,
        orderId: orderRef.id,
        otpCode,
        vendorName,
        totalPaise: amount,
        estimatedReadyMinutes: 15,
        pickupMode: mode,
      });
    } catch (e) {
      console.error("❌ VERIFY PAYMENT ERROR:", e);
      return res.status(500).json({ error: e.message });
    }
  });
});