class AddOrderPageModel {

  //განასხვავოს შეკვეთა ექსპრესია თუ არა
  bool? express;

  //ასაღები მისამართის კოორდინატები
  double? parcelPickupAddressLatitude;
  double? parcelPickupAddressLongitude;

  //ჩასაბარებელი მისამართის კოორდინატები
  double? parcelAddressToBeDeliveredLatitude;
  double? parcelAddressToBeDeliveredLongitude;

  //საკურიერო მომსახურების ფასი
  String? servicePrice;

  //1 - ბარათით, 2 - ჩაბარების დროს; 3 - აღებისას
  int? servicePaymentType;

  //კლიენტის სახელი
  String? clientName;

  //ექსპრეს შეკვეთის თარიღები
  DateTime? serviceDate;
  DateTime? serviceDateFrom;
  DateTime? serviceDateTo;

  //ამანათის ღირებულება
  String? serviceParcelPrice;

  //ამანათის მაიდენტიფიცირებელი
  String? serviceParcelIdentifiable;

  //კომენტარი
  String? orderComment;

  //ამანათის მდებარეობის რეგიონი და ქვეყანა
  String? pickupAdminArea;
  String? pickupCountryCode;

  //ამანათის მიტანის რეგიონი და ქვეყანა
  String? toBeDeliveredAdminArea;
  String? toBeDeliveredCountryCode;

  double? totalDistance;

  String? viewerPhone;

  int? parcelType;

  bool? courierHasParcelMoney;

  AddOrderPageModel({this.express, this.parcelPickupAddressLatitude, this.parcelPickupAddressLongitude, this.parcelAddressToBeDeliveredLatitude,
    this.parcelAddressToBeDeliveredLongitude, this.servicePrice, this.servicePaymentType, this.clientName, this.serviceDate, this.serviceDateFrom,
    this.serviceDateTo, this.serviceParcelPrice, this.serviceParcelIdentifiable, this.orderComment, this.pickupAdminArea,
    this.pickupCountryCode, this.toBeDeliveredAdminArea, this.toBeDeliveredCountryCode, this.totalDistance, this.viewerPhone, this.parcelType, this.courierHasParcelMoney
  });

  Map<String, dynamic> toMap() {
    return {
      'express': express !=null ? express.toString() : "",
      'parcelPickupAddressLatitude': parcelPickupAddressLatitude !=null ? parcelPickupAddressLatitude.toString() : "",
      'parcelPickupAddressLongitude': parcelPickupAddressLongitude !=null ? parcelPickupAddressLongitude.toString() : "",
      'parcelAddressToBeDeliveredLatitude': parcelAddressToBeDeliveredLatitude !=null ? parcelAddressToBeDeliveredLatitude.toString() : "",
      'parcelAddressToBeDeliveredLongitude': parcelAddressToBeDeliveredLongitude !=null ? parcelAddressToBeDeliveredLongitude.toString() : "",
      'servicePrice': servicePrice !=null ? servicePrice : "",
      'servicePaymentType': servicePaymentType !=null ? servicePaymentType.toString() : "",
      'clientName': clientName !=null ? clientName : "",
      'serviceDate': serviceDate !=null ? serviceDate.toString() : "",
      'serviceDateFrom': serviceDateFrom !=null ? serviceDateFrom.toString() : "",
      'serviceDateTo': serviceDateTo !=null ? serviceDateTo.toString() : "",
      'serviceParcelPrice': serviceParcelPrice !=null ? serviceParcelPrice : "",
      'serviceParcelIdentifiable': serviceParcelIdentifiable !=null ? serviceParcelIdentifiable : "",
      'orderComment': orderComment !=null ? orderComment : "",
      'pickupAdminArea': pickupAdminArea !=null ? pickupAdminArea : "",
      'pickupCountryCode': pickupCountryCode !=null ? pickupCountryCode : "",
      'toBeDeliveredAdminArea': toBeDeliveredAdminArea !=null ? toBeDeliveredAdminArea : "",
      'toBeDeliveredCountryCode': toBeDeliveredCountryCode !=null ? toBeDeliveredCountryCode : "",
      'totalDistance': totalDistance !=null ? totalDistance.toString() : "",
      'viewerPhone': viewerPhone !=null ? viewerPhone : "",
      'parcelType': parcelType !=null ? parcelType.toString() : "",
      'courierHasParcelMoney': courierHasParcelMoney !=null ? courierHasParcelMoney.toString() : "",
    };
  }

}