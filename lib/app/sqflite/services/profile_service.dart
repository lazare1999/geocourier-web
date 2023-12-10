import 'package:geo_couriers/app/sqflite/models/profile_model.dart';
import 'package:geo_couriers/app/sqflite/repositories/repository.dart';

class ProfileService {
  late Repository _repositoryProfile;

  ProfileService() {
    _repositoryProfile = Repository();
  }

  Future<void> insert(ProfileModel r) async {
    _repositoryProfile.insertData('profile', r.toMap());
  }

  Future<List<ProfileModel>> getProfileData() async {
    final List<Map<String, dynamic>> maps = await _repositoryProfile.readData('profile');

    return List.generate(maps.length, (i) {
      return ProfileModel(
          id: maps[i]['id'],
          firstName: maps[i]['firstName'],
          lastName: maps[i]['lastName'],
          nickname: maps[i]['nickname'],
          email: maps[i]['email'],
          phoneNumber: maps[i]['phoneNumber'],
          rating: maps[i]['rating'],
      );
    });
  }

  Future<void> deleteAll() async {
    _repositoryProfile.delete('profile');
  }

}