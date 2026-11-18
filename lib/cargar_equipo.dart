
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CargarEquipo extends StatefulWidget {
  const CargarEquipo({super.key});

  @override
  State<CargarEquipo> createState() => _CargarEquipoState();
}

class _CargarEquipoState extends State<CargarEquipo> {
  List<Map<String, dynamic>> equipos = [];

  String? localId;
  String? visitanteId;

  bool cargando = true;
  bool guardando = false;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      final prefs = SharedPreferencesAsync();

      final datos = await prefs.getString('equipos');
      final seleccion =
      await prefs.getString('partido_equipos');

      final lista = (jsonDecode(datos ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      String? local;
      String? visitante;

      if (seleccion != null) {
        final guardado =
        jsonDecode(seleccion) as Map<String, dynamic>;

        local = guardado['localId']?.toString();
        visitante = guardado['visitanteId']?.toString();
      }

      // Comprobar que los equipos aún existan.
      if (!lista.any((e) => e['id'].toString() == local)) {
        local = null;
      }

      if (!lista.any((e) => e['id'].toString() == visitante)) {
        visitante = null;
      }

      if (!mounted) return;

      setState(() {
        equipos = lista;
        localId = local;
        visitanteId = visitante;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'No se pudieron cargar los equipos: $e';
        cargando = false;
      });
    }
  }

  Map<String, dynamic>? buscarEquipo(String? id) {
    if (id == null) return null;

    for (final equipo in equipos) {
      if (equipo['id'].toString() == id) {
        return equipo;
      }
    }

    return null;
  }

  Future<void> guardarSeleccion() async {
    if (localId == null || visitanteId == null) {
      mostrarMensaje('Selecciona ambos equipos');
      return;
    }

    if (localId == visitanteId) {
      mostrarMensaje(
        'El equipo local y visitante deben ser diferentes',
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final seleccion = {
        'localId': localId,
        'visitanteId': visitanteId,
      };

      await prefs.setString(
        'partido_equipos',
        jsonEncode(seleccion),
      );

      mostrarMensaje('Selección guardada correctamente');
    } catch (e) {
      mostrarMensaje('No se pudo guardar la selección: $e');
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Widget crearPanel({
    required String titulo,
    required Color color,
    required String? seleccionado,
    required ValueChanged<String?> alCambiar,
  }) {
    final equipo = buscarEquipo(seleccionado);

    final jugadores =
        (equipo?['jugadores'] as List?) ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: color),
                const SizedBox(width: 10),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            DropdownButton<String>(
              value: seleccionado,
              isExpanded: true,
              hint: const Text('Selecciona un equipo'),
              items: equipos.map((e) {
                return DropdownMenuItem<String>(
                  value: e['id'].toString(),
                  child: Text(e['nombre'].toString()),
                );
              }).toList(),
              onChanged: alCambiar,
            ),

            if (equipo != null) ...[
              const SizedBox(height: 12),

              Text(
                'Jugadores: ${jugadores.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              for (final jugador in jugadores)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3,
                  ),
                  child: Text(
                    '#${jugador['numero']} - '
                        '${jugador['nombre']}',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CARGAR EQUIPOS'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: cargando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : error != null
          ? Center(child: Text(error!))
          : equipos.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No tienes equipos guardados. '
                'Primero registra un equipo '
                'en AGREGAR EQUIPO.',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Selecciona los equipos '
                'que jugarán el partido.',
            style: TextStyle(fontSize: 17),
          ),

          const SizedBox(height: 20),

          crearPanel(
            titulo: 'EQUIPO LOCAL',
            color: Colors.green,
            seleccionado: localId,
            alCambiar: (id) {
              setState(() {
                localId = id;
              });
            },
          ),

          const SizedBox(height: 15),

          crearPanel(
            titulo: 'EQUIPO VISITANTE',
            color: Colors.blue,
            seleccionado: visitanteId,
            alCambiar: (id) {
              setState(() {
                visitanteId = id;
              });
            },
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : guardarSeleccion,
              icon: const Icon(Icons.save),
              label: Text(
                guardando
                    ? 'GUARDANDO...'
                    : 'GUARDAR SELECCIÓN',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
