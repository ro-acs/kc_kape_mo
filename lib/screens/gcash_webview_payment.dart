import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';

import 'dashboard.dart';

class GCashWebViewPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final double amount;
  final String selectedPayment;
  final Map<String, dynamic> defaultAddress; // ✅ Fixed type

  const GCashWebViewPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.amount,
    required this.selectedPayment,
    required this.defaultAddress,
  });

  @override
  State<GCashWebViewPaymentScreen> createState() =>
      _GCashWebViewPaymentScreenState();
}

class _GCashWebViewPaymentScreenState extends State<GCashWebViewPaymentScreen> {
  bool isLoading = true;
  bool paymentHandled = false;
  late final WebViewController _controller;
  final user = FirebaseAuth.instance.currentUser!;
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _promo;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            if (!paymentHandled &&
                (url.contains("payment-success") || url.contains("success"))) {
              paymentHandled = true;
              _handleSuccessPayment();
              return NavigationDecision.prevent;
            }

            if (!paymentHandled &&
                (url.contains("payment-failed") || url.contains("cancel"))) {
              paymentHandled = true;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Payment was cancelled or failed."),
                ),
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  double _calculateDiscount(double subtotal) {
    if (_promo == null) return 0.0;

    if (_promo!['type'] == 'flat') {
      return _promo!['value'].toDouble();
    } else if (_promo!['type'] == 'percent') {
      return subtotal * (_promo!['value'].toDouble() / 100);
    }
    return 0.0;
  }

  Future<void> _handleSuccessPayment() async {
    _confettiController.play();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final discount = _calculateDiscount(widget.amount);
    final total = widget.amount - discount;

    final cartSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    _cartItems = cartSnapshot.docs
        .where((doc) => doc.id != 'promo')
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'],
              'price': doc['price'],
              'quantity': doc['quantity'],
            })
        .toList();

    final promoDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc('promo')
        .get();

    _promo = promoDoc.data();

    final order = {
      'items': _cartItems,
      'promo': _promo,
      'subtotal': widget.amount,
      'discount': discount,
      'total': total,
      'paymentMethod': widget.selectedPayment,
      'deliveryAddress': widget.defaultAddress, // ✅ Already a Map
      'timestamp': Timestamp.now(),
      'status': 'Pending',
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .add(order);

    if (_promo != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('used_promos')
          .doc(_promo!['code'])
          .set({'usedAt': Timestamp.now()});
    }

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final cartItems = await cartRef.get();
    for (var doc in cartItems.docs) {
      await doc.reference.delete();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Order placed successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GCash Payment"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              shouldLoop: false,
              emissionFrequency: 0.08,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 5,
            ),
          ),
        ],
      ),
    );
  }
}
