import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class FireMap extends StatefulWidget {

  final int? userId;
  final CameraPosition? initialCameraPosition;
  final int? parcelId;

  FireMap({required this.userId, required this.initialCameraPosition, required this.parcelId});

  State createState() => FireMapState(userId: userId, initialCameraPosition: initialCameraPosition, parcelId: parcelId);
}


class FireMapState extends State<FireMap> {
  final int? userId;
  final CameraPosition? initialCameraPosition;
  final int? parcelId;

  FireMapState({required this.userId, required this.initialCameraPosition, required this.parcelId});

  Timer? _timer;

  Completer<GoogleMapController> _controller = Completer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  Set<Marker> _markers = Set<Marker>();
  BitmapDescriptor? _markerIcon;

  FirebaseFirestore _fireStore = FirebaseFirestore.instance;


  Future<void> _onMapCreated(GoogleMapController controller) async {
    setState(() {
      _controller.complete(controller);
    });
  }

  Future<void> _updateCamera(LatLng latLng) async {
    final GoogleMapController controller = await _controller.future;
    controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: latLng,
      zoom: 18.0,
    )));
  }

  @override
  void initState() {
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 50)), 'assets/icons/courier.png').then((onValue) {_markerIcon = onValue;});
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _updateCourierLocation());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () { Navigator.pop(context,false); },
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

              ],
            ),
            youtubeLink: "https://www.youtube.com/watch?v=Cb8gQVwByNM"
          )
      ),
      body: GoogleMap(
          initialCameraPosition: initialCameraPosition!,
          zoomControlsEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          scrollGesturesEnabled: false,
          onMapCreated: _onMapCreated,
          markers: _markers
      ),
    );
  }
  _updateCourierLocation() async {

    await _fireStore.collection('locations')
        .where('user_id', isEqualTo: userId).where('parcel_id', isEqualTo: parcelId).get()
        .then((event) {
          if (event.docs.isNotEmpty) {
            GeoPoint courierCoordinates = event.docs.first.get("position")["geopoint"];

            var latLng = LatLng(courierCoordinates.latitude, courierCoordinates.longitude);

            _markers.clear();
            _updateCamera(latLng);

            setState(() {
              _markers.add(Marker(
                markerId: MarkerId('courier'),
                position: latLng,
                icon: _markerIcon!,
                // rotation: currentLocation.heading
              ));
            });
          } else if(mounted) {
            Navigator.pop(context);
            setState(() {

            });
          }
        });
  }

  @override
  dispose() {
    _timer?.cancel();
    super.dispose();
  }
}