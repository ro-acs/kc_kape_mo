import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FeedbackViewerScreen extends StatelessWidget {
  const FeedbackViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong."));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final feedbackDocs = snapshot.data!.docs;

        if (feedbackDocs.isEmpty) {
          return const Center(child: Text("No feedback yet."));
        }

        return ListView.builder(
          itemCount: feedbackDocs.length,
          itemBuilder: (context, index) {
            final data = feedbackDocs[index].data() as Map<String, dynamic>;
            final user = data['user'] ?? 'Anonymous';
            final comment = data['comment'] ?? '';
            final rating = data['rating'] ?? 0;
            final timestamp = data['date'];

            // Convert and format timestamp
            String formattedDate = '';
            if (timestamp is Timestamp) {
              final dateTime = timestamp.toDate();
              formattedDate =
                  DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown,
                  child: Text(
                    rating.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  user,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment),
                    const SizedBox(height: 4),
                    Text(
                      "Date: $formattedDate",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
