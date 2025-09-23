import 'package:flutter/material.dart';

class Saludo extends StatefulWidget {
  const Saludo({super.key});

  @override
  State<Saludo> createState() => _SaludoState();
}

class _SaludoState extends State<Saludo> {
  String nombre = 'Mundo';
  final TextEditingController _controller = TextEditingController();

  void actualizarNombre() {
    setState(() {
      // si el campo no está vacío, actualizamos el saludo
      if (_controller.text.trim().isNotEmpty) {
        nombre = _controller.text.trim();
        _controller.clear(); // opcional: vacía el campo después
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor escribe un nombre'),
            duration: Duration(seconds: 2), // opcional: duración del mensaje
            behavior: SnackBarBehavior.floating, // opcional: flota sin pegarse abajo
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () {
                // aquí SÍ cambias estado, por lo que necesitas setState
                setState(() {
                  nombre = 'lalala';
                });
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // libera el controlador
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saludo interactivo')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hola, $nombre',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Escribe tu nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: actualizarNombre,
              child: const Text('Actualizar saludo'),
            ),
          ],
        ),
      ),
    );
  }
}
