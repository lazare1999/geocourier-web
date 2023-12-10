class ProfileModel {
  int? id;
  String? firstName;
  String? lastName;
  String? nickname;
  String? email;
  String? phoneNumber;
  String? rating;

  ProfileModel({this.id, this.firstName, this.lastName, this.nickname, this.email, this.phoneNumber, this.rating});

  Map<String, dynamic> toMap() {
    return {
      'id': id !=null ? id.toString() : "",
      'firstName': firstName !=null ? firstName : "",
      'lastName': lastName !=null ? lastName : "",
      'nickname': nickname !=null ? nickname : "",
      'email': email !=null ? email : "",
      'phoneNumber': phoneNumber !=null ? phoneNumber : "",
      'rating': rating !=null ? rating : "0",
    };
  }

  void updateProfile(var body) {

    if (body == null) {
      return;
    }
    if (body.containsKey("userId")) {
      this.id = body["userId"] ==null ? 0 : body["userId"];
    } else {
      this.id = 0;
    }
    if (body.containsKey("email")) {
      this.email = body["email"] ==null ? "" : body["email"].toString();
    } else {
      this.email = "";
    }
    if (body.containsKey("firstName")) {
      this.firstName = body["firstName"] ==null ? "" : body["firstName"].toString();
    } else {
      this.firstName = "";
    }
    if (body.containsKey("lastName")) {
      this.lastName = body["lastName"] ==null ? "" : body["lastName"].toString();
    } else {
      this.lastName = "";
    }
    if (body.containsKey("nickname")) {
      this.nickname = body["nickname"] ==null ? "" : body["nickname"].toString();
    } else {
      this.nickname = "";
    }
    if (body.containsKey("username")) {
      this.phoneNumber = body["username"] ==null ? "" : body["username"].toString();
    } else {
      this.phoneNumber = "";
    }
    if (body.containsKey("rating")) {
      this.rating = body["rating"] ==null ? "0" : body["rating"].toString();
    } else {
      this.rating = "0";
    }
  }
}