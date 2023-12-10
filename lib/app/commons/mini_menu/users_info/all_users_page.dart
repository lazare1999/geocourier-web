import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/mini_menu/users_info/models/users_info_model.dart';
import 'package:geo_couriers/app/commons/star_rating.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../main.dart';

class AllUsersPage extends StatefulWidget {
  @override
  _AllUsersPage createState() => _AllUsersPage();
}


class _AllUsersPage extends State<AllUsersPage> {

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
        },
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
        title: Text(AppLocalizations.of(context)!.users),
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
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Container(
                                      height: 200,
                                      color: Colors.white,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            MaterialButton(
                                              child: Text(AppLocalizations.of(context)!.rating),
                                              onPressed: () async {
                                                int? _userDeliveredParcelsCount = 0;
                                                int? _userSuccessfullyCompletedJobsCount = 0;

                                                try {

                                                  final res = await geoCourierClient.post(
                                                    'miniMenu/fav_user_statistics',
                                                    queryParameters: {
                                                      "favUserId": item.userId.toString(),
                                                    },
                                                  );

                                                  if(res.statusCode ==200) {
                                                    var body = res.data;
                                                    _userDeliveredParcelsCount = body["userDeliveredParcelsCount"];
                                                    _userSuccessfullyCompletedJobsCount = body["userSuccessfullyCompletedJobsCount"];
                                                  }

                                                } catch (e) {
                                                  if (e is DioException && e.response?.statusCode == 403) {
                                                    reloadApp(context);
                                                  } else {
                                                    showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                                                  }
                                                  return;
                                                }

                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    content: Container(
                                                      child: Form(
                                                        child: Scrollbar(
                                                          child: SingleChildScrollView(
                                                            padding: EdgeInsets.all(16),
                                                            child: Column(
                                                              children: [
                                                                ...[
                                                                  StarRating(rating: item.rating !=null ? item.rating : 0),
                                                                  Text(AppLocalizations.of(context)!.delivered_parcels + ": " +_userDeliveredParcelsCount.toString()),
                                                                  Text(AppLocalizations.of(context)!.successfully_completed_jobs + ": " +_userSuccessfullyCompletedJobsCount.toString()),
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
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                );
                                              },
                                            ),
                                            !item.isFav! ? Container() : MaterialButton(
                                              child: Text(AppLocalizations.of(context)!.give_name),
                                              onPressed: () async {

                                                var _nickname = item.nickname;
                                                showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      content: Container(
                                                        child: Form(
                                                          child: Scrollbar(
                                                            child: SingleChildScrollView(
                                                              padding: EdgeInsets.all(16),
                                                              child: Column(
                                                                children: [
                                                                  ...[
                                                                    TextFormField(
                                                                      decoration: InputDecoration(
                                                                        filled: true,
                                                                        labelText: AppLocalizations.of(context)!.give_name,
                                                                      ),
                                                                      initialValue: item.nickname,
                                                                      onChanged: (value) {
                                                                        _nickname = value;
                                                                      },
                                                                    ),
                                                                    MaterialButton(
                                                                        color: Colors.deepOrange,
                                                                        shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(18.0),
                                                                        ),
                                                                        child: Text(
                                                                          AppLocalizations.of(context)!.save,
                                                                          style: TextStyle(color: Colors.white),
                                                                        ),
                                                                        onPressed: () async {
                                                                          try {

                                                                            final res = await geoCourierClient.post(
                                                                              'miniMenu/update_nickname',
                                                                              queryParameters: {
                                                                                "favUserId": item.userId.toString(),
                                                                                "nickname": _nickname.toString(),
                                                                              },
                                                                            );

                                                                            if(res.statusCode ==200) {
                                                                              Navigator.pop(context,false);
                                                                              Navigator.pop(context,false);
                                                                              _pagingController.refresh();
                                                                            }

                                                                          } catch (e) {
                                                                            if (e is DioException && e.response?.statusCode == 403) {
                                                                              reloadApp(context);
                                                                            } else {
                                                                              showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                                                                            }
                                                                            return;
                                                                          }
                                                                        }
                                                                    )
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
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: MaterialButton(
                              child: Icon(
                                  item.isFav! ? Icons.remove_circle_outline : Icons.add,
                                  color: item.isFav! ? Colors.red : Colors.green
                              ),
                              onPressed: () async {
                                if (item.isFav!) {
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(' '),
                                        content: Text(AppLocalizations.of(context)!.unmake_favorite_question),
                                        actions: <Widget>[
                                          OutlinedButton(
                                            child: Text(AppLocalizations.of(context)!.yes),
                                            onPressed: () async {
                                              try {

                                                final res = await geoCourierClient.post(
                                                  'miniMenu/remove_favorite',
                                                  queryParameters: {
                                                    "favoriteUserId": item.userId.toString(),
                                                  },
                                                );

                                                if(res.statusCode ==200) {
                                                  _pagingController.refresh();
                                                  Navigator.pop(context,false);
                                                }

                                              } catch (e) {
                                                if (e is DioException && e.response?.statusCode == 403) {
                                                  reloadApp(context);
                                                } else {
                                                  _pagingController.error = e;
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
                                } else {
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(' '),
                                        content: Text(AppLocalizations.of(context)!.make_favorite_question),
                                        actions: <Widget>[
                                          OutlinedButton(
                                            child: Text(AppLocalizations.of(context)!.yes),
                                            onPressed: () async {
                                              try {

                                                final res = await geoCourierClient.post(
                                                  'miniMenu/add_user_in_favorites',
                                                  queryParameters: {
                                                    "favoriteUserId": item.userId.toString(),
                                                  },
                                                );

                                                if(res.statusCode ==200) {
                                                  _pagingController.refresh();
                                                  Navigator.pop(context,false);
                                                }

                                              } catch (e) {
                                                if (e is DioException && e.response?.statusCode == 403) {
                                                  reloadApp(context);
                                                } else {
                                                  _pagingController.error = e;
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