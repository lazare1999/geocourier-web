class ParcelsModel {
  ParcelsModel({
    this.orderId,
    this.serviceParcelIdentifiable,
    this.orderComment,
    this.senderUserId,
    this.express,
    this.servicePrice,
    this.clientName,
    this.serviceParcelPrice,
    this.viewerPhone
  });

  factory ParcelsModel.fromJson(Map<String, dynamic> json) =>
      ParcelsModel(
        orderId: json['orderId'],
        serviceParcelIdentifiable: json['serviceParcelIdentifiable'],
        orderComment: json['orderComment'],
        senderUserId: json['senderUserId'],
        express: json['express'],
        servicePrice: json['servicePrice'],
        clientName: json['clientName'],
        serviceParcelPrice: json['serviceParcelPrice'],
        viewerPhone: json['viewerPhone'],
      );

  final int? orderId;
  final String? serviceParcelIdentifiable;
  final String? orderComment;
  final int? senderUserId;
  final bool? express;
  final double? servicePrice;
  final String? clientName;
  final double? serviceParcelPrice;
  final String? viewerPhone;

}