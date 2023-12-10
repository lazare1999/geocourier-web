part of 'login_page.dart';

FormData _$FormDataFromJson(Map<String, dynamic> json) {
  return FormData(
    phoneNumber: json['phoneNumber'] as String?,
    password: json['password'] as String?,
  );
}

Map<String, dynamic> _$FormDataToJson(FormData instance) => <String, dynamic>{
  'phoneNumber': instance.phoneNumber,
  'password': instance.password,
};