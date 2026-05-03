class ChatRoomModel {
  final int id;
  final int? userId;
  final int? courseId;
  final DateTime? createdAt;

  ChatRoomModel({
    required this.id,
    this.userId,
    this.courseId,
    this.createdAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['id_user'] as int?,
      courseId: json['id_courses'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class ChatMessageModel {
  final int id;
  final int? roomId;
  final String? senderType; // 'employee' или 'user'
  final int? senderId;
  final String message;
  final bool? isRead;
  final DateTime? createdAt;

  ChatMessageModel({
    required this.id,
    this.roomId,
    this.senderType,
    this.senderId,
    required this.message,
    this.isRead,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      roomId: json['id_room'] as int?,
      senderType: json['sender_type'] as String?,
      senderId: json['sender_id'] as int?,
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_room': roomId,
      'sender_type': senderType,
      'sender_id': senderId,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}