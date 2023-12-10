import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';

class MarkerSnippetText {
  late String fromWhereToWhere;
  late String comment;
  late String parcelPrice;
  late String servicePaymentType;
  late String serviceParcelPrice;
  late String courierHasParcelMoney;
  late String clientName;
  late String expressString;

  String getMarkerSnippetText(Parcels parcel, context) {

    fromWhereToWhere = AppLocalizations.of(context)!.direction + parcel.pickupCountryCode! + ", "+ parcel.pickupAdminArea! + " -> " + parcel.toBeDeliveredCountryCode! + ", "+ parcel.toBeDeliveredAdminArea!;
    if(parcel.totalDistance !=null && parcel.totalDistance !="") {
      fromWhereToWhere += " <strong style=\"color: crimson;\">("+ parcel.totalDistance! +" km)</strong>";
    }
    fromWhereToWhere +="\n";

    comment = AppLocalizations.of(context)!.comment + ": " + parcel.orderComment! + "\n";

    parcelPrice = AppLocalizations.of(context)!.courier_fee + parcel.servicePrice.toString() + " " + parcel.currency! + "<br>";

    servicePaymentType = AppLocalizations.of(context)!.payment_method;
    switch (parcel.servicePaymentType) {
      case "CARD" : servicePaymentType += AppLocalizations.of(context)!.by_card; break;
      case "DELIVERY" : servicePaymentType += AppLocalizations.of(context)!.by_delivery_time; break;
      case "TAKING" : servicePaymentType += AppLocalizations.of(context)!.when_taking_the_parcel; break;
    }
    servicePaymentType +="<br>";

    serviceParcelPrice ="";
    if(parcel.serviceParcelPrice !=null && parcel.serviceParcelPrice !=0) {
      serviceParcelPrice += AppLocalizations.of(context)!.the_cost_of_the_parcel + ": " + parcel.serviceParcelPrice.toString() + " " + parcel.currency! + "<br>";
    }

    courierHasParcelMoney ="";
    if(parcel.courierHasParcelMoney !=null && parcel.courierHasParcelMoney!) {
      courierHasParcelMoney += ", " + AppLocalizations.of(context)!.courier_will_have_parcel_money + "<br>";
    }

    clientName = "";
    if (parcel.clientName !=null && parcel.clientName !="") {
      clientName = AppLocalizations.of(context)!.client_name + ": " + parcel.clientName!;
    }
    clientName +="<br>";

    expressString = "";
    if (parcel.express !=null && parcel.express!) {
      if (parcel.serviceDate !=null) {
        expressString = AppLocalizations.of(context)!.express
            + " (" + parcel.serviceDate!.year.toString() + "/" + parcel.serviceDate!.month.toString() + "/" + parcel.serviceDate!.day.toString()
            + " " + parcel.serviceDate!.hour.toString() + ":" + parcel.serviceDate!.minute.toString();
      } else if (parcel.serviceDateFrom !=null) {
        expressString = AppLocalizations.of(context)!.express
            + " (" + parcel.serviceDateFrom!.year.toString() + "/" + parcel.serviceDateFrom!.month.toString() + "/" + parcel.serviceDateFrom!.day.toString()
            + " " + parcel.serviceDateFrom!.hour.toString() + ":" + parcel.serviceDateFrom!.minute.toString();
        if (parcel.serviceDateTo !=null) {
          expressString += " -> "
              + " (" + parcel.serviceDateTo!.year.toString() + "/" + parcel.serviceDateTo!.month.toString() + "/" + parcel.serviceDateTo!.day.toString()
              + " " + parcel.serviceDateTo!.hour.toString() + ":" + parcel.serviceDateTo!.minute.toString();
        }

      }
      expressString += ")";
    }

    return fromWhereToWhere +
        comment +
        parcelPrice +
        servicePaymentType +
        serviceParcelPrice +
        courierHasParcelMoney +
        clientName +
        expressString;
  }


}