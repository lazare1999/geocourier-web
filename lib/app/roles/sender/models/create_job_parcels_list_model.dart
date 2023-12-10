class CreateJobParcelsListModel {

  int? id;
  int? orderId;
  int? senderUserId;
  bool? express;
  double? servicePrice;
  String? clientName;
  double? serviceParcelPrice;
  String? serviceParcelIdentifiable;
  String? orderComment;
  String? viewerPhone;

  CreateJobParcelsListModel({
    this.id, this.orderId, this.senderUserId, this.express, this.servicePrice, this.clientName,
    this.serviceParcelPrice, this.serviceParcelIdentifiable, this.orderComment, this.viewerPhone
  });


  void updateCreateJobParcelsListModel(var body, int id) {
    if (body == null) {
      return;
    }

    this.id = id;
    if (body.orderId != null) {
      this.orderId = body.orderId;
    }
    if (body.senderUserId != null) {
      this.senderUserId = body.senderUserId;
    }
    if (body.express != null) {
      this.express = body.express;
    }
    if (body.servicePrice != null) {
      this.servicePrice = body.servicePrice;
    }
    if (body.clientName != null) {
      this.clientName = body.clientName;
    }
    if (body.serviceParcelPrice != null) {
      this.serviceParcelPrice = body.serviceParcelPrice;
    }
    if (body.serviceParcelIdentifiable != null) {
      this.serviceParcelIdentifiable = body.serviceParcelIdentifiable;
    }
    if (body.orderComment != null) {
      this.orderComment = body.orderComment;
    }
    if (body.viewerPhone != null) {
      this.viewerPhone = body.viewerPhone;
    }
  }
}