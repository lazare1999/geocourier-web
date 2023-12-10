class OrdersCouriersInfoModel {
  OrdersCouriersInfoModel({
    this.id,
    this.courierPhone,
    this.parcelAddressToBeDeliveredLatitude,
    this.parcelAddressToBeDeliveredLongitude,
  });

  factory OrdersCouriersInfoModel.fromJson(Map<String, dynamic> json) =>
      OrdersCouriersInfoModel(
        id: json['id'],
        courierPhone: json['courierPhone'],
        parcelAddressToBeDeliveredLatitude: json['parcelAddressToBeDeliveredLatitude'],
        parcelAddressToBeDeliveredLongitude: json['parcelAddressToBeDeliveredLongitude'],
      );

  final int? id;
  final String? courierPhone;
  final String? parcelAddressToBeDeliveredLatitude;
  final String? parcelAddressToBeDeliveredLongitude;

}