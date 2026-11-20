
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cargar_equipo.dart';
import 'registro_eventos.dart';
import 'registro_shootouts.dart';
import 'cedula_tactil.dart';

class NuevaCedula extends StatefulWidget {
  const NuevaCedula({super.key});

  @override
  State<NuevaCedula> createState() =>
      _NuevaCedulaState();
}

class _NuevaCedulaState extends State<NuevaCedula> {
  final Map<String, TextEditingController> campos = {
    'ciudad': TextEditingController(),
    'torneo': TextEditingController(),
    'cancha': TextEditingController(),
    'fecha': TextEditingController(),
    'hora': TextEditingController(),
    'jornada': TextEditingController(),
    'categoria': TextEditingController(),
    'rama': TextEditingController(),
    'arbitro': TextEditingController(),
    'observaciones': TextEditingController(),
    'dtLocal': TextEditingController(),
    'atLocal': TextEditingController(),
    'dtVisitante': TextEditingController(),
    'atVisitante': TextEditingController(),
  };

  Map<String, dynamic>? equipoLocal;
  Map<String, dynamic>? equipoVisitante;

  List<Map<String, dynamic>> eventos = [];
  List<Map<String, dynamic>> shootouts = [];
  List<Map<String, dynamic>> faltasBloques = [];
  List<Map<String, dynamic>> marcasVisuales = [];

  // Cada entrada contiene una firma PNG en Base64.
  Map<String, String> firmas = {};

  bool cargando = true;
  bool guardando = false;
  bool vistaHoja = true;

  String? error;

  String dato(String clave) {
    return campos[clave]?.text.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    cargarEquipos();
  }

  int contar(String lado, String tipo) {
    final eventosContados = eventos.where(
      (item) => item['lado'] == lado && item['tipo'] == tipo,
    ).length;

    if (tipo != 'falta') return eventosContados;

    return eventosContados +
        faltasBloques.where(
          (item) => item['lado'] == lado,
        ).length;
  }

  int shootoutsAcertados(String lado) {
    return shootouts.where(
          (intento) =>
      intento['lado'] == lado &&
          intento['resultado'] == 'gol',
    ).length;
  }

  void mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  // =========================================
  // CARGAR EQUIPOS
  // =========================================

  Future<void> cargarEquipos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final textoEquipos =
      await prefs.getString('equipos');

      final textoSeleccion =
      await prefs.getString('partido_equipos');

