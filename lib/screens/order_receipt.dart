import 'package:flutter/material.dart';
import 'dashboard.dart'; // For going back to the main screen

class OrderReceiptScreen extends StatelessWidget {
  final String address;
  final String contact;
  final String city;
  final String payment;
  final String note;

  const OrderReceiptScreen({
    super.key,
    required this.address,
    required this.contact,
    required this.city,
    required this.payment,
    required this.note,
  });

  // Sample data (can later be dynamic from cart)
  final List<Map<String, dynamic>> orderedItems = const [
    {
      'name': 'Cappuccino',
      'size': 'Medium',
      'quantity': 2,
      'price': 120.0,
    },
    {
      'name': 'Latte',
      'size': 'Large',
      'quantity': 1,
      'price': 150.0,
    },
  ];

  double _calculateTotal() {
    double total = 0;
    for (final item in orderedItems) {
      total += (item['quantity'] as int) * (item['price'] as double);
    }
    return total;
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 15, color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Receipt"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.brown[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _info("📍 Address", "$address, $city"),
                  _info("📞 Contact", contact),
                  _info("💳 Payment Method", payment),
                  _info("📝 Note", note.isEmpty ? "None" : note),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, color: Colors.brown),
                  const SizedBox(height: 10),
                  const Text(
                    "🧾 Ordered Items",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  ...orderedItems.map<Widget>((item) => ListTile(
                        title: Text("${item['name']} (${item['size']})",
                            style: const TextStyle(color: Colors.black)),
                        subtitle: Text("Qty: ${item['quantity']}",
                            style: const TextStyle(color: Colors.black54)),
                        trailing: Text(
                          "₱${((item['quantity'] as int) * (item['price'] as double)).toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.black),
                        ),
                        contentPadding: EdgeInsets.zero,
                      )),
                  const Divider(thickness: 1, color: Colors.brown),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        "Total",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black),
                      ),
                      Text(
                        "₱${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "⏰ Estimated Delivery: 30-45 mins",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text("Back to Home"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
