import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RatingsFeedback extends StatefulWidget {
  const RatingsFeedback({super.key});

  @override
  State<RatingsFeedback> createState() => _RatingsFeedbackState();
}

class _RatingsFeedbackState extends State<RatingsFeedback> {
  final TextEditingController _feedbackController = TextEditingController();
  int _currentRating = 0;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserFullName();
  }

  Future<void> _loadUserFullName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      _userName = doc.data()?['full_name'] ?? user.email ?? 'Customer';
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    String message;
    Color snackBarColor;

    if (_currentRating == 0) {
      message = "Please select a rating.";
      snackBarColor = Colors.red;
    } else if (_feedbackController.text.trim().isEmpty) {
      message = "Please enter your feedback.";
      snackBarColor = Colors.red;
    } else {
      try {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('feedback').add({
          'user': _userName ?? 'Customer',
          'uid': user?.uid ?? '',
          'rating': _currentRating,
          'comment': _feedbackController.text.trim(),
          'date': Timestamp.now(),
        });

        message = "Thank you for your feedback!";
        snackBarColor = Colors.green;

        _feedbackController.clear();
        setState(() {
          _currentRating = 0;
        });
      } catch (e) {
        message = "Error submitting feedback.";
        snackBarColor = Colors.red;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: snackBarColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate Our Service',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _currentRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 35,
                ),
                onPressed: () => setState(() => _currentRating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _feedbackController,
            style: const TextStyle(color: Colors.black),
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Your Feedback',
              labelStyle: const TextStyle(color: Colors.brown),
              hintText: 'Tell us about your experience...',
              hintStyle: const TextStyle(color: Colors.brown),
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.brown, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Submit Feedback',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
