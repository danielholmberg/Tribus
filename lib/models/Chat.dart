import 'package:cloud_firestore/cloud_firestore.dart';

class ChatData {
  final String id;
  final List<dynamic> members;
  ChatData({
    this.id, 
    this.members
  });

  factory ChatData.fromSnapshot(DocumentSnapshot doc) {
    print('doc: ${doc.data.toString()}');
    return ChatData(
      id: doc.documentID,
      members: doc.data['members'] ?? [],
    );
  }
}