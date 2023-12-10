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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../main.dart';

class ChooseFavCourierCompanyUsersPage extends StatefulWidget {

  @override
  _ChooseFavCourierCompanyUsersPage createState() => _ChooseFavCourierCompanyUsersPage();
}


class _ChooseFavCourierCompanyUsersPage extends State<ChooseFavCourierCompanyUsersPage> {

  static const _pageSize = 10;

  bool _searchOnlyFavorite = false;

  final PagingController<int, UsersInfoModel> _pagingController = PagingController(firstPageKey: 0);

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
        title: Text(""),
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
                                try {

                                  await geoCourierClient.post(
                                      'miniMenu/choose_fav_courier_company',
                                      queryParameters: {
                                        "favouriteCourierCompanyId": item.userId.toString(),
                                      }
                                  );

                                  final SharedPreferences _prefs = await SharedPreferences.getInstance();
                                  _prefs.setInt("fav_courier_company_id", item.userId!);
                                  navigateToLastPage(context);

                                } catch (e) {
                                  if (e is DioException && e.response?.statusCode == 403) {
                                    reloadApp(context);
                                  } else {
                                    showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
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