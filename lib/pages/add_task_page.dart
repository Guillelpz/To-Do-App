import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTask extends StatefulWidget {
  const AddTask({super.key});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  final TextEditingController _controller = TextEditingController();
  Recurrence _recurrence = Recurrence.once;

  void _guardar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para la tarea')),
      );
      return;
    }
    final task = Task(title: texto, recurrence: _recurrence);
    Navigator.pop(context, task);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tarea')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Título de la tarea',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _guardar(),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Recurrencia:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Recurrence>(
                    value: _recurrence,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: Recurrence.once,   child: Text('Una sola vez')),
                      DropdownMenuItem(value: Recurrence.daily,  child: Text('Diaria')),
                      DropdownMenuItem(value: Recurrence.weekly, child: Text('Semanal')),
                    ],
                    onChanged: (r) => setState(() => _recurrence = r ?? Recurrence.once),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardar,
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
