import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class UserInteraction {
  final bool isLiked;
  final bool isDisliked;

  const UserInteraction({
    this.isLiked = false,
    this.isDisliked = false,
  });

  factory UserInteraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const UserInteraction();

    return UserInteraction(
      isLiked: data['isLiked'] ?? false,
      isDisliked: data['isDisliked'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isLiked': isLiked,
      'isDisliked': isDisliked,
    };
  }
}