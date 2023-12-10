class Parcels {
  Parcels({
    this.orderId,
    this.senderUserId,
    this.jobId,
    this.orderStatus,
    this.express,
    this.parcelPickupAddressLatitude,
    this.parcelPickupAddressLongitude,
    this.parcelAddressToBeDeliveredLatitude,
    this.parcelAddressToBeDeliveredLongitude,
    this.servicePrice,
    this.servicePaymentType,
    this.clientName,
    this.serviceDate,
    this.serviceDateFrom,
    this.serviceDateTo,
    this.serviceParcelPrice,
    this.serviceParcelIdentifiable,
    this.orderComment,
    this.pickupAdminArea,
    this.pickupCountryCode,
    this.toBeDeliveredAdminArea,
    this.toBeDeliveredCountryCode,
    this.totalDistance,
    this.viewerPhone,
    this.arrivalInProgress,
    this.currency,
    this.parcelType,
    this.courierHasParcelMoney,
  });

  factory Parcels.fromJson(Map<String, dynamic> json) =>
      Parcels(
        orderId: json['orderId'],
        senderUserId: json['senderUserId'],
        jobId: json['jobId'],
        orderStatus: json['orderStatus'],
        express: json['express'],
        parcelPickupAddressLatitude: json['parcelPickupAddressLatitude'],
        parcelPickupAddressLongitude: json['parcelPickupAddressLongitude'],
        parcelAddressToBeDeliveredLatitude: json['parcelAddressToBeDeliveredLatitude'],
        parcelAddressToBeDeliveredLongitude: json['parcelAddressToBeDeliveredLongitude'],
        servicePrice: json['servicePrice'],
        servicePaymentType: json['servicePaymentType'],
        clientName: json['clientName'],
        serviceDate: json['serviceDate'] !=null ? DateTime.parse(json['serviceDate']) : json['serviceDate'],
        serviceDateFrom: json['serviceDateFrom'] !=null ? DateTime.parse(json['serviceDateFrom']) : json['serviceDateFrom'],
        serviceDateTo: json['serviceDateTo'] !=null ? DateTime.parse(json['serviceDateTo']) : json['serviceDateTo'],
        serviceParcelPrice: json['serviceParcelPrice'],
        serviceParcelIdentifiable: json['serviceParcelIdentifiable'],
        orderComment: json['orderComment'],
        pickupAdminArea: json['pickupAdminArea'],
        pickupCountryCode: json['pickupCountryCode'],
        toBeDeliveredAdminArea: json['toBeDeliveredAdminArea'],
        toBeDeliveredCountryCode: json['toBeDeliveredCountryCode'],
        totalDistance: json['totalDistance'],
        viewerPhone: json['viewerPhone'],
        arrivalInProgress: json['arrivalInProgress'],
        currency: json['currency'],
        parcelType: json['parcelType'],
        courierHasParcelMoney: json['courierHasParcelMoney'],
      );

  final int? orderId;
  final int? senderUserId;
  final int? jobId;
  final String? orderStatus;
  final bool? express;
  final String? parcelPickupAddressLatitude;
  final String? parcelPickupAddressLongitude;
  final String? parcelAddressToBeDeliveredLatitude;
  final String? parcelAddressToBeDeliveredLongitude;
  final double? servicePrice;
  final String? servicePaymentType;
  final String? clientName;

  final DateTime? serviceDate;
  final DateTime? serviceDateFrom;
  final DateTime? serviceDateTo;
  final double? serviceParcelPrice;
  final String? serviceParcelIdentifiable;
  final String? orderComment;
  final String? pickupAdminArea;
  final String? pickupCountryCode;
  final String? toBeDeliveredAdminArea;
  final String? toBeDeliveredCountryCode;
  final String? totalDistance;
  final String? viewerPhone;
  final String? currency;
  final bool? arrivalInProgress;
  final String? parcelType;
  final bool? courierHasParcelMoney;

}