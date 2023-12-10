import 'dart:async';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geo_couriers/app/roles/courier/parcel_locations.dart' as locations;

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../main.dart';

class WorkingModeParcelsWindowPage extends StatefulWidget {
  final ValueChanged<LatLng>? update;
  final String? kGoogleApiKey;

  WorkingModeParcelsWindowPage({this.update, required this.kGoogleApiKey});

  @override
  _WorkingModeParcelsWindowPage createState() => _WorkingModeParcelsWindowPage(update: update, kGoogleApiKey: kGoogleApiKey);
}

class _WorkingModeParcelsWindowPage extends State<WorkingModeParcelsWindowPage> {
  final ValueChanged<LatLng>? update;
  final String? kGoogleApiKey;

  _WorkingModeParcelsWindowPage({this.update, required this.kGoogleApiKey});

  static const _pageSize = 10;

  final PagingController<int, Parcels> _pagingController = PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {

    var newItems = await locations.getParcels(context, true);

    final isLastPage = newItems!.length < _pageSize;
    if (isLastPage) {
      _pagingController.appendLastPage(newItems);
    } else {
      final nextPageKey = pageKey + newItems.length;
      _pagingController.appendPage(newItems, nextPageKey.toInt());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: MyApp.of(context)!.isDarkModeEnabled ? Color(0xFF15202B) : Colors.white,
        title: Center(child: RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: AppLocalizations.of(context)!.takeaway,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                )
              ),
              TextSpan(
                text: " <-> ",
                style: TextStyle(
                  color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                ),
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.delivery,
                style: TextStyle(
                  color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh(),),
        child: PagedListView<int, Parcels>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Parcels>(
            itemBuilder: (context, item, index) {
              return generateCard(
                  Padding(
                      padding: EdgeInsets.only(
                          left: 25.0, right: 25.0, top: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Expanded(
                            child: Icon(Icons.directions_run_rounded, color: item.arrivalInProgress! ? Colors.black : Colors.red),
                          ),
                          Expanded(
                            flex: 3,
                            child: ArgonTimerButton(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.45,
                              minWidth: MediaQuery.of(context).size.width * 0.30,
                              highlightColor: Colors.transparent,
                              highlightElevation: 0,
                              roundLoadingShape: false,
                              onTap: (startTimer, btnState) async {
                                if (btnState == ButtonState.Idle) {
                                  startTimer(15);
                                  showParcelInfoDialog(item, context, kGoogleApiKey!);
                                  item.arrivalInProgress! ?
                                  update!(LatLng(double.parse(item.parcelAddressToBeDeliveredLatitude!), double.parse(item.parcelAddressToBeDeliveredLongitude!))):
                                  update!(LatLng(double.parse(item.parcelPickupAddressLatitude!), double.parse(item.parcelPickupAddressLongitude!)));
                                }
                              },
                              child: Text(
                                item.serviceParcelIdentifiable!,
                              ),
                              loader: (timeLeft) {
                                return Text(
                                  AppLocalizations.of(context)!.please_wait + " | $timeLeft",
                                  style: TextStyle(
                                      color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                      fontSize: 15
                                  ),
                                );
                              },
                              borderRadius: 18.0,
                              color: Colors.transparent,
                              elevation: 0,
                            ),
                          ),
                        ],
                      )
                  ), 10.0
              );
            },
          ),
          separatorBuilder: (context, index) => const Divider(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}