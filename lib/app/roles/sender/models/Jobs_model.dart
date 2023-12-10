class JobsModel {
  JobsModel({
    this.orderJobId,
    this.senderPhone,
    this.senderUserId,
    this.jobName,
    this.orderCount,
    this.courierUserId,
    this.containsExpressOrder,
  });

  factory JobsModel.fromJson(Map<String, dynamic> json) =>
      JobsModel(
        orderJobId: json['orderJobId'],
        senderPhone: json['senderPhone'],
        senderUserId: json['senderUserId'],
        jobName: json['jobName'],
        orderCount: json['orderCount'],
        courierUserId: json['courierUserId'],
        containsExpressOrder: json['containsExpressOrder'],
      );

  int? id;
  int? orderJobId;
  String? senderPhone;
  int? senderUserId;
  String? jobName;
  int? orderCount;
  int? courierUserId;
  bool? containsExpressOrder;


  void update(var body, int id) {
    if (body == null) {
      return;
    }

    this.id = id;
    if (body.orderJobId != null) {
      this.orderJobId = body.orderJobId;
    }
    if (body.senderPhone != null) {
      this.senderPhone = body.senderPhone;
    }
    if (body.senderUserId != null) {
      this.senderUserId = body.senderUserId;
    }
    if (body.jobName != null) {
      this.jobName = body.jobName;
    }
    if (body.orderCount != null) {
      this.orderCount = body.orderCount;
    }
    if (body.courierUserId != null) {
      this.courierUserId = body.courierUserId;
    }
    if (body.containsExpressOrder != null) {
      this.containsExpressOrder = body.containsExpressOrder;
    }
  }

}