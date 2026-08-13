import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

// 🔥 GLOBAL NAV KEY
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

// 🔔 LOCAL NOTIFICATION INSTANCE
final FlutterLocalNotificationsPlugin
    flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔔 HIGH PRIORITY CHANNEL
const AndroidNotificationChannel channel =
    AndroidNotificationChannel(
  'orders_channel',
  'Orders',
  description: 'New order notifications',
  importance: Importance.max,
  playSound: true,
);

// 🔔 BACKGROUND HANDLER
Future<void>
    _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions
            .currentPlatform,
  );

  debugPrint(
    "🔔 Background notification: ${message.notification?.title}",
  );
}

// ─────────────────────────────────────────────
// 🔥 GET REAL VENDOR ID FROM EMAIL
// ─────────────────────────────────────────────
Future<String?> getVendorIdFromEmail(
  String? email,
) async {
  if (email == null) return null;

  try {
    final query =
        await FirebaseFirestore.instance
            .collection('vendors')
            .where(
              'email',
              isEqualTo: email,
            )
            .limit(1)
            .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first.id;
  } catch (e) {
    debugPrint(
      "❌ GET VENDOR ID ERROR: $e",
    );

    return null;
  }
}

// ─────────────────────────────────────────────
// 🔥 SAVE TOKEN HELPER
// ─────────────────────────────────────────────
Future<void> saveVendorFcmToken() async {
  try {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final token =
        await FirebaseMessaging.instance
            .getToken();

    if (token == null) return;

    // ✅ GET REAL VENDOR ID
    final vendorId =
        await getVendorIdFromEmail(
      user.email,
    );

    if (vendorId == null) {
      debugPrint(
        "❌ NO VENDOR FOUND FOR EMAIL",
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('vendors')
        .doc(vendorId)
        .set({
      "fcm_token": token,

      // ✅ helpful future metadata
      "last_token_update":
          FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint(
      "✅ TOKEN SAVED: $token",
    );
  } catch (e) {
    debugPrint(
      "❌ TOKEN SAVE ERROR: $e",
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint(
    "🚀 STEP 1: Flutter Initialized",
  );

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions
            .currentPlatform,
  );

  debugPrint(
    "🚀 STEP 2: Firebase Initialized",
  );

  // ✅ AUTH WARMUP FIX
  await Future.delayed(
    const Duration(
      milliseconds: 300,
    ),
  );

  FirebaseAuth.instance.currentUser;

  debugPrint(
    "🚀 STEP 3: Firebase Auth Warmed Up",
  );

  // 🔔 INIT LOCAL NOTIFICATIONS
  const AndroidInitializationSettings
      androidSettings =
      AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const InitializationSettings
      settings =
      InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin
      .initialize(
    settings,

    // ✅ NOTIFICATION TAP FIX
    onDidReceiveNotificationResponse:
        (details) async {
      final user =
          FirebaseAuth
              .instance.currentUser;

      if (user != null) {
        final vendorId =
            await getVendorIdFromEmail(
          user.email,
        );

        if (vendorId != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) =>
                  DashboardScreen(
                vendorId: vendorId,
              ),
            ),
          );
        }
      }
    },
  );

  // 🔥 CREATE CHANNEL
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        channel,
      );

  debugPrint(
    "🚀 STEP 4: Notification Channel Created",
  );

  // 🔔 REQUEST PERMISSION
  await FirebaseMessaging.instance
      .requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint(
    "🚀 STEP 5: Notification Permission Granted",
  );

  // 🔔 BACKGROUND HANDLER
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // 🔥 SAVE TOKEN
  await saveVendorFcmToken();

  // 🔥 TOKEN REFRESH LISTENER
  FirebaseMessaging.instance
      .onTokenRefresh
      .listen((token) async {
    try {
      final user =
          FirebaseAuth
              .instance.currentUser;

      if (user != null) {
        // ✅ GET REAL VENDOR ID
        final vendorId =
            await getVendorIdFromEmail(
          user.email,
        );

        if (vendorId == null) {
          debugPrint(
            "❌ NO VENDOR FOUND",
          );
          return;
        }

        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .set({
          "fcm_token": token,
          "last_token_update":
              FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint(
          "✅ TOKEN REFRESHED",
        );
      }
    } catch (e) {
      debugPrint(
        "❌ TOKEN REFRESH ERROR: $e",
      );
    }
  });

  // 🔥 FOREGROUND NOTIFICATION
  FirebaseMessaging.onMessage.listen(
    (
      RemoteMessage message,
    ) async {
      debugPrint(
        "🔔 Foreground notification received",
      );

      final notification =
          message.notification;

      if (notification != null) {
        await flutterLocalNotificationsPlugin
            .show(
          DateTime.now()
                  .millisecondsSinceEpoch ~/
              1000,

          notification.title,
          notification.body,

          const NotificationDetails(
            android:
                AndroidNotificationDetails(
              'orders_channel',
              'Orders',

              importance:
                  Importance.max,

              priority:
                  Priority.high,

              playSound: true,
              enableVibration: true,

              ticker: 'New Order',
            ),
          ),
        );

        // 🔥 SAFE DIALOG
        final context =
            navigatorKey.currentContext;

        if (context != null) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(
                notification.title ??
                    "New Order",
              ),
              content: Text(
                notification.body ?? "",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    "OK",
                  ),
                ),
              ],
            ),
          );
        }
      }
    },
  );

  // 🔥 CLICK HANDLER
  FirebaseMessaging
      .onMessageOpenedApp
      .listen(
    (
      RemoteMessage message,
    ) async {
      debugPrint(
        "📲 Notification clicked",
      );

      final user =
          FirebaseAuth.instance
              .currentUser;

      if (user != null) {
        final vendorId =
            await getVendorIdFromEmail(
          user.email,
        );

        if (vendorId != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) =>
                  DashboardScreen(
                vendorId: vendorId,
              ),
            ),
          );
        }
      }
    },
  );

  debugPrint(
    "🚀 STEP 6: App Started",
  );

  runApp(const MyApp());
}

