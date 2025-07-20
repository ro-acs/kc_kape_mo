import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoCodeController = TextEditingController();
  double _discountAmount = 0;
  String _promoFeedback = '';

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPromoCode(); // 👈 Add this line
  }

  Future<void> _loadPromoCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final promoDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc('promo')
        .get();

    if (promoDoc.exists) {
      final data = promoDoc.data();
      final code = data?['code'] ?? '';
      if (code.isNotEmpty) {
        setState(() {
          _promoCodeController.text = code;
        });

        // Recalculate discount with this code
        _recalculateDiscount();
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int change) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final newQty = item.quantity + change;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(item.id);

    if (newQty < 1) {
      await docRef.delete();
    } else {
      await docRef.update({'quantity': newQty});
    }

    _recalculateDiscount();
  }

  Future<void> _deleteItem(CartItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(item.id)
        .delete();

    _recalculateDiscount();
  }

  void _recalculateDiscount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();

    final cartItems = snapshot.docs.map((doc) {
      final data = doc.data();
      return CartItem.fromMap(doc.id, data);
    }).toList();

    final subtotal = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + item.price * item.quantity,
    );

    if (_promoCodeController.text.isNotEmpty) {
      _applyPromoCode(subtotal);
    } else {
      setState(() {
        _discountAmount = 0;
        _promoFeedback = '';
      });
    }
  }

  Future<void> _applyPromoCode(double subtotal) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty || uid == null) {
      setState(() {
        _promoFeedback = "Enter a promo code.";
        _discountAmount = 0;
      });
      return;
    }

    final promoSnap = await FirebaseFirestore.instance
        .collection('promocodes')
        .doc(code)
        .get();
    if (!promoSnap.exists) {
      setState(() {
        _promoFeedback = "Promo code not found.";
        _discountAmount = 0;
      });
      return;
    }

    final promo = promoSnap.data()!;
    final usedBy = List<String>.from(promo['usedBy'] ?? []);
    if (usedBy.contains(uid)) {
      setState(() {
        _promoFeedback = "You have already used this promo.";
        _discountAmount = 0;
      });
      return;
    }

    double discount = 0;
    if (promo['type'] == 'flat') {
      discount = promo['value'].toDouble();
    } else if (promo['type'] == 'percent') {
      discount = subtotal * (promo['value'] / 100);
    }

    setState(() {
      _discountAmount = discount;
      _promoFeedback = "Promo applied: -₱${discount.toStringAsFixed(2)}";
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc('promo')
        .set({
      'code': code,
      'type': promo['type'],
      'value': promo['value'],
    });

    //await FirebaseFirestore.instance.collection('promocodes').doc(code).update({
    //  'usedBy': FieldValue.arrayUnion([uid])
    //});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in to view your cart.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading cart."));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final cartItems = docs.where((doc) => doc.id != 'promo').map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return CartItem.fromMap(doc.id, data);
          }).toList();

          if (cartItems.isEmpty) {
            return const Center(child: Text("Your cart is empty."));
          }

          final subtotal = cartItems.fold<double>(
            0.0,
            (sum, item) => sum + item.price * item.quantity,
          );
          final total = subtotal - _discountAmount;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.brown),
                                    onPressed: () => _updateQuantity(item, -1),
                                  ),
                                  Text('${item.quantity}',
                                      style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle,
                                        color: Colors.brown),
                                    onPressed: () => _updateQuantity(item, 1),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteItem(item),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '₱${(item.price * item.quantity).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _promoCodeController,
                  decoration: InputDecoration(
                    labelText: "Promo Code",
                    suffixIcon: TextButton(
                      onPressed: () => _applyPromoCode(subtotal),
                      child: const Text("Apply"),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_promoFeedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _promoFeedback,
                    style: TextStyle(
                      color: _discountAmount > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal:",
                        style: TextStyle(fontSize: 16, color: Colors.black87)),
                    Text("₱${subtotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                if (_discountAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Discount:",
                          style: TextStyle(fontSize: 16, color: Colors.green)),
                      Text("-₱${_discountAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 16, color: Colors.green)),
                    ],
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total:",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown)),
                    Text("₱${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckoutScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Proceed to Checkout",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
