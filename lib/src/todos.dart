import 'dart:async';
import 'dart:io';
import 'dart:convert';

// import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class ToDoItem {
  static const String $title = 'title';
  static const String $description = 'description';
  static const String $is_urgent = 'is_urgent';
  static const String $is_done = 'is_done';
  static const String $created_at = 'created_at';

  String title = '';
  String description = '';
  bool is_urgent = false;
  bool is_done = false;
  int created_at = 0;

  DateTime get created {
    final cr =
        DateTime.fromMillisecondsSinceEpoch(created_at, isUtc: true).toLocal();
    if (cr.year > 2050) return DateTime.now();
      else return cr;
  }

  set created(DateTime dt) => created_at = dt.toUtc().millisecondsSinceEpoch;

  ToDoItem() {
    created = DateTime.now();
  }

  factory ToDoItem.fromMap(Map m) => ToDoItem()
    ..title = m[$title] ?? ''
    ..description = m[$description] ?? ''
    ..is_done = m[$is_done] ?? false
    ..is_urgent = m[$is_urgent] ?? false
    ..created_at = m[$created_at] ?? 0;

  Map<String, dynamic> toMap() => {
        $title: title,
        $description: description,
        $is_urgent: is_urgent,
        $created_at: created_at,
        $is_done: is_done,
      };

  Map<String, dynamic> toJson() => toMap();
}

class ToDoList {
  static String fPath(String layout) => 'data_$layout.json';
  Map<String, List<ToDoItem>> _items = {};
  Map<String, bool> _loaded = {};
  String layout = 'en';

  ToDoList();

  int get length => _items[layout]?.length ?? 0;

  ToDoItem removeAt(int idx) => _items[layout]!.removeAt(idx);

  int indexOf(ToDoItem o) => _items[layout]?.indexOf(o) ?? -1;

  bool remove(ToDoItem o) {
    final idx = indexOf(o);
    if (idx < 0) return false;

    for (final l in _items.keys) _items[l]!.removeAt(idx);
    return true;
  }

  bool setCreated(ToDoItem o, DateTime ct) {
    final idx = indexOf(o);
    if (idx < 0) return false;

    for (final l in _items.keys) _items[l]![idx].created = ct;
    return true;
  }

  bool setDone(ToDoItem o, bool done) {
    final idx = indexOf(o);
    if (idx < 0) return false;

    for (final l in _items.keys) _items[l]![idx].is_done = done;
    return true;
  }

  bool setUrgent(ToDoItem o, bool urg) {
    final idx = indexOf(o);
    if (idx < 0) return false;

    for (final l in _items.keys) _items[l]![idx].is_urgent = urg;
    return true;
  }

  void add(ToDoItem o) {
    for (final k in _items.keys) _items[k]!.add(o);
  }

  void insertAt(int idx, ToDoItem o) {
    for (final k in _items.keys) _items[k]!.insert(idx, o);
  }

  operator [](int idx) => _items[layout]![idx];

  ToDoItem? getItem(ToDoItem o, String layout) {
    if (this.layout == layout) return o;

    final idx = indexOf(o);
    if (idx < 0) return null;
    if (!_items.containsKey(layout)) return null;
    return _items[layout]![idx];
  }

  bool isLoaded(String layout) => _loaded[layout] ?? false;

  Future<bool> save() async {
    final dapp = await getApplicationDocumentsDirectory();
    try {
      for (final k in _items.keys) {
        final res = {'todos': _items[k]!.map((el) => el.toJson()).toList()};
        await File('${dapp.path}/${fPath(k)}')
            .writeAsString(json.encode(res));
      }
    } catch (e) {
      print('Error saving todos ! \n $e');
      return false;
    }
    return true;
  }

  Future<List<ToDoItem>> load([String layout = 'en']) async {
    ///Set layout and init items
    this.layout = layout;
    _items[layout] ??= [];
    if (!isLoaded(layout))
      try {
        _loaded[layout] = true;

        late String response;
        final dapp = await getApplicationDocumentsDirectory();
        ///File exists in documents ?
        final f = File('${dapp.path}/${fPath(layout)}');
        if (!f.existsSync()) {
          ///No get it from assets
          response = await rootBundle.loadString(fPath(layout));
          await f.writeAsString(response);
        } else
          response = await f.readAsString();

        final m = json.decode(response);
        if (m is Map && m.containsKey('todos'))
          _items[layout] = m['todos']
              .map((el) => ToDoItem.fromMap(el))
              .toList()
              .cast<ToDoItem>();
      } catch (e) {
        print('Error loading assets $e !');
      }
    return _items[layout]!;
  }
}
