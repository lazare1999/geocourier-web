import 'dart:convert';

import 'package:geo_couriers/utils/lazo_utils.dart';

AuthenticationResponse authenticationResponseFromJson(String str) => AuthenticationResponse.fromJson(json.decode(str));

String authenticationResponseToJson(AuthenticationResponse data) => json.encode(data.toJson());

class AuthenticationResponse {
  AuthenticationResponse({
    this.jwt,
    this.expiresIn,
    this.expiresAt,
    this.refreshToken,
    this.refreshExpiresIn,
    this.refreshExpiresAt,
  });

  String? jwt;
  int? expiresIn;
  DateTime? expiresAt;
  String? refreshToken;
  int? refreshExpiresIn;
  DateTime? refreshExpiresAt;

  factory AuthenticationResponse.fromJson(Map<String, dynamic> json) => AuthenticationResponse(
    jwt: json["jwt"],
    expiresIn: json["expiresIn"],
    refreshToken: json["refreshToken"],
    refreshExpiresIn: json["refreshExpiresIn"],
  );

  Map<String, dynamic> toJson() => {
    "jwt": jwt,
    "expiresIn": expiresIn,
    "refreshToken": refreshToken,
    "refreshExpiresIn": refreshExpiresIn,
  };

  void update(var body) {

    if (body == null) {
      return;
    }
    if (body.containsKey("jwt")) {
      this.jwt = body["jwt"];
    }
    if (body.containsKey("refreshToken")) {
      this.refreshToken = body["refreshToken"];
    }
    if (body.containsKey("expiresIn")) {

      if (isInteger(body["expiresIn"])) {
        this.expiresIn = body["expiresIn"];
      } else {
        this.expiresIn = int.parse(body["expiresIn"]);
      }

      this.expiresAt = DateTime.fromMillisecondsSinceEpoch(this.expiresIn!);
    }
    if (body.containsKey("refreshExpiresIn")) {

      if (isInteger(body["refreshExpiresIn"])) {
        this.refreshExpiresIn = body["refreshExpiresIn"];
      } else {
        this.refreshExpiresIn = int.parse(body["refreshExpiresIn"]);
      }

      this.refreshExpiresAt = DateTime.fromMillisecondsSinceEpoch(this.refreshExpiresIn!);
    }
  }

}