import 'package:dio/dio.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<List<Parcels>?> getParcels(context, bool foCourier) async {
  if (foCourier) {
    return await getCourierParcels(context);
  } else {
    return await getNotCourierParcels(context);
  }
}

Future<List<Parcels>?> getCourierParcels(context) async {

  try {

    final res = await geoCourierClient.post('orders_courier/get_courier_parcels');

    if(res.statusCode ==200) {
      return List<Parcels>.from(res.data.map((model)=> Parcels.fromJson(model)));
    }

  } catch (e) {
    if (e is DioException && e.response?.statusCode == 403) {
      reloadApp(context);
    } else {
      showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
    }
  }
  return null;

}

Future<List<Parcels>?> getNotCourierParcels(context) async {
  try {

    final res = await geoCourierClient.post('orders_courier/get_not_courier_parcels');

    if(res.statusCode ==200) {
      return List<Parcels>.from(res.data.map((model)=> Parcels.fromJson(model)));
    }

  } catch (e) {
    if (e is DioException && e.response?.statusCode == 403) {
      reloadApp(context);
    } else {
      showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
    }
  }
  return null;
}