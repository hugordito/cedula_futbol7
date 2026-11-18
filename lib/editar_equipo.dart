
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditarEquipo extends StatefulWidget {
  const EditarEquipo({super.key});

  @override
  State<EditarEquipo> createState() => _EditarEquipoState();
}

class _EditarEquipoState extends State<EditarEquipo> {
  List<Map<String, dynamic>> equipos = [];

  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarEquipos();
  }

  Future<void> cargarEquipos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final datos = await prefs.getString('equipos');

      final lista = (jsonDecode(datos ?? '[]') as List)
          .map(
            (e) => Map<String, dynamic>.from(e as Map),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        equipos = lista;
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

  Future<void> abrirFormulario(
      Map<String, dynamic> equipo,
      ) async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => FormularioEditarEquipo(
          equipo: equipo,
        ),
      ),
    );

    if (!mounted) return;

    if (actualizado == true) {
      await cargarEquipos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Equipo actualizado correctamente',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EDITAR EQUIPO'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: cargando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(error!),
        ),
      )
          : equipos.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Todavía no hay equipos '
                'registrados.',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1050,
          ),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'EQUIPOS REGISTRADOS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Selecciona el equipo que '
                    'deseas modificar.',
              ),

              const SizedBox(height: 18),

              for (final equipo in equipos)
                Card(
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.shield,
                      color: Colors.blue,
                      size: 32,
                    ),

                    title: Text(
                      equipo['nombre']
                          .toString(),
                    ),

                    subtitle: Text(
                      '${(equipo['jugadores'] as List?)?.length ?? 0}'
                          ' de 20 jugadores',
                    ),

                    trailing: const Icon(
                      Icons.edit,
                    ),

                    onTap: () =>
                        abrirFormulario(equipo),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormularioEditarEquipo extends StatefulWidget {
  final Map<String, dynamic> equipo;

  const FormularioEditarEquipo({
    super.key,
    required this.equipo,
  });

  @override
  State<FormularioEditarEquipo> createState() =>
      _FormularioEditarEquipoState();
}

class _FormularioEditarEquipoState
    extends State<FormularioEditarEquipo> {
  static const int maxJugadores = 20;

  late final TextEditingController nombreEquipo;

  late final List<TextEditingController> numeros;
  late final List<TextEditingController> nombres;

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    nombreEquipo = TextEditingController(
      text: widget.equipo['nombre'].toString(),
    );

    numeros = List.generate(
      maxJugadores,
          (_) => TextEditingController(),
    );

    nombres = List.generate(
      maxJugadores,
          (_) => TextEditingController(),
    );

    final jugadores =
        (widget.equipo['jugadores'] as List?) ?? [];

    for (int i = 0;
    i < jugadores.length && i < maxJugadores;
    i++) {
      final jugador = jugadores[i] as Map;

      numeros[i].text =
          jugador['numero']?.toString() ?? '';

      nombres[i].text =
          jugador['nombre']?.toString() ?? '';
    }
  }

  void mostrarMensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  List<Map<String, dynamic>>? obtenerJugadores() {
    final jugadores = <Map<String, dynamic>>[];
    final usados = <int>{};

    for (int i = 0; i < maxJugadores; i++) {
      final numeroTexto = numeros[i].text.trim();
      final nombreTexto = nombres[i].text.trim();

      if (numeroTexto.isEmpty &&
          nombreTexto.isEmpty) {
        continue;
      }

      if (numeroTexto.isEmpty ||
          nombreTexto.isEmpty) {
        mostrarMensaje(
          'Completa los datos del '
              'jugador ${i + 1}',
        );
        return null;
      }

      final numero = int.tryParse(numeroTexto);

      if (numero == null ||
          numero < 1 ||
          numero > 99) {
        mostrarMensaje(
          'El número del jugador ${i + 1} '
              'debe estar entre 1 y 99',
        );
        return null;
      }

      if (usados.contains(numero)) {
        mostrarMensaje(
          'El número $numero está repetido',
        );
        return null;
      }

      usados.add(numero);

      jugadores.add({
        'numero': numero,
        'nombre': nombreTexto,
      });
    }

    if (jugadores.isEmpty) {
      mostrarMensaje(
        'El equipo debe tener al menos un jugador',
      );
      return null;
    }

    return jugadores;
  }

  Future<void> guardarCambios() async {
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

      final idActual = widget.equipo['id'].toString();

      final repetido = equipos.any(
            (equipo) =>
        equipo['id'].toString() != idActual &&
            equipo['nombre']
                .toString()
                .trim()
                .toLowerCase() ==
                nombre.toLowerCase(),
      );

      if (repetido) {
        mostrarMensaje(
          'Ya existe otro equipo con ese nombre',
        );
        return;
      }

      final indice = equipos.indexWhere(
            (equipo) =>
        equipo['id'].toString() == idActual,
      );

      if (indice == -1) {
        mostrarMensaje(
          'No se encontró el equipo para editar',
        );
        return;
      }

      equipos[indice] = {
        ...equipos[indice],
        'id': idActual,
        'nombre': nombre,
        'jugadores': jugadores,
      };

      await prefs.setString(
        'equipos',
        jsonEncode(equipos),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      mostrarMensaje(
        'No se pudo actualizar el equipo: $e',
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
          crossAxisAlignment:
          CrossAxisAlignment.start,
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
        title: const Text('MODIFICAR EQUIPO'),
        backgroundColor: Colors.blue,
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
                'EDITAR PLANTILLA',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Puedes modificar nombres, '
                    'números y añadir jugadores '
                    'hasta completar 20.',
              ),

              const SizedBox(height: 20),

              TextField(
                controller: nombreEquipo,
                textCapitalization:
                TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del equipo',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'JUGADORES (1-20)',
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
                  guardando ? null : guardarCambios,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),

                  icon: const Icon(Icons.save),

                  label: Text(
                    guardando
                        ? 'GUARDANDO...'
                        : 'GUARDAR CAMBIOS',
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
