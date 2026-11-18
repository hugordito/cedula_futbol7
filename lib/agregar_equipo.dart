
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgregarEquipo extends StatefulWidget {
  const AgregarEquipo({super.key});

  @override
  State<AgregarEquipo> createState() => _AgregarEquipoState();
}

class _AgregarEquipoState extends State<AgregarEquipo> {
  static const int maxJugadores = 20;

  final nombreEquipo = TextEditingController();

  final numeros = List.generate(
    maxJugadores,
        (_) => TextEditingController(),
  );

  final nombres = List.generate(
    maxJugadores,
        (_) => TextEditingController(),
  );

  bool guardando = false;

  void mostrarMensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  List<Map<String, dynamic>>? obtenerJugadores() {
    final jugadores = <Map<String, dynamic>>[];
    final numerosRegistrados = <int>{};

    for (int i = 0; i < maxJugadores; i++) {
      final textoNumero = numeros[i].text.trim();
      final textoNombre = nombres[i].text.trim();

      if (textoNumero.isEmpty && textoNombre.isEmpty) {
        continue;
      }

      if (textoNumero.isEmpty || textoNombre.isEmpty) {
        mostrarMensaje(
          'Completa el número y nombre '
              'del jugador ${i + 1}',
        );
        return null;
      }

      final numero = int.tryParse(textoNumero);

      if (numero == null ||
          numero < 1 ||
          numero > 99) {
        mostrarMensaje(
          'El número del jugador ${i + 1} '
              'debe estar entre 1 y 99',
        );
        return null;
      }

      if (numerosRegistrados.contains(numero)) {
        mostrarMensaje(
          'El número $numero está repetido',
        );
        return null;
      }

      numerosRegistrados.add(numero);

      jugadores.add({
        'numero': numero,
        'nombre': textoNombre,
      });
    }

    if (jugadores.isEmpty) {
      mostrarMensaje(
        'Registra al menos un jugador',
      );
      return null;
    }

    return jugadores;
  }

  Future<void> guardarEquipo() async {
    if (guardando) return;

    final nombre = nombreEquipo.text.trim();

    if (nombre.isEmpty) {
      mostrarMensaje(
        'Escribe el nombre del equipo',
      );
      return;
    }

    final jugadores = obtenerJugadores();

    if (jugadores == null) return;

    setState(() {
      guardando = true;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final datos = await prefs.getString('equipos');

      final equipos = (jsonDecode(datos ?? '[]') as List)
          .map(
            (e) => Map<String, dynamic>.from(e as Map),
      )
          .toList();

      final existe = equipos.any(
            (equipo) =>
        equipo['nombre']
            .toString()
            .trim()
            .toLowerCase() ==
            nombre.toLowerCase(),
      );

      if (existe) {
        mostrarMensaje(
          'Ya existe un equipo con ese nombre',
        );
        return;
      }

      equipos.add({
        'id': DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        'nombre': nombre,
        'jugadores': jugadores,
      });

      await prefs.setString(
        'equipos',
        jsonEncode(equipos),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      mostrarMensaje(
        'No se pudo guardar el equipo: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  Widget crearCampoJugador(int indice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JUGADOR ${indice + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: numeros[indice],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'N.º',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: nombres[indice],
                    textCapitalization:
                    TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del jugador',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nombreEquipo.dispose();

    for (final controlador in numeros) {
      controlador.dispose();
    }

    for (final controlador in nombres) {
      controlador.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AGREGAR EQUIPO'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1050,
          ),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'REGISTRO DE EQUIPO',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Registra hasta 20 jugadores. '
                    'No es obligatorio llenar todos '
                    'los espacios.',
              ),

              const SizedBox(height: 20),

              TextField(
                controller: nombreEquipo,
                textCapitalization:
                TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del equipo',
                  prefixIcon: Icon(Icons.shield),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'PLANTILLA DE JUGADORES (1-20)',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, espacio) {
                  final ancho = espacio.maxWidth;

                  if (ancho < 700) {
                    return Column(
                      children: [
                        for (int i = 0;
                        i < maxJugadores;
                        i++)
                          crearCampoJugador(i),
                      ],
                    );
                  }

                  const separacion = 14.0;

                  final anchoTarjeta =
                      (ancho - separacion) / 2;

                  return Wrap(
                    spacing: separacion,
                    runSpacing: 4,
                    children: [
                      for (int i = 0;
                      i < maxJugadores;
                      i++)
                        SizedBox(
                          width: anchoTarjeta,
                          child: crearCampoJugador(i),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed:
                  guardando ? null : guardarEquipo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.save),
                  label: Text(
                    guardando
                        ? 'GUARDANDO...'
                        : 'GUARDAR EQUIPO',
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
