import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/roles/courier/windows/parcels_window_page.dart';
import 'package:geo_couriers/app/roles/sender/models/Jobs_model.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class JobsWindowPage extends StatefulWidget {

  final ValueChanged<LatLng>? update;
  final String? kGoogleApiKey;

  JobsWindowPage({this.update, required this.kGoogleApiKey});

  @override
  _JobsWindowPage createState() => _JobsWindowPage(update: update, kGoogleApiKey: kGoogleApiKey);
}

class _JobsWindowPage extends State<JobsWindowPage> {

  final ValueChanged<LatLng>? update;
  final String? kGoogleApiKey;

  _JobsWindowPage({this.update, required this.kGoogleApiKey});

  List<int?> _alreadyOpenJobWindowParcelIdList = List<int?>.empty(growable: true);
  
  static const _pageSize = 10;

  final PagingController<int, JobsModel> _pagingController = PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {

    if (pageKey >0) {
      pageKey = pageKey - _pageSize +1;
    }

    try {

      final res = await geoCourierClient.post(
        'orders_courier/get_vacant_jobs',
        queryParameters: {
          "pageKey": pageKey.toString(),
          "pageSize": _pageSize.toString(),
        },
      );

      if(res.statusCode ==200) {
        List<JobsModel> newItems = List<JobsModel>.from(res.data.map((i) => JobsModel.fromJson(i)));

        final isLastPage = newItems.length < _pageSize;
        if (isLastPage) {
          _pagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _pagingController.appendPage(newItems, nextPageKey);
        }

      }

    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        reloadApp(context);
      } else {
        _pagingController.error = e;
      }
      return;
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh(),),
        child: PagedListView<int, JobsModel>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<JobsModel>(
            itemBuilder: (context, item, index) {
              var _jobName = "N" + item.orderJobId.toString();
              if (item.jobName !="" && item.jobName !=null) {
                _jobName += " - " + item.jobName!;
              }
              return generateCard(
                  Padding(
                      padding: EdgeInsets.only(
                          left: 25.0, right: 25.0, top: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[


                          item.containsExpressOrder ==true ? Expanded(
                              flex: 1,
                              child: Icon(Icons.star, color: Color.fromRGBO(218,165,32, 1.0),)
                          ) : Visibility(
                            visible: false, child: Container(),
                          ),


                          Expanded(
                              flex: 4,
                              child: ListTile(
                                title: Text(_jobName),
                                onTap: () {
                                  if (_alreadyOpenJobWindowParcelIdList.contains(item.orderJobId)) {
                                    return;
                                  }
                                  setState(() {
                                    _alreadyOpenJobWindowParcelIdList.add(item.orderJobId);
                                  });

                                  showDialog(
                                    context: context,
                                    useSafeArea: false,
                                    useRootNavigator: false,
                                    builder: (context) => AlertDialog(
                                      content: Container(
                                        height: MediaQuery.of(context).size.height * 0.7,
                                        child: ParcelsWindowPage(update: update, orderJobId: item.orderJobId, kGoogleApiKey: kGoogleApiKey),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18.0),
                                          side: BorderSide(color: Colors.black)
                                      ),
                                    ),
                                  ).then((value) => setState(() {
                                    _alreadyOpenJobWindowParcelIdList.remove(item.orderJobId);
                                  }));
                                },
                              )
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