// ─────────────────────────────────────────────
// 🔥 MAIN APP
// ─────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      navigatorKey: navigatorKey,

      title: 'Biteo Vendor Panel',

      debugShowCheckedModeBanner:
          false,

      theme: ThemeData(
        primaryColor:
            const Color(0xFFFF5A5F),

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(0xFFFF5A5F),
        ),

        useMaterial3: true,
      ),

      // ✅ KEYBOARD OVERFLOW FIX
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(
            textScaler:
                const TextScaler.linear(
              1.0,
            ),
          ),
          child: child!,
        );
      },

      // ✅ AUTO LOGIN SUPPORT
      home: StreamBuilder<User?>(
        stream:
            FirebaseAuth.instance
                .authStateChanges(),
        builder: (
          context,
          snapshot,
        ) {
          // 🔄 LOADING
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child:
                    CircularProgressIndicator(),
              ),
            );
          }

          // ✅ LOGGED IN
          if (snapshot.hasData &&
              snapshot.data != null) {
            debugPrint(
              "✅ USER LOGGED IN: ${snapshot.data!.uid}",
            );

            return FutureBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              future:
                  FirebaseFirestore.instance
                      .collection('vendors')
                      .where(
                        'email',
                        isEqualTo:
                            snapshot.data!.email,
                      )
                      .limit(1)
                      .get(),
              builder: (
                context,
                vendorSnapshot,
              ) {
                if (vendorSnapshot
                        .connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                // ❌ NO VENDOR FOUND
                if (!vendorSnapshot.hasData ||
                    vendorSnapshot
                        .data!.docs
                        .isEmpty) {
                  return const LoginScreen();
                }

                // ✅ REAL VENDOR DOC ID
                final vendorId =
                    vendorSnapshot
                        .data!
                        .docs
                        .first
                        .id;

                debugPrint(
                  "✅ REAL VENDOR ID: $vendorId",
                );

                return DashboardScreen(
                  vendorId: vendorId,
                );
              },
            );
          }

          // ❌ LOGGED OUT
          debugPrint(
            "❌ USER NOT LOGGED IN",
          );

          return const LoginScreen();
        },
      ),
    );
  }
}

// ✅ YOUR ORIGINAL SCREEN
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Biteo Vendor Panel",
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},

          child: const Text(
            "Start Adding Vendor",
          ),
        ),
      ),
    );
  }
}