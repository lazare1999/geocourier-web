part of 'register_page.dart';

FormData _$FormDataFromJson(Map<String, dynamic> json) {

  return FormData(
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    nickname: json['nickname'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    password: json['password'] as String?,
  );
}

Map<String, dynamic> _$FormDataToJson(FormData instance) => <String, dynamic>{
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'nickname': instance.nickname,
  'phoneNumber': instance.phoneNumber,
  'password': instance.password,
};