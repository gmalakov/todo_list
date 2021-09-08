import 'dart:async';
import 'package:flutter/material.dart';

// import 'package:flutter/services.dart';
import 'todos.dart' as d;

const minHours = 1;

class TodoList extends StatefulWidget {
  static String layout = 'en';
  static d.ToDoList? tdl;
  static Timer? sch;

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

  DateTime? parseDate(String ds) {
    if (ds.isEmpty) return null;
    final dt = ds.trim().split(' ');
    if (dt.length < 2) return null;
    final dtl = dt.first
        .split('.')
        .map((el) => int.tryParse(el) ?? 0)
        .toList()
        .cast<int>();
    final ttl = dt.last
        .split(':')
        .map((el) => int.tryParse(el) ?? 0)
        .toList()
        .cast<int>();
    return DateTime(dtl[2], dtl[1], dtl[0], ttl[0], ttl[1], ttl[2]);
  }

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

  void timSvc(Timer? t) {
    final now = DateTime.now().toUtc();
    for (int i = 0; i < tdl!.length; i++) {
      final cd = tdl![i].created;
      if (!(now.isBefore(cd)) || now.difference(cd).inHours < minHours) {
        tdl!.setUrgent(tdl![i], true);
      }
    }
  }

  Widget build(BuildContext context) {
    TodoList.sch ??= Timer.periodic(const Duration(minutes: 1), timSvc);

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
          DateTime currentDate = item!.created;

          return StatefulBuilder(// StatefulBuilder
              builder: (context, setDialogState) {
            Future<void> _selectDate(BuildContext context) async {
              final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: currentDate,
                  locale: Locale(layout),
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2050));
              if (pickedDate != null && pickedDate != currentDate)
                setDialogState(() {
                  currentDate = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      currentDate.hour,
                      currentDate.minute,
                      currentDate.second);
                });
            }

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
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller:
                          TextEditingController(text: formatDate(currentDate)),
                      decoration:
                          const InputDecoration(labelText: 'Task title'),
                      onChanged: (val) {
                        currentDate = parseDate(val) ?? DateTime(2020);
                      },
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text('Select date'),
                    ),
                  ],
                ),
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
                        ..description = body
                        ..created = currentDate;

                      if (tdl!.indexOf(item!) == -1)
                        tdl!.add(item!);
                      else
                        tdl!
                          ..setUrgent(item!, is_urgent)
                          ..setDone(item!, is_done)
                          ..setCreated(item!, currentDate);
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