      final equipos =
      (jsonDecode(textoEquipos ?? '[]') as List)
          .map(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

      Map<String, dynamic>? local;
      Map<String, dynamic>? visitante;

      if (textoSeleccion != null) {
        final seleccion = Map<String, dynamic>.from(
          jsonDecode(textoSeleccion) as Map,
        );

        final idLocal =
        seleccion['localId']?.toString();

        final idVisitante =
        seleccion['visitanteId']?.toString();

        for (final equipo in equipos) {
          if (equipo['id'].toString() == idLocal) {
            local = equipo;
          }

          if (equipo['id'].toString() == idVisitante) {
            visitante = equipo;
          }
        }
      }

      if (!mounted) return;

      final cambiaron =
          equipoLocal?['id'] != local?['id'] ||
              equipoVisitante?['id'] != visitante?['id'];

      setState(() {
        equipoLocal = local;
        equipoVisitante = visitante;

        if (cambiaron) {
          eventos = [];
          shootouts = [];
          faltasBloques = [];
          marcasVisuales = [];

          // Evita conservar firmas de otro partido
          // cuando se cambia la selección de equipos.
          firmas = {};
        }

        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = 'No se pudieron cargar equipos: $e';
      });
    }
  }

  Future<void> seleccionarEquipos() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const CargarEquipo(),
      ),
    );

    if (!mounted) return;

    await cargarEquipos();
  }

  // =========================================
  // REGISTRAR ACONTECIMIENTOS
  // =========================================

  Future<void> abrirEventos() async {
    if (equipoLocal == null ||
        equipoVisitante == null) {
      mensaje('Primero selecciona los equipos');
      return;
    }

    final resultado =
    await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute<List<Map<String, dynamic>>>(
        builder: (context) => RegistroEventos(
          equipoLocal: equipoLocal!,
          equipoVisitante: equipoVisitante!,
          eventosIniciales: eventos,
        ),
      ),
    );

    if (!mounted || resultado == null) return;

    setState(() {
      eventos = resultado;
    });
  }

  // =========================================
  // REGISTRAR SHOOT OUTS
  // =========================================

  Future<void> abrirShootouts() async {
    if (equipoLocal == null ||
        equipoVisitante == null) {
      mensaje('Primero selecciona los equipos');
      return;
    }

    final resultado =
    await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute<List<Map<String, dynamic>>>(
        builder: (context) => RegistroShootouts(
          equipoLocal: equipoLocal!,
          equipoVisitante: equipoVisitante!,
          intentosIniciales: shootouts,
        ),
      ),
    );

    if (!mounted || resultado == null) return;

    setState(() {
      shootouts = resultado;
    });
  }

  // =========================================
  // GUARDAR BORRADOR CON FIRMAS
  // =========================================

  Future<void> guardarBorrador() async {
    if (guardando) return;

    if (equipoLocal == null ||
        equipoVisitante == null) {
      mensaje('Selecciona los dos equipos');
      return;
    }

    if (equipoLocal!['id'] ==
        equipoVisitante!['id']) {
      mensaje('Los equipos deben ser diferentes');
      return;
    }

    if (dato('torneo').isEmpty ||
        dato('fecha').isEmpty) {
      mensaje('Completa el torneo y la fecha');
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final texto =
      await prefs.getString('cedulas_borrador');

      final lista =
      jsonDecode(texto ?? '[]') as List;

      final ahora = DateTime.now();

      final nuevaCedula = <String, dynamic>{
        'id': ahora.microsecondsSinceEpoch.toString(),

        'estado': 'borrador',

        'creadaEn': ahora.toIso8601String(),

        for (final entrada in campos.entries)
          entrada.key: entrada.value.text.trim(),

        'equipoLocal': equipoLocal,
        'equipoVisitante': equipoVisitante,

        'eventos': eventos,
        'shootouts': shootouts,
        'faltasBloques': faltasBloques,
        'marcasVisuales': marcasVisuales,

        // Las seis firmas guardadas en la hoja.
        'firmas': Map<String, String>.from(firmas),

        'golesLocal': contar('local', 'gol'),
        'golesVisitante': contar('visitante', 'gol'),

        'faltasLocal': contar('local', 'falta'),
        'faltasVisitante':
        contar('visitante', 'falta'),

        'shootoutsGolLocal':
        shootoutsAcertados('local'),

        'shootoutsGolVisitante':
        shootoutsAcertados('visitante'),
      };

      lista.add(nuevaCedula);

      await prefs.setString(
        'cedulas_borrador',
        jsonEncode(lista),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      mensaje('Error al guardar borrador: $e');
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  // =========================================
  // CAMPOS Y FORMULARIO
  // =========================================

  Widget campo(
      String etiqueta,
      String clave, {
        int lineas = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: campos[clave],
        maxLines: lineas,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget formularioAdaptable(List<Widget> lista) {
    return LayoutBuilder(
      builder: (context, espacio) {
        if (espacio.maxWidth < 700) {
          return Column(
            children: lista,
          );
        }

        final ancho =
            (espacio.maxWidth - 14) / 2;

        return Wrap(
          spacing: 14,
          children: [
            for (final elemento in lista)
              SizedBox(
                width: ancho,
                child: elemento,
              ),
          ],
        );
      },
    );
  }

  Widget tarjetaEquipo(
      String titulo,
      Map<String, dynamic>? equipo,
      ) {
    final plantilla =
        (equipo?['jugadores'] as List?) ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              equipo?['nombre']?.toString() ??
                  'Sin seleccionar',
            ),

            Text(
              '${plantilla.length} de 20 jugadores',
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // EDITOR DE DATOS TRADICIONAL
  // =========================================

  Widget editor() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 950,
        ),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            titulo('DATOS DEL PARTIDO'),

            formularioAdaptable([
              campo('Ciudad', 'ciudad'),
              campo('Torneo', 'torneo'),
              campo('Cancha', 'cancha'),
              campo('Fecha', 'fecha'),
              campo('Hora', 'hora'),
              campo('Jornada', 'jornada'),
              campo('Rama', 'rama'),
              campo('Categoría', 'categoria'),
              campo('Árbitro', 'arbitro'),
            ]),

            titulo('EQUIPOS PARTICIPANTES'),

            OutlinedButton.icon(
              onPressed: seleccionarEquipos,
              icon: const Icon(Icons.folder_open),
              label: const Text(
                'SELECCIONAR EQUIPOS',
              ),
            ),

            LayoutBuilder(
              builder: (context, espacio) {
                if (espacio.maxWidth < 650) {
                  return Column(
                    children: [
                      tarjetaEquipo(
                        'LOCAL',
                        equipoLocal,
                      ),
                      tarjetaEquipo(
                        'VISITANTE',
                        equipoVisitante,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: tarjetaEquipo(
                        'LOCAL',
                        equipoLocal,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: tarjetaEquipo(
                        'VISITANTE',
                        equipoVisitante,
                      ),
                    ),
                  ],
                );
              },
            ),

            titulo('CUERPO TÉCNICO'),

            formularioAdaptable([
              campo('D.T. local', 'dtLocal'),
              campo('A.T. local', 'atLocal'),
              campo('D.T. visitante', 'dtVisitante'),
              campo('A.T. visitante', 'atVisitante'),
            ]),

            titulo('GOLES, FALTAS Y TARJETAS'),

            Text(
              'Marcador: '
                  '${contar('local', 'gol')} - '
                  '${contar('visitante', 'gol')}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Acontecimientos: ${eventos.length}',
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: abrirEventos,
              icon: const Icon(Icons.edit_note),
              label: const Text(
                'REGISTRAR ACONTECIMIENTOS',
              ),
            ),

            titulo('DEFINICIÓN EN SHOOT OUT'),

            Text(
              'Local: ${shootoutsAcertados('local')} · '
                  'Visitante: '
                  '${shootoutsAcertados('visitante')}',
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: abrirShootouts,
              icon: const Icon(Icons.sports_soccer),
              label: const Text(
                'REGISTRAR SHOOT OUTS',
              ),
            ),

            titulo('FIRMAS'),

            Text(
              'Firmas capturadas: ${firmas.length} de 6',
            ),

            const SizedBox(height: 8),

            const Text(
              'Para firmar, entra en VER CÉDULA '
                  'y toca el recuadro correspondiente.',
            ),

            titulo('OBSERVACIONES'),

            campo(
              'Observaciones del partido',
              'observaciones',
              lineas: 5,
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                guardando ? null : guardarBorrador,
                icon: const Icon(Icons.save),
                label: Text(
                  guardando
                      ? 'GUARDANDO...'
                      : 'GUARDAR BORRADOR',
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================================
  // LIBERAR CONTROLADORES
  // =========================================

  @override
  void dispose() {
    for (final controlador in campos.values) {
      controlador.dispose();
    }

    super.dispose();
  }

  // =========================================
  // PANTALLA PRINCIPAL DE NUEVA CEDULA
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NUEVA CÉDULA'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),

      body: cargando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : error != null
          ? Center(
        child: Text(error!),
      )
          : Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              6,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        vistaHoja = false;
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text(
                      'EDITAR DATOS',
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        vistaHoja = true;
                      });
                    },
                    icon: const Icon(
                      Icons.description,
                    ),
                    label: const Text(
                      'VER CÉDULA',
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (vistaHoja)
            Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: guardando
                      ? null
                      : guardarBorrador,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.save),
                  label: Text(
                    guardando
                        ? 'GUARDANDO...'
                        : 'GUARDAR CÉDULA',
                  ),
                ),
              ),
            ),

          if (vistaHoja)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Text(
                'Toca las casillas de la hoja '
                    'para introducir datos y firmas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ),

          Expanded(
            child: vistaHoja
                ? CedulaTactil(
              campos: campos,

              equipoLocal: equipoLocal,

              equipoVisitante:
              equipoVisitante,

              eventos: eventos,

              shootouts: shootouts,
               faltasBloques: faltasBloques,
               marcasVisuales: marcasVisuales,

              firmas: firmas,

              onFaltasBloquesActualizadas: (nuevas) {
                 setState(() {
                   faltasBloques = nuevas;
                 });
               },
               onMarcasVisualesActualizadas: (nuevas) {
                 setState(() {
                   marcasVisuales = nuevas;
                 });
               },
               onCamposActualizados: () {
                setState(() {});
              },

              onEventosActualizados:
                  (nuevosEventos) {
                setState(() {
                  eventos = nuevosEventos;
                });
              },

              onFirmasActualizadas:
                  (nuevasFirmas) {
                setState(() {
                  firmas =
                  Map<String, String>.from(
                    nuevasFirmas,
                  );
                });
              },

              onEditarEquipos:
              seleccionarEquipos,

              onEditarShootouts:
              abrirShootouts,
            )
                : editor(),
          ),
        ],
      ),
    );
  }
}
