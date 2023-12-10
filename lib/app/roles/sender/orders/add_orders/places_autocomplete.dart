import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/roles/sender/models/add_order_page_model.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlacesAutocomplete extends StatefulWidget {


  final String? kGoogleApiKey;
  final LatLng? markerValue1;
  final LatLng? markerValue2;
  final AddOrderPageModel? addOrderPageModel;
  final ValueChanged<AddOrderPageModel>? updateAddOrderPageModel;
  final ValueChanged<LatLng>? updateMarker1;
  final ValueChanged<LatLng>? updateMarker2;


  PlacesAutocomplete({required this.kGoogleApiKey, required this.markerValue1,
    required this.markerValue2, required this.addOrderPageModel,
    required this.updateAddOrderPageModel, this.updateMarker1, this.updateMarker2,
  });

  @override
  _PlacesAutocompleteState createState() => _PlacesAutocompleteState(kGoogleApiKey: kGoogleApiKey, markerValue1:
  markerValue1, markerValue2: markerValue2, addOrderPageModel: addOrderPageModel,
    updateAddOrderPageModel: updateAddOrderPageModel,  updateMarker1: updateMarker1, updateMarker2: updateMarker2,);

}

class _PlacesAutocompleteState extends State<PlacesAutocomplete> {

  final String? kGoogleApiKey;
  late final LatLng? markerValue1;
  final LatLng? markerValue2;
  final AddOrderPageModel? addOrderPageModel;
  final ValueChanged<AddOrderPageModel>? updateAddOrderPageModel;
  final ValueChanged<LatLng>? updateMarker1;
  final ValueChanged<LatLng>? updateMarker2;

  _PlacesAutocompleteState({this.kGoogleApiKey, this.markerValue1, this.addOrderPageModel, this.markerValue2,
    this.updateAddOrderPageModel, this.updateMarker1, this.updateMarker2});

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];

  LatLng? _markerPos;

  String? _apiKey = dotenv.env['GOOGLE_API_KEY'];

  @override
  void initState() {
    googlePlace = GooglePlace(_apiKey!);
    super.initState();
  }

  Future<DetailsResult?> getDetails(String placeId) async {

    var result;
    if (kIsWeb) {
      result = await getPlaceDetails(placeId, _apiKey, context);
    } else {
      result = await this.googlePlace.details.get(placeId);
    }

    if (result != null && result.result != null && mounted) {
      return result.result;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.only(right: 20, left: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(

                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.enter_address,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50.0),
                    borderSide: BorderSide(
                      color: Colors.deepOrange,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50.0),
                    borderSide: BorderSide(
                      color: Colors.black54,
                      width: 2.0,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    autoCompleteSearch(value);
                  } else {
                    if (predictions.length > 0 && mounted) {
                      setState(() {
                        predictions = [];
                      });
                    }
                  }
                },
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(predictions[index].description!),
                      onTap: () async {

                        var prediction = predictions[index];
                        var details = await getDetails(prediction.placeId!);

                        if(details ==null) {
                          showAlertDialog(context, AppLocalizations.of(context)!.an_error_occurred, "");
                          return;
                        }

                        var lat = details.geometry!.location!.lat;
                        var lng = details.geometry!.location!.lng;

                        if (addOrderPageModel!.parcelAddressToBeDeliveredLatitude !=null &&
                            addOrderPageModel!.parcelAddressToBeDeliveredLatitude !=null) {

                          if (addOrderPageModel!.parcelAddressToBeDeliveredLatitude == lat &&
                              addOrderPageModel!.parcelAddressToBeDeliveredLatitude == lng) {

                            showAlertDialog(context, AppLocalizations.of(context)!.same_as_the_delivery_address, "");
                            return;
                          }
                        }

                        _markerPos = LatLng(lat!, lng!);

                        if(updateMarker1 !=null) {
                          addOrderPageModel!.parcelPickupAddressLatitude = lat;
                          addOrderPageModel!.parcelPickupAddressLongitude = lng;

                          if (kIsWeb) {
                            var addressComponents = await getPlaceViaCoordinates(_markerPos!.latitude, _markerPos!.longitude, kGoogleApiKey, context);
                            if (addressComponents !=null) {
                              addOrderPageModel!.pickupCountryCode = addressComponents.firstWhere((entry) => entry['types'].contains('country'))['short_name'];
                              addOrderPageModel!.pickupAdminArea =  addressComponents.firstWhere((entry) => entry['types'].contains('administrative_area_level_1'))['long_name'];
                            }
                          } else {
                            var address = await placemarkFromCoordinates(lat, lng);

                            if (address.length > 0) {
                              addOrderPageModel!.pickupAdminArea = address[0].administrativeArea;
                              addOrderPageModel!.pickupCountryCode = address[0].isoCountryCode;
                            }
                          }
                          updateMarker1!(_markerPos!);
                        }

                        if(updateMarker2 !=null) {
                          addOrderPageModel!.parcelAddressToBeDeliveredLatitude = lat;
                          addOrderPageModel!.parcelAddressToBeDeliveredLongitude = lng;
                          if (kIsWeb) {
                            var addressComponents = await getPlaceViaCoordinates(_markerPos!.latitude, _markerPos!.longitude, kGoogleApiKey, context);
                            if (addressComponents !=null) {
                              addOrderPageModel!.toBeDeliveredCountryCode = addressComponents.firstWhere((entry) => entry['types'].contains('country'))['short_name'];
                              addOrderPageModel!.toBeDeliveredAdminArea =  addressComponents.firstWhere((entry) => entry['types'].contains('administrative_area_level_1'))['long_name'];
                            }
                          } else {
                            var address = await placemarkFromCoordinates(lat, lng);

                            if (address.length > 0) {
                              addOrderPageModel!.toBeDeliveredAdminArea = address[0].administrativeArea;
                              addOrderPageModel!.toBeDeliveredCountryCode = address[0].isoCountryCode;
                            }
                          }
                          updateMarker2!(_markerPos!);
                        }

                        updateAddOrderPageModel!(addOrderPageModel!);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void autoCompleteSearch(String value) async {
    var result;
    if (kIsWeb) {
      result = await getPlaceAutocompletePredictions(value, _apiKey, context);
    } else {
      result = await googlePlace.autocomplete.get(value);
    }

    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions!;
      });
    }

  }
}
