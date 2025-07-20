import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy-MM-dd • hh:mm a').format(date);
  }

  Future<String> _fetchUserFullName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data()?['full_name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _markOrderAsCompleted(DocumentReference orderRef) async {
    try {
      await orderRef.update({'status': 'Completed'});
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  Widget _buildOrderCard(BuildContext context, QueryDocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final total = data['total'] ?? 0;
    final address = data['deliveryAddress']['address'] ?? 'No address';
    final province = data['deliveryAddress']['province'] ?? 'N/A';
    final city = data['deliveryAddress']['city'] ?? 'N/A';
    final method = data['paymentMethod'] ?? 'N/A';
    final time = data['timestamp'] as Timestamp;
    final orderId = order.id;
    final path = order.reference.path;
    final userId = path.split('/')[1];
    final status = data['status'];
    final dateStr = DateFormat('yyyy-MM-dd – hh:mm a').format(time.toDate());

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final custName = userData?['full_name'] ?? 'Customer';
        final phone = userData?['phone'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text("Order ID: $orderId",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("📅 $dateStr"),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("👤 Customer: $custName"),
                    if (phone.isNotEmpty)
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse("tel:$phone")),
                        child: Text("📞 Phone: $phone",
                            style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline)),
                      ),
                    const SizedBox(height: 6),
                    const Text("🛒 Items:",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 2),
                          child: Text(
                              "- ${item['name']} x${item['quantity']} • ₱${item['price']}"),
                        )),
                    const SizedBox(height: 10),
                    Text("💵 Total: ₱${(total as num).toStringAsFixed(2)}"),
                    Text("🚚 Address: $address, $city, $province"),
                    Text("💳 Payment Method: $method"),
                    Text("🛠 Status: $status"),
                    if (status != 'Completed') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text("Mark as Completed"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              _markOrderAsCompleted(order.reference),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customer Orders'),
        backgroundColor: Colors.brown,
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('orders')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading orders."));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("No orders found."));
            }

            // Group orders by formatted date (yyyy-MM-dd)
            Map<String, List<QueryDocumentSnapshot>> groupedOrders = {};

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              if (timestamp == null) continue;

              final dateKey =
                  DateFormat('yyyy-MM-dd').format(timestamp.toDate());
              groupedOrders.putIfAbsent(dateKey, () => []).add(doc);
            }

            final sortedKeys = groupedOrders.keys.toList()
              ..sort((a, b) => b.compareTo(a)); // Latest first

            return ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final dateKey = sortedKeys[index];
                final displayDate = DateFormat('MMMM d, yyyy')
                    .format(DateTime.parse(dateKey)); // e.g., July 21, 2025
                final orders = groupedOrders[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        "📅 $displayDate",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                    ...orders
                        .map((order) => _buildOrderCard(context, order))
                        .toList(),
                  ],
                );
              },
            );
          }),
    );
  }
}
