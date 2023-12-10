import 'dart:async';

import 'package:geo_couriers/app/sqflite/repositories/database_connection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Repository {
  DatabaseConnection? _databaseConnection;

  Repository() {
    _databaseConnection = kIsWeb ? null : DatabaseConnection();
  }

  static Database? _database;

  //ამოწმებს db არსებობს თუ არა
  Future<Database?> get database async {
    if(_database !=null) return _database;
    _database = await _databaseConnection!.setDatabase();
    return _database;
  }

  //ჩაწეროს ინფო ცხრილებში
  insertData(table, values) async {
    var connection = await database;
    return await connection!.insert(table, values);
  }

  //ინფორმაციის წაკითხვა ცხრილებიდან
  readData(table) async {
    var connection = await database;
    return await connection!.query(table);
  }

  readDataById(table, itemId) async {
    var connection = await database;
    return await connection!.query(table, where: 'id=?', whereArgs: [itemId]);
  }

  readDataByColumn(table, column, itemId) async {
    var connection = await database;
    return await connection!.query(table, where: column+'=?', whereArgs: [itemId]);
  }
  //ინფორმაციის წაკითხვა ცხრილებიდან

  //განახლება
  update(table, data) async {
    var connection = await database;
    return await connection!.update(table, data, where: 'id=?', whereArgs: [data['id']]);
  }

  //წაშლა
  delete(table) async {
    var connection = await database;
    return await connection!.delete(table);
  }

  deleteById(table, itemId) async {
    var connection = await database;
    return await connection!.delete(table, where: 'id=?', whereArgs: [itemId]);
  }
  //წაშლა

}