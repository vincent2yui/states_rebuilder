// Copyright 2018 The Flutter Architecture Sample Authors. All rights reserved.
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:clean_architecture_todo_mvc/domain/entities/todo.dart';
import 'package:clean_architecture_todo_mvc/service/todos_service.dart';
import 'package:clean_architecture_todo_mvc/ui/exceptions/error_handler.dart';
import 'package:todos_app_core/todos_app_core.dart';

class AddEditPage extends StatefulWidget {
  final ReactiveModel<Todo> todoRM;

  AddEditPage({
    Key key,
    this.todoRM,
  }) : super(key: key ?? ArchSampleKeys.addTodoScreen);

  @override
  _AddEditPageState createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  static final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  // Here we use a StatefulWidget to hold local fields _task and _note
  String _task;
  String _note;
  bool get isEditing => widget.todoRM != null;
  Todo get todo => widget.todoRM?.state;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? ArchSampleLocalizations.of(context).editTodo
            : ArchSampleLocalizations.of(context).addTodo),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          autovalidate: false,
          onWillPop: () {
            return Future(() => true);
          },
          child: ListView(
            children: [
              TextFormField(
                initialValue: todo != null ? todo.task : '',
                key: ArchSampleKeys.taskField,
                autofocus: isEditing ? false : true,
                style: Theme.of(context).textTheme.headline5,
                decoration: InputDecoration(
                    hintText: ArchSampleLocalizations.of(context).newTodoHint),
                validator: (val) => val.trim().isEmpty
                    ? ArchSampleLocalizations.of(context).emptyTodoError
                    : null,
                onSaved: (value) => _task = value,
              ),
              TextFormField(
                initialValue: todo != null ? todo.note : '',
                key: ArchSampleKeys.noteField,
                maxLines: 10,
                style: Theme.of(context).textTheme.subtitle1,
                decoration: InputDecoration(
                  hintText: ArchSampleLocalizations.of(context).notesHint,
                ),
                onSaved: (value) => _note = value,
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key:
            isEditing ? ArchSampleKeys.saveTodoFab : ArchSampleKeys.saveNewTodo,
        tooltip: isEditing
            ? ArchSampleLocalizations.of(context).saveChanges
            : ArchSampleLocalizations.of(context).addTodo,
        child: Icon(isEditing ? Icons.check : Icons.add),
        onPressed: () {
          final form = formKey.currentState;
          if (form.validate()) {
            form.save();
            if (isEditing) {
              final oldTodo = todo;
              final newTodo = todo.copyWith(
                task: _task,
                note: _note,
              );
              widget.todoRM.setState(
                (s) async {
                  widget.todoRM.state = newTodo;
                  Navigator.pop(context, newTodo);
                  await IN.get<TodosService>().updateTodo(todo);
                },
                watch: (todoRM) => widget.todoRM.hasError,
                onError: (context, error) {
                  widget.todoRM.state = oldTodo;
                  ErrorHandler.showErrorSnackBar(context, error);
                },
              );
            } else {
              RM.get<TodosService>().setState(
                (s) {
                  Navigator.pop(context);
                  return s.addTodo(Todo(_task, note: _note));
                },
                onError: ErrorHandler.showErrorSnackBar,
              );
            }
          }
        },
      ),
    );
  }
}
