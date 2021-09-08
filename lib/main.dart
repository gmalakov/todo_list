import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/todo_task.dart';

void main() {
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo Task',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: Scaffold(
        appBar: AppBar(
            title: Text('ToDo Task')),
        body: TodoList(),
      ),
    );
  }
}
