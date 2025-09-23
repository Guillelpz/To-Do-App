import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'add_task_page.dart' as add;

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _prefsTasksKey = 'tasks_v2';
  static const _prefsDayKey   = 'lastDayKey_v1';
  static const _prefsWeekKey  = 'lastWeekKey_v1';

  final List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAndMaybeReset();
  }

  // --- Helpers de periodo ---
  String _dayKey(DateTime d) {
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime _startOfWeek(DateTime d) {
    // Lunes como inicio de semana
    final local = d.toLocal();
    final weekday = local.weekday; // 1 = Lunes ... 7 = Domingo
    return DateTime(local.year, local.month, local.day).subtract(Duration(days: weekday - 1));
  }

  String _weekKey(DateTime d) {
    final monday = _startOfWeek(d);
    final y = monday.year.toString().padLeft(4, '0');
    final m = monday.month.toString().padLeft(2, '0');
    final day = monday.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _loadAndMaybeReset() async {
    final now = DateTime.now();
    final currentDayKey  = _dayKey(now);
    final currentWeekKey = _weekKey(now);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar tareas
      final raw = prefs.getString(_prefsTasksKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw) as List;
        _tasks
          ..clear()
          ..addAll(decoded.map((e) => Task.fromMap(e as Map<String, dynamic>)));
      }

      // Comparar y resetear si cambiaron periodos
      final lastDayKey  = prefs.getString(_prefsDayKey);
      final lastWeekKey = prefs.getString(_prefsWeekKey);

      bool changed = false;

      if (lastDayKey == null || lastDayKey != currentDayKey) {
        // Reset diario
        for (var i = 0; i < _tasks.length; i++) {
          final t = _tasks[i];
          if (t.recurrence == Recurrence.daily && t.completed) {
            _tasks[i] = t.copyWith(completed: false);
            changed = true;
          }
        }
        await prefs.setString(_prefsDayKey, currentDayKey);
      }

      if (lastWeekKey == null || lastWeekKey != currentWeekKey) {
        // Reset semanal
        for (var i = 0; i < _tasks.length; i++) {
          final t = _tasks[i];
          if (t.recurrence == Recurrence.weekly && t.completed) {
            _tasks[i] = t.copyWith(completed: false);
            changed = true;
          }
        }
        await prefs.setString(_prefsWeekKey, currentWeekKey);
      }

      if (changed) {
        // Guardar la lista reseteada
        await _saveTasks(prefs: prefs);
      }
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar o resetear las tareas')),
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveTasks({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => t.toMap()).toList();
    await p.setString(_prefsTasksKey, jsonEncode(jsonList));
  }

  Future<void> _irANuevaTarea() async {
    final Task? nueva = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const add.AddTask()),
    );
    if (nueva != null) {
      setState(() => _tasks.add(nueva));
      await _saveTasks();
    }
  }

  Future<void> _toggleComplete(int index, bool? value) async {
    final t = _tasks[index];
    setState(() {
      _tasks[index] = t.copyWith(completed: value ?? false);
    });
    await _saveTasks();
  }

  Future<void> _eliminar(int index) async {
    final eliminada = _tasks.removeAt(index);
    setState(() {});
    await _saveTasks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Eliminada: ${eliminada.title}')),
    );
  }

  Future<bool?> _confirmarBorrado(Task task) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Seguro que quieres eliminar "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
  }

  String _recurrenceLabel(Recurrence r) {
    switch (r) {
      case Recurrence.once:   return 'Una sola vez';
      case Recurrence.daily:  return 'Diaria';
      case Recurrence.weekly: return 'Semanal';
    }
  }

  IconData _recurrenceIcon(Recurrence r) {
    switch (r) {
      case Recurrence.once:   return Icons.radio_button_unchecked;
      case Recurrence.daily:  return Icons.calendar_today;
      case Recurrence.weekly: return Icons.date_range;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis tareas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis tareas')),
      body: _tasks.isEmpty
          ? const Center(child: Text('No hay tareas. ¡Agrega la primera!'))
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Dismissible(
                  key: ValueKey('${task.title}-${task.recurrence}-$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete),
                  ),
                  confirmDismiss: (_) => _confirmarBorrado(task),
                  onDismissed: (_) => _eliminar(index),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.completed,
                      onChanged: (v) => _toggleComplete(index, v),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(_recurrenceIcon(task.recurrence), size: 16),
                        const SizedBox(width: 6),
                        Text(_recurrenceLabel(task.recurrence)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await _confirmarBorrado(task) ?? false;
                        if (ok) _eliminar(index);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irANuevaTarea,
        child: const Icon(Icons.add),
      ),
    );
  }
}
