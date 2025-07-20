import 'package:flutter/foundation.dart';
import '../models/feedback_item.dart';

class FeedbackData extends ChangeNotifier {
  final List<FeedbackItem> _feedbackItems = [];

  List<FeedbackItem> get items => List.unmodifiable(_feedbackItems);

  void addFeedback({
    required String user,
    required int rating,
    required String comment,
    required String date,
  }) {
    _feedbackItems.insert(0,
        FeedbackItem(user: user, rating: rating, comment: comment, date: date));
    notifyListeners();
  }
}
