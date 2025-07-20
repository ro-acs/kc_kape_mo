import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/providers/gcash_payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _promo;
  Map<String, dynamic>? _defaultAddress;
  String _selectedPayment = 'Cash on Delivery';

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadPromo();
    _loadDefaultAddress();
  }

  Future<void> _loadCartItems() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    setState(() {
      _cartItems = cartSnapshot.docs
          .where((doc) => doc.id != 'promo')
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'],
                'price': doc['price'],
                'quantity': doc['quantity'],
              })
          .toList();
    });
  }

  Future<void> _loadPromo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final promoDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc('promo')
        .get();

    if (promoDoc.exists) {
      setState(() {
        _promo = promoDoc.data();
      });
    }
  }

  Future<void> _loadDefaultAddress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final addressSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (addressSnapshot.docs.isNotEmpty) {
      setState(() {
        _defaultAddress = addressSnapshot.docs.first.data();
      });
    }
  }

  double _calculateSubtotal() {
    return _cartItems.fold(
        0.0, (sum, item) => sum + (item['price'] * item['quantity']));
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

  void _placeOrder() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount(subtotal);
    final total = subtotal - discount;

    if (_selectedPayment == 'GCash') {
      final checkoutUrl = await GCashPaymentService.getPaymentUrl(
        uid: user.uid,
        amountInCentavos: (total * 100).toInt(),
      );

      if (checkoutUrl != null) {
        Navigator.pushReplacementNamed(
          context,
          '/gcash_payment',
          arguments: {
            'paymentUrl': checkoutUrl,
            'selectedPayment': _selectedPayment,
            'defaultAddress': _defaultAddress,
            'referenceId': user.uid,
            'amount': total,
          },
        );
      } else {
        Fluttertoast.showToast(msg: "❌ Failed to create GCash link.");
      }
    } else {
      final order = {
        'items': _cartItems,
        'promo': _promo,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'paymentMethod': _selectedPayment,
        'deliveryAddress': _defaultAddress,
        'timestamp': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .add(order);

      // Prevent promo reuse
      if (_promo != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('used_promos')
            .doc(_promo!['code'])
            .set({'usedAt': Timestamp.now()});
      }

      // Clear cart
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
          const SnackBar(content: Text("Order placed successfully!")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount(subtotal);
    final total = subtotal - discount;

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("Delivery Address",
                style: TextStyle(fontWeight: FontWeight.bold)),
            _defaultAddress == null
                ? const Text("No default address found.")
                : Text(
                    "${_defaultAddress!['address']}, ${_defaultAddress!['city']}, ${_defaultAddress!['province']}"),
            const SizedBox(height: 20),
            const Text("Order Summary",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ..._cartItems.map((item) => ListTile(
                  title: Text(item['name']),
                  subtitle: Text("Qty: ${item['quantity']}"),
                  trailing: Text(
                      "₱${(item['price'] * item['quantity']).toStringAsFixed(2)}"),
                )),
            const Divider(),
            if (_promo != null) ...[
              Text("Promo Applied: ${_promo!['code']}"),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal"),
                Text("₱${subtotal.toStringAsFixed(2)}")
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Discount"),
                Text("-₱${discount.toStringAsFixed(2)}")
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text("₱${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Payment Method",
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedPayment,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  _selectedPayment = value!;
                });
              },
              items: const [
                DropdownMenuItem(
                    value: 'Cash on Delivery', child: Text('Cash on Delivery')),
                DropdownMenuItem(value: 'GCash', child: Text('GCash')),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("Place Order",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
