import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/roles/sender/models/Jobs_model.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class DoneJobsPage extends StatefulWidget {
  final bool forCourier;
  final String? kGoogleApiKey;

  DoneJobsPage({required this.forCourier, required this.kGoogleApiKey});

  @override
  _DoneJobsPage createState() => _DoneJobsPage(forCourier: forCourier, kGoogleApiKey: kGoogleApiKey);
}

class _DoneJobsPage extends State<DoneJobsPage> {
  final bool forCourier;
  final String? kGoogleApiKey;

  _DoneJobsPage({required this.forCourier, required this.kGoogleApiKey});

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

      var url ='';
      if (forCourier) {
        url = 'orders_courier/get_done_courier_jobs';
      } else {
        url = 'orders_sender/get_done_jobs';
      }

      final res = await geoCourierClient.post(
        url,
        queryParameters: {
          "pageKey": pageKey.toString(),
          "pageSize": _pageSize.toString(),
        }
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
      appBar: AppBar(),
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
                          Flexible(
                              child: ListTile(
                                  title: Text(item.orderCount.toString()),
                              )
                          ),
                          Flexible(
                              child: ListTile(
                                title: Text(_jobName),
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