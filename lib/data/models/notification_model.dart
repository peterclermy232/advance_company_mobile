import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String user;
  final String userName;
  final String notificationType;
  final String title;
  final String message;
  final String? relatedDepositId;
  final String? relatedApplicationId;
  final String? relatedUserName;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String timeAgo;

  const NotificationModel({
    required this.id,
    required this.user,
    required this.userName,
    required this.notificationType,
    required this.title,
    required this.message,
    this.relatedDepositId,
    this.relatedApplicationId,
    this.relatedUserName,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.timeAgo,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['uuid'] as String,
      user: json['user'] as String,
      userName: json['user_name'] as String,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      relatedDepositId: json['related_deposit_id'] as String?,
      relatedApplicationId: json['related_application_id'] as String?,
      relatedUserName: json['related_user_name'] as String?,
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      timeAgo: json['time_ago'] as String,
    );
  }

  @override
  List<Object?> get props => [
    id,
    user,
    userName,
    notificationType,
    title,
    message,
    relatedDepositId,
    relatedApplicationId,
    relatedUserName,
    isRead,
    readAt,
    createdAt,
    timeAgo,
  ];
}