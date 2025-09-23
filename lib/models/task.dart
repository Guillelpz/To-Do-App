import 'package:flutter/foundation.dart';

enum Recurrence { once, daily, weekly }

String recurrenceToString(Recurrence r) {
  switch (r) {
    case Recurrence.once:   return 'once';
    case Recurrence.daily:  return 'daily';
    case Recurrence.weekly: return 'weekly';
  }
}

Recurrence recurrenceFromString(String s) {
  switch (s) {
    case 'daily':  return Recurrence.daily;
    case 'weekly': return Recurrence.weekly;
    case 'once':
    default:       return Recurrence.once;
  }
}

@immutable
class Task {
  final String title;
  final bool completed;
  final Recurrence recurrence;

  const Task({
    required this.title,
    this.completed = false,
    this.recurrence = Recurrence.once,
  });

  Task copyWith({String? title, bool? completed, Recurrence? recurrence}) {
    return Task(
      title: title ?? this.title,
      completed: completed ?? this.completed,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'completed': completed,
        'recurrence': recurrenceToString(recurrence),
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        title: map['title'] as String,
        completed: (map['completed'] as bool?) ?? false,
        recurrence: recurrenceFromString(map['recurrence'] as String? ?? 'once'),
      );
}
