import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_page.dart';
import 'screens/dashboard.dart';
import 'screens/cart_screen.dart';
import 'screens/addresses_screen.dart';
import 'screens/gcash_webview_payment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KC Kape Mo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.brown),
      onGenerateRoute: _onGenerateRoute,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return const Dashboard();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }

  Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text(message)),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const Dashboard());
      case '/cart':
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case '/addresses':
        return MaterialPageRoute(builder: (_) => const AddressesScreen());
      case '/gcash_payment':
        final args = settings.arguments;
        print('❌ $args');
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => GCashWebViewPaymentScreen(
              paymentUrl: args['paymentUrl'] ?? '',
              selectedPayment: args['selectedPayment'] ?? '',
              defaultAddress: args['defaultAddress'] ?? '',
              amount: (args['amount'] ?? 0).toDouble(),
            ),
          );
        } else {
          return _errorRoute("Invalid arguments for GCash payment.");
        }

      default:
        return null;
    }
  }
}
