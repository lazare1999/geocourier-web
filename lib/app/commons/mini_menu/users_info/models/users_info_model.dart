class UsersInfoModel {
  UsersInfoModel({
    this.userId,
    this.username,
    this.firstName,
    this.lastName,
    this.rating,
    this.nickname,
    this.mainNickname,
    this.isFav,
  });

  factory UsersInfoModel.fromJson(Map<String, dynamic> json) =>
      UsersInfoModel(
        userId: json['userId'],
        username: json['username'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        rating: json['rating'],
        nickname: json['nickname'],
        mainNickname: json['mainNickname'],
        isFav: json['isFav'],
      );

  final int? userId;
  final String? username;
  final String? firstName;
  final String? lastName;
  final double? rating;
  final String? nickname;
  final String? mainNickname;
  final bool? isFav;

}