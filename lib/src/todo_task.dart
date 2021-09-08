import 'dart:html';

import 'package:flutter/material.dart';

// import 'package:flutter/services.dart';
import 'todos.dart' as d;

class TodoList extends StatefulWidget {
  static String layout = 'en';
  static d.ToDoList? tdl;

  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  d.ToDoList? get tdl => TodoList.tdl;

  set tdl(d.ToDoList? t) => TodoList.tdl = t;

  String get layout => TodoList.layout;

  set layout(String l) => TodoList.layout = l;

  void _toggleTodo(d.ToDoItem todo, bool? is_done) {
    setState(() {
      tdl!.setDone(todo, is_done ?? false);
    });
  }

  String formatDate(DateTime? dt) => dt != null
      ? '${dt.day.toString().padLeft(2, '0')}.'
          '${dt.month.toString().padLeft(2, '0')}.'
          '${dt.year.toString()} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}'
      : '';

  Widget _buildItem(BuildContext context, int index) {
    final todo = tdl![index];

    return Padding(
        padding: EdgeInsets.all(8),
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
                padding: EdgeInsets.all(11),
                child: CheckboxListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  value: todo.is_done,
                  secondary: Icon(todo.is_urgent ? Icons.warning : Icons.task),
                  title: Text(
                    '${todo.title} ${formatDate(todo.created)}',
                    style: TextStyle(fontSize: 18),
                  ),
                  tileColor:
                      todo.is_urgent ? Color(0xFFE57373) : Color(0xFFA5D6A7),
                  checkColor: Colors.red,
                  subtitle: Row(textDirection: TextDirection.ltr, children: [
                    Expanded(child: Text(todo.description)),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          tdl!.remove(todo);
                        });
                      },
                    ),
                    IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _displayDialog(context, item: todo);
                        })
                  ]),
                  onChanged: (bool? isChecked) => _toggleTodo(todo, isChecked),
                )),
            semanticContainer: true,
            shadowColor: Colors.blueGrey));
  }

  @override
  Future<d.ToDoList> _load() async {
    tdl ??= d.ToDoList();

    //Load both layouts
    await tdl!.load('bg');
    await tdl!.load('en');
    tdl!.layout = layout;
    return tdl!;
  }

  Widget build(BuildContext context) {
    return FutureBuilder<d.ToDoList>(
        future: _load(),
        builder: (BuildContext context, AsyncSnapshot<d.ToDoList> snapshot) {
          return Scaffold(
              appBar: AppBar(
                  title: Row(children: [
                Expanded(child: Text('Language')),
                DropdownButton(
                    items: [
                      DropdownMenuItem<String>(
                          value: 'en', child: Text('English')),
                      DropdownMenuItem<String>(
                          value: 'bg', child: Text('Български')),
                    ],
                    value: layout,
                    icon: const Icon(Icons.arrow_downward),
                    iconSize: 24,
                    elevation: 16,
                    style: const TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        layout = newValue!;
                      });
                    })
              ])),
              body: ListView.builder(
                itemBuilder: _buildItem,
                itemCount: tdl!.length,
              ));
        });
  }

  // display a dialog for the user to enter items
  Future<AlertDialog?> _displayDialog(BuildContext context,
      {d.ToDoItem? item}) async {
    item ??= d.ToDoItem();
    // alter the app state to show a dialog
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          String title = item!.title;
          String body = item!.description;
          bool is_done = item!.is_done;
          bool is_urgent = item!.is_urgent;

          return StatefulBuilder(// StatefulBuilder
              builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Task'),
              content: Column(children: [
                Row(children: [
                  Expanded(child: Text('Language')),
                  DropdownButton(
                      items: [
                        DropdownMenuItem<String>(
                            value: 'en', child: Text('English')),
                        DropdownMenuItem<String>(
                            value: 'bg', child: Text('Български')),
                      ],
                      value: layout,
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          if (newValue != null) {
                            item = tdl!.getItem(item!, newValue);
                            Navigator.of(context).pop();
                            layout = newValue;
                            tdl!.layout = newValue;

                            if (item != null)
                              _displayDialog(context, item: item);
                          } else
                            print('Error getting right layout!');
                        });
                      })
                ]),
                TextField(
                  controller: TextEditingController(text: title),
                  decoration: const InputDecoration(labelText: 'Task title'),
                  onChanged: (val) {
                    title = val;
                  },
                ),
                TextField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  controller: TextEditingController(text: body),
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (val) {
                    body = val;
                  },
                ),
                CheckboxListTile(
                    title: Text('Is urgent'),
                    value: is_urgent,
                    onChanged: (checked) {
                      setDialogState(() {
                        is_urgent = checked!;
                      });
                    }),
                CheckboxListTile(
                    title: Text('Is done'),
                    value: is_done,
                    onChanged: (checked) {
                      setDialogState(() {
                        is_done = checked!;
                      });
                    }),
              ]),
              actions: <Widget>[
                // add button
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    Navigator.of(context).pop();

                    setState(() {
                      item!
                        ..is_urgent = is_urgent
                        ..is_done = is_done
                        ..title = title
                        ..description = body;

                      if (tdl!.indexOf(item!) == -1)
                        tdl!.add(item!);
                      else
                        tdl!
                          ..setUrgent(item!, is_urgent)
                          ..setDone(item!, is_done);
                    });
                  },
                ),
                // cancel button
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
        });
  }
}
/*

 */
