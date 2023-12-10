import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/mini_menu/users_info/models/users_info_model.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../main.dart';
import '../../commons/models/parcels_model.dart';

class HandOverParcelsToCourierUsersPage extends StatefulWidget {
  final List<int?> checkedParcels;
  final PagingController<int, Parcels> pagingController;

  HandOverParcelsToCourierUsersPage({required this.checkedParcels, required this.pagingController});

  @override
  _HandOverParcelsToCourierUsersPage createState() => _HandOverParcelsToCourierUsersPage(checkedParcels: checkedParcels, pagingController: pagingController);
}


class _HandOverParcelsToCourierUsersPage extends State<HandOverParcelsToCourierUsersPage> {
  final List<int?> checkedParcels;
  final PagingController<int, Parcels> pagingController;

  _HandOverParcelsToCourierUsersPage({required this.checkedParcels, required this.pagingController});

  static const _pageSize = 10;

  final PagingController<int, UsersInfoModel> _pagingController = PagingController(firstPageKey: 0);

  var _searchOnlyFavorite = false;

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
          'miniMenu/all_users',
          queryParameters: {
            "pageKey": pageKey.toString(),
            "pageSize": _pageSize.toString(),
            "searchOnlyFavorite": _searchOnlyFavorite.toString(),
          }
      );

      if(res.statusCode ==200) {
        List<UsersInfoModel> newItems = List<UsersInfoModel>.from(res.data.map((i) => UsersInfoModel.fromJson(i)));

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
        // title: Text(AppLocalizations.of(context)!.users),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh(),),
        child: PagedListView<int, UsersInfoModel>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<UsersInfoModel>(
            itemBuilder: (context, item, index) {

              var _firstLastName = (item.firstName ==null ? "" : item.firstName)! + " " + (item.lastName ==null ? "" : item.lastName!) + " " + (item.mainNickname ==null ? "" : item.mainNickname!);
              if (item.nickname !=null && item.nickname!.isNotEmpty) {
                _firstLastName = item.nickname!;
              }

              return generateCard(
                  Padding(
                      padding: EdgeInsets.only(
                          left: 25.0, right: 25.0, top: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: ListTile(
                              title: Text(
                                _firstLastName,
                                style: TextStyle(
                                  color: item.isFav! ? Colors.deepOrange : MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                ),
                              ),
                              onTap: () async {
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(' '),
                                      content: Text(AppLocalizations.of(context)!.hand_over_job_question),
                                      actions: <Widget>[
                                        OutlinedButton(
                                          child: Text(AppLocalizations.of(context)!.yes),
                                          onPressed: () async {

                                            try {

                                              await geoCourierClient.post(
                                                'courier_company/hand_over_job_to_company_courier',
                                                queryParameters: {
                                                  "checkedParcels": checkedParcels.toString(),
                                                  "courierUserId": item.userId.toString(),
                                                },
                                              );

                                              pagingController.refresh();
                                              Navigator.pop(context, false);
                                              Navigator.pop(context, false);

                                            } catch (e) {
                                              if (e is DioException && e.response?.statusCode == 403) {
                                                reloadApp(context);
                                              } else {
                                                showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                                              }
                                              return;
                                            }
                                          }, //exit the app
                                        ),
                                        OutlinedButton(
                                          child: Text(AppLocalizations.of(context)!.no),
                                          onPressed: ()=> Navigator.pop(context,false),
                                        )
                                      ],
                                    )
                                );
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
            FloatingActionButton(
              heroTag: "btn1",
              child: Icon(CustomIcons.fb_messenger),
              onPressed: () {
                launchUrl(Uri.parse("http://" +dotenv.env['MESSENGER']!), mode: LaunchMode.externalApplication);
              },
            ),
            FloatingActionButton(
              child: Icon(_searchOnlyFavorite ? Icons.star : Icons.star_border_outlined),
              onPressed: () {
                setState(() {
                  this._searchOnlyFavorite = !_searchOnlyFavorite;
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