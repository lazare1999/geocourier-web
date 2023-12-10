import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseConnection {
  setDatabase() async {
    var directory = await getApplicationDocumentsDirectory();
    var path = join(directory.path, 'courier.db');

    var database = await openDatabase(path, version: 2, onCreate: _onCreatingDatabase);
    return database;
  }

  _onCreatingDatabase(Database database, int version) async {
    await database.execute("CREATE TABLE profile(id INTEGER PRIMARY KEY, firstName TEXT, lastName TEXT, nickname TEXT, email TEXT, phoneNumber TEXT, rating TEXT)");
  }

}

