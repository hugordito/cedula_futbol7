
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';

// ==========================================
// CARGAR EQUIPOS
// ESTILO ARENA MOUSTACHE
// ==========================================

class CargarEquipo extends StatefulWidget {
  const CargarEquipo({super.key});

  @override
  State<CargarEquipo> createState() =>
      _CargarEquipoState();
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

  // ==========================================
  // CARGAR EQUIPOS Y SELECCIÓN GUARDADA
  // ==========================================

  Future<void> cargarDatos() async {
    try {
      final prefs = SharedPreferencesAsync();

      final datos = await prefs.getString('equipos');

      final seleccion =
      await prefs.getString('partido_equipos');

      final lista = (jsonDecode(datos ?? '[]') as List)
          .map(
            (e) => Map<String, dynamic>.from(e as Map),
      )
          .toList();

      String? local;
      String? visitante;

      if (seleccion != null) {
        final guardado =
        jsonDecode(seleccion) as Map<String, dynamic>;

        local = guardado['localId']?.toString();
        visitante = guardado['visitanteId']?.toString();
      }

      // Verificar que ambos equipos todavía existan.
      if (!lista.any(
            (e) => e['id'].toString() == local,
      )) {
        local = null;
      }

      if (!lista.any(
            (e) => e['id'].toString() == visitante,
      )) {
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

  // ==========================================
  // BUSCAR EQUIPO POR ID
  // ==========================================

  Map<String, dynamic>? buscarEquipo(String? id) {
    if (id == null) return null;

    for (final equipo in equipos) {
      if (equipo['id'].toString() == id) {
        return equipo;
      }
    }

    return null;
  }

  // ==========================================
  // MOSTRAR MENSAJES
  // ==========================================

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: ArenaColores.negro,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // GUARDAR SELECCIÓN DE EQUIPOS
  // ==========================================

  Future<void> guardarSeleccion() async {
    if (guardando) return;

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

      mostrarMensaje(
        'Selección guardada correctamente',
      );
    } catch (e) {
      mostrarMensaje(
        'No se pudo guardar la selección: $e',
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
  // ENCABEZADO DE LA PANTALLA
  // ==========================================

  Widget crearEncabezado() {
    return Column(
      children: [
        const Icon(
          Icons.sports_soccer,
          size: 55,
          color: ArenaColores.dorado,
        ),

        const SizedBox(height: 12),

        const ArenaTextoMetalico(
          texto: 'SELECCIÓN DE EQUIPOS',
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
            'Selecciona los equipos que jugarán '
                'el partido: uno LOCAL y otro VISITANTE.',
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
  // PANEL DE SELECCIÓN DE EQUIPOS
  // ==========================================

  Widget crearPanel({
    required String titulo,
    required Color color,
    required String? seleccionado,
    required ValueChanged<String?> alCambiar,
  }) {
    final equipo = buscarEquipo(seleccionado);

    final jugadores =
        (equipo?['jugadores'] as List?) ?? [];

    return ArenaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado del panel.
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Selector de equipo.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD9B48F),
                width: 1.2,
              ),
            ),
            child: DropdownButton<String>(
              value: seleccionado,
              isExpanded: true,
              dropdownColor: Colors.white,
              underline: const SizedBox.shrink(),
              hint: const Text(
                'Selecciona un equipo',
                style: TextStyle(
                  color: Color(0xFF756D66),
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: ArenaColores.rojo,
              ),
              style: const TextStyle(
                color: ArenaColores.negro,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              items: equipos.map((e) {
                return DropdownMenuItem<String>(
                  value: e['id'].toString(),
                  child: Text(
                    e['nombre'].toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: alCambiar,
            ),
          ),

          // Vista previa de los jugadores.
          if (equipo != null) ...[
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 22,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'JUGADORES: ${jugadores.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE4C5A6),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  for (final jugador in jugadores)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 39,
                            padding:
                            const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: ArenaColores.negro,
                              borderRadius:
                              BorderRadius.circular(7),
                              border: Border.all(
                                color: ArenaColores.dorado,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${jugador['numero']}',
                              style: const TextStyle(
                                color: ArenaColores.dorado,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 7,
                              ),
                              child: Text(
                                '${jugador['nombre']}',
                                style: const TextStyle(
                                  color: ArenaColores.negro,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),

            const Center(
              child: Text(
                'Aún no has seleccionado un equipo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF756D66),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // BOTÓN GUARDAR SELECCIÓN
  // ==========================================

  Widget crearBotonGuardar() {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed:
        guardando ? null : guardarSeleccion,
        style: ElevatedButton.styleFrom(
          backgroundColor: ArenaColores.negro,
          foregroundColor: ArenaColores.dorado,
          disabledBackgroundColor: Colors.grey,
          elevation: 5,
          shadowColor: ArenaColores.rojo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
              : 'GUARDAR SELECCIÓN',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ESTADO VACÍO O ERROR
  // ==========================================

  Widget crearMensajeCentral({
    required IconData icono,
    required String mensaje,
  }) {
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
                Icon(
                  icono,
                  color: ArenaColores.rojo,
                  size: 50,
                ),

                const SizedBox(height: 16),

                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CONTENIDO GENERAL
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
      return crearMensajeCentral(
        icono: Icons.error_outline,
        mensaje: error!,
      );
    }

    if (equipos.isEmpty) {
      return crearMensajeCentral(
        icono: Icons.groups,
        mensaje:
        'No tienes equipos guardados. '
            'Primero registra un equipo '
            'en AGREGAR EQUIPO.',
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

            // Equipo local.
            crearPanel(
              titulo: 'EQUIPO LOCAL',
              color: const Color(0xFFB31212),
              seleccionado: localId,
              alCambiar: (id) {
                setState(() {
                  localId = id;
                });
              },
            ),

            const SizedBox(height: 16),

            crearPanel(
              titulo: 'EQUIPO VISITANTE',
              color: const Color(0xFF1F1A17),
              seleccionado: visitanteId,
              alCambiar: (id) {
                setState(() {
                  visitanteId = id;
                });
              },
            ),

            const SizedBox(height: 26),

            crearBotonGuardar(),

            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANTALLA COMPLETA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'CARGAR EQUIPOS',
      ),

      body: ArenaFondo(
        child: crearContenido(),
      ),
    );
  }
}
