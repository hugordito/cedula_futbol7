
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';

// ==========================================
// PANTALLA EDITAR EQUIPO
// ARENA MOUSTACHE
// ==========================================

class EditarEquipo extends StatefulWidget {
  const EditarEquipo({super.key});

  @override
  State<EditarEquipo> createState() =>
      _EditarEquipoState();
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

  // ==========================================
  // CARGAR EQUIPOS GUARDADOS
  // ==========================================

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

  // ==========================================
  // ABRIR FORMULARIO DE EDICIÓN
  // ==========================================

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
          backgroundColor: ArenaColores.negro,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // ENCABEZADO DE LA LISTA DE EQUIPOS
  // ==========================================

  Widget crearEncabezado() {
    return Column(
      children: [
        const Icon(
          Icons.groups,
          size: 55,
          color: ArenaColores.dorado,
        ),

        const SizedBox(height: 12),

        const ArenaTextoMetalico(
          texto: 'EQUIPOS REGISTRADOS',
          tamano: 25,
          dorado: true,
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xD91B0505),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x80FFD36B),
            ),
          ),
          child: const Text(
            'Selecciona el equipo que deseas modificar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TARJETA PARA CADA EQUIPO REGISTRADO
  // ==========================================

  Widget crearTarjetaEquipo(
      Map<String, dynamic> equipo,
      ) {
    final nombre =
        equipo['nombre']?.toString() ?? 'Sin nombre';

    final totalJugadores =
        (equipo['jugadores'] as List?)?.length ?? 0;

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE4C5A6),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),

        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ArenaColores.negro,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ArenaColores.dorado,
            ),
          ),
          child: const Icon(
            Icons.shield,
            color: ArenaColores.dorado,
            size: 27,
          ),
        ),

        title: Text(
          nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ArenaColores.negro,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '$totalJugadores de 20 jugadores',
            style: const TextStyle(
              color: Color(0xFF655C54),
              fontSize: 13,
            ),
          ),
        ),

        trailing: const Icon(
          Icons.edit,
          color: ArenaColores.rojo,
          size: 25,
        ),

        onTap: () => abrirFormulario(equipo),
      ),
    );
  }

  // ==========================================
  // CONTENIDO DE LA PANTALLA
  // ==========================================

  Widget crearContenido() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: ArenaColores.dorado,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 550,
            ),
            child: ArenaPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: ArenaColores.rojo,
                    size: 45,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ArenaColores.negro,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1050,
        ),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SizedBox(height: 14),

            crearEncabezado(),

            const SizedBox(height: 26),

            ArenaPanel(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.folder_open,
                        color: ArenaColores.rojo,
                        size: 25,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'MIS EQUIPOS',
                          style: TextStyle(
                            color: ArenaColores.negro,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (equipos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 35,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.groups,
                            color: ArenaColores.rojo,
                            size: 48,
                          ),

                          SizedBox(height: 14),

                          Text(
                            'Todavía no hay equipos '
                                'registrados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: ArenaColores.negro,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final equipo in equipos)
                      crearTarjetaEquipo(equipo),
                ],
              ),
            ),

            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VISTA PRINCIPAL EDITAR EQUIPO
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'EDITAR EQUIPO',
      ),

      body: ArenaFondo(
        child: crearContenido(),
      ),
    );
  }
}

// ==========================================
// FORMULARIO MODIFICAR EQUIPO
// ==========================================

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

  // ==========================================
  // CARGAR DATOS DEL EQUIPO
  // ==========================================

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

  // ==========================================
  // MENSAJES
  // ==========================================

  void mostrarMensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: ArenaColores.negro,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // VALIDAR Y OBTENER JUGADORES
  // ==========================================

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

  // ==========================================
  // GUARDAR MODIFICACIONES
  // ==========================================

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

  // ==========================================
  // TARJETAS DE JUGADORES
  // ==========================================

  Widget crearCampoJugador(int indice) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE4C5A6),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: ArenaColores.rojo,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Text(
                  'JUGADOR ${indice + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ArenaColores.negro,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: numeros[indice],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'N.º',
                      filled: true,
                      fillColor: const Color(
                        0xFFF8F7F5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: nombres[indice],
                    textCapitalization:
                    TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre del jugador',
                      filled: true,
                      fillColor: const Color(
                        0xFFF8F7F5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(9),
                      ),
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

  // ==========================================
  // ENCABEZADO DE MODIFICACIÓN
  // ==========================================

  Widget crearEncabezado() {
    return Column(
      children: [
        const Icon(
          Icons.edit,
          color: ArenaColores.dorado,
          size: 55,
        ),

        const SizedBox(height: 12),

        const ArenaTextoMetalico(
          texto: 'EDITAR PLANTILLA',
          tamano: 25,
          dorado: true,
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xD91B0505),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x80FFD36B),
            ),
          ),
          child: const Text(
            'Puedes modificar nombres, números '
                'y añadir jugadores hasta completar 20.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FORMULARIO DE EDICIÓN
  // ==========================================

  Widget crearFormulario() {
    return ArenaPanel(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shield,
                color: ArenaColores.rojo,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'DATOS DEL EQUIPO',
                  style: TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          TextField(
            controller: nombreEquipo,
            textCapitalization:
            TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nombre del equipo',
              prefixIcon: const Icon(
                Icons.shield,
                color: ArenaColores.rojo,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 26),

          const Divider(
            color: Color(0xFFD9B48F),
          ),

          const SizedBox(height: 14),

          const Row(
            children: [
              Icon(
                Icons.groups,
                color: ArenaColores.rojo,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'JUGADORES (1-20)',
                  style: TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Una columna en celulares y
          // dos columnas en pantallas grandes.
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

          const SizedBox(height: 22),

          SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed:
              guardando ? null : guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArenaColores.negro,
                foregroundColor: ArenaColores.dorado,
                disabledBackgroundColor: Colors.grey,
                elevation: 5,
                shadowColor: ArenaColores.rojo,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                  side: const BorderSide(
                    color: ArenaColores.dorado,
                    width: 1.5,
                  ),
                ),
              ),
              icon: Icon(
                guardando
                    ? Icons.hourglass_top
                    : Icons.save,
                size: 24,
              ),
              label: Text(
                guardando
                    ? 'GUARDANDO...'
                    : 'GUARDAR CAMBIOS',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LIBERAR CONTROLADORES
  // ==========================================

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

  // ==========================================
  // VISTA MODIFICAR EQUIPO
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'MODIFICAR EQUIPO',
      ),

      body: ArenaFondo(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1050,
            ),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const SizedBox(height: 14),

                crearEncabezado(),

                const SizedBox(height: 26),

                crearFormulario(),

                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
