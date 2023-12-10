import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../main.dart';
import '../../star_rating.dart';
import 'models/notification_model.dart';

class NotificationPage extends StatefulWidget {

  final List topics;

  NotificationPage({required this.topics});

  @override
  _NotificationPage createState() => _NotificationPage(topics: topics);
}


class _NotificationPage extends State<NotificationPage> {

  final List topics;

  _NotificationPage({required this.topics});

  static const _pageSize = 10;
  bool _activeNotifications = true;

  final PagingController<int, NotificationModel> _pagingController = PagingController(firstPageKey: 0);

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
        'miniMenu/get_notifications',
        queryParameters: {
          "pageKey": pageKey.toString(),
          "pageSize": _pageSize.toString(),
          "statusId": _activeNotifications.toString(),
        },
      );

      if(res.statusCode ==200) {
        List<NotificationModel> newItems = List<NotificationModel>.from(res.data.map((i) => NotificationModel.fromJson(i)));

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notification),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh(),),
        child: PagedListView<int, NotificationModel>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<NotificationModel>(
            itemBuilder: (context, item, index) {

              var _body;

              switch (item.body) {
                case "COURIER_APPROVED_JOB" : _body = AppLocalizations.of(context)!.courier_approved_job; break;
                case "JOBS_DONE" : _body = AppLocalizations.of(context)!.jobs_done; break;
                case "HAND_OVER_JOB" : _body = AppLocalizations.of(context)!.hand_over_job; break;
                case "PARCEL_UNSUCCESSFUL" : _body = AppLocalizations.of(context)!.parcel_unsuccessful; break;
                case "COURIER_TOOK_PARCEL" : _body = AppLocalizations.of(context)!.courier_took_parcel; break;
                default : _body = item.body;
              }

              return generateCard(
                  Padding(
                      padding: EdgeInsets.only(
                          left: 25.0, right: 25.0, top: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Expanded(
                            child: ListTile(
                              title: Text(item.title!),
                              onTap: () async {

                                double _rating = 0;
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    double rating = 0;
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return AlertDialog(
                                          content: Container(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ...[
                                                  RichText(
                                                    text: TextSpan(
                                                      text: item.title! + "\n",
                                                      style: TextStyle(
                                                          color: Colors.red,
                                                          fontWeight: FontWeight.bold
                                                      ),
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                            text: _body! + "\n",
                                                            style: TextStyle(
                                                              color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                                            )
                                                        ),
                                                        TextSpan(
                                                          text: item.addDate!.substring(0, 10),
                                                          style: TextStyle(
                                                              color: Colors.red,
                                                              fontWeight: FontWeight.bold
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  item.statusId ==0 && item.mustRateUser ==true ? StarRating(
                                                      rating: rating,
                                                      onRatingChanged: (r) {
                                                        setState(() {
                                                          rating = r;
                                                          _rating = r;
                                                        });
                                                      }
                                                  ) : Text(""),
                                                ].expand(
                                                      (widget) => [
                                                    widget,
                                                    SizedBox(
                                                      height: 25,
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18.0),
                                              side: BorderSide(color: Colors.black)
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );

                                if (item.statusId ==1) {
                                  return;
                                }



                                try {

                                  if (_rating >0) {
                                    await geoCourierClient.post(
                                      'miniMenu/rate_user',
                                      queryParameters: {
                                        "rating": _rating.toString(),
                                        "userId": item.userId.toString(),
                                      },
                                    );
                                  }

                                  await geoCourierClient.post(
                                    'miniMenu/set_notification_status',
                                    queryParameters: {
                                      "notificationId": item.notificationId.toString(),
                                    },
                                  );


                                  _pagingController.refresh();

                                } catch (e) {
                                  if (e is DioException && e.response?.statusCode == 403) {
                                    reloadApp(context);
                                  }
                                  return;
                                }
                              },
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
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            topics.isEmpty ? Container() : ArgonTimerButton(
              height: 50,
              width: MediaQuery.of(context).size.width * 0.6,
              minWidth: MediaQuery.of(context).size.width * 0.5,
              highlightColor: Colors.transparent,
              highlightElevation: 0,
              roundLoadingShape: false,
              onTap: (startTimer, btnState) async {
                if (btnState == ButtonState.Idle) {
                  startTimer(5);
                  if (subscribed.contains(topics.first)) {
                    await FirebaseMessaging.instance
                        .unsubscribeFromTopic(topics.first);
                    await FirebaseFirestore.instance
                        .collection('topics')
                        .doc(token)
                        .update({topics.first: FieldValue.delete()});
                    setState(() {
                      subscribed.remove(topics.first);
                    });
                  } else {

                    await FirebaseMessaging.instance
                        .subscribeToTopic(topics.first);

                    await FirebaseFirestore.instance
                        .collection('topics')
                        .doc(token)
                        .set({topics.first: 'subscribe'},
                        SetOptions(merge: true));
                    setState(() {
                      subscribed.add(topics.first);
                    });
                  }


                }
              },
              child: subscribed.contains(topics.first) ? Text(AppLocalizations.of(context)!.unsubscribe) : Text(AppLocalizations.of(context)!.subscribe),
              loader: (timeLeft) {
                return Text(
                  AppLocalizations.of(context)!.please_wait + " | $timeLeft",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15
                  ),
                );
              },
              borderRadius: 18.0,
              color: Colors.deepOrange,
              elevation: 0,
            ),
            FloatingActionButton(
              child: Icon(_activeNotifications ? Icons.notifications_active : Icons.notifications_active_outlined),
              onPressed: () {
                setState(() {
                  this._activeNotifications = !_activeNotifications;
                  _pagingController.refresh();
                });
              },
            ),
          ],
        ),
      ),

    );
  }


}