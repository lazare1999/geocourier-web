import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/roles/sender/models/add_order_page_model.dart';
import 'package:geo_couriers/app/roles/sender/orders/add_orders/places_autocomplete.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryAddressGoogleMap extends StatefulWidget {

  final String? kGoogleApiKey;
  final LatLng? markerValue1;
  final LatLng? markerValue2;
  final AddOrderPageModel? addOrderPageModel;
  final ValueChanged<AddOrderPageModel>? updateAddOrderPageModel;
  final ValueChanged<LatLng>? updateMarker2;

  DeliveryAddressGoogleMap({required this.kGoogleApiKey, required this.markerValue1,
    required this.markerValue2, required this.addOrderPageModel,
    required this.updateAddOrderPageModel, required this.updateMarker2,
  });

  @override
  _DeliveryAddressGoogleMap createState() => _DeliveryAddressGoogleMap(kGoogleApiKey: kGoogleApiKey, markerValue1:
  markerValue1, markerValue2: markerValue2, addOrderPageModel: addOrderPageModel,
    updateAddOrderPageModel: updateAddOrderPageModel,  updateMarker2: updateMarker2,);
}

class _DeliveryAddressGoogleMap extends State<DeliveryAddressGoogleMap> {

  final String? kGoogleApiKey;
  final LatLng? markerValue1;
  late final LatLng? markerValue2;
  final AddOrderPageModel? addOrderPageModel;
  final ValueChanged<AddOrderPageModel>? updateAddOrderPageModel;
  final ValueChanged<LatLng>? updateMarker2;
  Marker? _marker;

  _DeliveryAddressGoogleMap({this.kGoogleApiKey, this.markerValue1, this.addOrderPageModel, this.markerValue2, this.updateAddOrderPageModel , this.updateMarker2});

  LatLng? _cameraPos;
  LatLng? _markerPos;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  Future<void> _onMapCreated(GoogleMapController controller) async {}

  Future<bool> _pageLoad() async {
    if(markerValue2 !=null) {
      _cameraPos = markerValue2;
      _markerPos = markerValue2;
    } else {
      Position position = await Geolocator.getCurrentPosition();
      _cameraPos = LatLng(position.latitude, position.longitude);
      _markerPos = _cameraPos;
    }

    var path = 'assets/images/parcels/black/empty.png';
    var _icon;
    if(kIsWeb) {
      _icon = await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), path);
    } else {
      final Uint8List markerIcon = await getBytesFromAsset(path, 200);
      _icon = BitmapDescriptor.fromBytes(markerIcon);
    }

    _marker = Marker(
        icon: _icon,
        draggable: true,
        markerId: MarkerId('Receivable_address_marker_id'),
        infoWindow: InfoWindow(title: AppLocalizations.of(context)!.save, onTap: () async {

          if (addOrderPageModel!.parcelPickupAddressLatitude !=null &&
              addOrderPageModel!.parcelPickupAddressLongitude !=null) {

            if (addOrderPageModel!.parcelPickupAddressLatitude == _markerPos!.latitude &&
                addOrderPageModel!.parcelPickupAddressLongitude == _markerPos!.longitude) {

              showAlertDialog(context, AppLocalizations.of(context)!.same_as_the_takeaway_address, "");
              return;
            }
          }

          addOrderPageModel!.parcelAddressToBeDeliveredLatitude = _markerPos!.latitude;
          addOrderPageModel!.parcelAddressToBeDeliveredLongitude = _markerPos!.longitude;

          if (kIsWeb) {
            var addressComponents = await getPlaceViaCoordinates(_markerPos!.latitude, _markerPos!.longitude, kGoogleApiKey, context);
            if (addressComponents !=null) {
              addOrderPageModel!.toBeDeliveredCountryCode = addressComponents.firstWhere((entry) => entry['types'].contains('country'))['short_name'];
              addOrderPageModel!.toBeDeliveredAdminArea =  addressComponents.firstWhere((entry) => entry['types'].contains('administrative_area_level_1'))['long_name'];
            }
          } else {
            var address = await placemarkFromCoordinates(_markerPos!.latitude, _markerPos!.longitude);
            if (address.length > 0) {
              addOrderPageModel!.toBeDeliveredAdminArea = address[0].administrativeArea;
              addOrderPageModel!.toBeDeliveredCountryCode = address[0].isoCountryCode;
            }
          }

          updateAddOrderPageModel!(addOrderPageModel!);
          Navigator.pop(context);

        }),
        position: LatLng(_cameraPos!.latitude, _cameraPos!.longitude),
        onDragEnd: ((newPosition) {
          _markerPos = newPosition;
          updateMarker2!(_markerPos!);
        })
    );


    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _pageLoad(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                leading: Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () { Navigator.pop(context); },
                    );
                  },
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                    ),
                    onPressed: () {
                      _scaffoldKey.currentState!.openEndDrawer();
                    },
                  )
                ],
              ),
              endDrawer: Drawer(
                  child: Info(
                      safeAreaChild: ListView(
                        children: <Widget>[
                          ListTile(
                            title: Row(
                              children: <Widget>[
                                Image.asset('assets/images/parcels/black/empty.png', width: 30, height: 30,),
                                Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 5.0),
                                      child: Text(AppLocalizations.of(context)!.delivery_address_google_map_info_1),
                                    )
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      youtubeLink: "https://www.youtube.com/watch?v=Cb8gQVwByNM"
                  )
              ),
              resizeToAvoidBottomInset: false,
              body: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _cameraPos!,
                  zoom: 15.0,
                ),
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                markers: Set<Marker>.of(<Marker>[
                  _marker!
                ]),
              ),
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PlacesAutocomplete(markerValue2: markerValue2,
                        updateAddOrderPageModel: updateAddOrderPageModel, markerValue1: markerValue1,
                        addOrderPageModel: addOrderPageModel, kGoogleApiKey: kGoogleApiKey, updateMarker2: updateMarker2)),
                  );

                },
              ),
            );
          } else {
            return AnimationControllerClass();
          }
        }
    );
  }

}