import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapac/dashboard/models/user_interaction.dart';

class ChatMessage {
  final String? id;
  final String sender;
  final String message;
  final String route;
  final String imageUrl;
  final String? senderUid;
  final int likes;
  final int dislikes;
  final bool isMostHelpful;
  final Timestamp? createdAt;
  final UserInteraction? userInteraction;

  const ChatMessage({
    this.id,
    required this.sender,
    required this.message,
    required this.route,
    required this.imageUrl,
    this.senderUid,
    this.likes = 0,
    this.dislikes = 0,
    this.isMostHelpful = false,
    this.createdAt,
    this.userInteraction,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      sender: data['sender'] ?? 'Anonymous',
      message: data['message'] ?? 'No message',
      route: data['route'] ?? 'Unknown Route',
      imageUrl: data['imageUrl'] ?? '',
      senderUid: data['senderUid'] as String?,
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      isMostHelpful: data['isMostHelpful'] ?? false,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sender': sender,
      'message': message,
      'route': route,
      'imageUrl': imageUrl,
      'senderUid': senderUid,
      'likes': 0,
      'dislikes': 0,
      'isMostHelpful': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  ChatMessage copyWith({
    int? likes,
    int? dislikes,
  }) {
    return ChatMessage(
      id: id,
      sender: sender,
      message: message,
      route: route,
      imageUrl: imageUrl,
      senderUid: senderUid,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      isMostHelpful: isMostHelpful,
      createdAt: createdAt,
    );
  }
}