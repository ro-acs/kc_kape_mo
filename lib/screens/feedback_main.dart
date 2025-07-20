import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ratings_feedback.dart';
import 'feedback_viewer.dart';

class FeedbackMainScreen extends StatefulWidget {
  const FeedbackMainScreen({super.key});

  @override
  State<FeedbackMainScreen> createState() => _FeedbackMainScreenState();
}

class _FeedbackMainScreenState extends State<FeedbackMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('full_name')) {
        setState(() {
          _userName = doc['full_name'];
        });
      } else {
        setState(() {
          _userName = user.email?.split('@')[0] ?? "Customer";
        });
      }
    } catch (e) {
      debugPrint("Error loading full_name: $e");
      setState(() {
        _userName = user.email?.split('@')[0] ?? "Customer";
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.message, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Hello, ${_userName ?? "Customer"}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.brown,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orangeAccent,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.rate_review), text: 'Rate Us'),
            Tab(icon: Icon(Icons.feedback), text: 'View Feedback'),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TabBarView(
              controller: _tabController,
              children: const [
                RatingsFeedback(),
                FeedbackViewerScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
