class NotificationModel {
  NotificationModel({
    this.notificationId,
    this.userId,
    this.statusId,
    this.title,
    this.body,
    this.addDate,
    this.mustRateUser,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        notificationId: json['notificationId'],
        userId: json['userId'],
        statusId: json['statusId'],
        title: json['title'],
        body: json['body'],
        addDate: json['addDate'],
        mustRateUser: json['mustRateUser']
      );

  final int? notificationId;
  final int? userId;
  final int? statusId;
  final String? title;
  final String? body;
  final String? addDate;
  final bool? mustRateUser;

}