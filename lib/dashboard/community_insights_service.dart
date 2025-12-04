import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapac/dashboard/models/user_interaction.dart';

class CommunityInsightsService {
  final FirebaseFirestore firestore;

  CommunityInsightsService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _commentsRef => firestore
      .collection('public_data')
      .doc('zapac_community')
      .collection('comments');

  Future<UserInteraction?> getUserInteraction({
    required String messageId,
    required String userId,
  }) async {
    final doc =
        await _commentsRef.doc(messageId).collection('votes').doc(userId).get();
    if (!doc.exists) return null;
    return UserInteraction.fromFirestore(doc);
  }

  Future<void> voteOnMessage({
    required String messageId,
    required String userId,
    required bool isLiking,
    required UserInteraction current,
  }) async {
    int likeChange = 0;
    int dislikeChange = 0;
    bool newIsLiked = current.isLiked;
    bool newIsDisliked = current.isDisliked;

    if (isLiking) {
      if (current.isLiked) {
        likeChange = -1;
        newIsLiked = false;
      } else {
        likeChange = 1;
        newIsLiked = true;
        if (current.isDisliked) {
          dislikeChange = -1;
          newIsDisliked = false;
        }
      }
    } else {
      if (current.isDisliked) {
        dislikeChange = -1;
        newIsDisliked = false;
      } else {
        dislikeChange = 1;
        newIsDisliked = true;
        if (current.isLiked) {
          likeChange = -1;
          newIsLiked = false;
        }
      }
    }

    final messageRef = _commentsRef.doc(messageId);
    final voteRef = messageRef.collection('votes').doc(userId);

    final batch = firestore.batch();

    if (likeChange != 0 || dislikeChange != 0) {
      batch.update(messageRef, {
        'likes': FieldValue.increment(likeChange),
        'dislikes': FieldValue.increment(dislikeChange),
      });
    }

    batch.set(voteRef, {
      'isLiked': newIsLiked,
      'isDisliked': newIsDisliked,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> reportMessage({
    required String messageId,
    required String userId,
  }) async {
    final reportRef =
        _commentsRef.doc(messageId).collection('reports').doc(userId);

    await reportRef.set({
      'reporterUid': userId,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _commentsRef.doc(messageId).set(
      {'reportCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteMessage(String messageId) async {
    await _commentsRef.doc(messageId).delete();
  }
}