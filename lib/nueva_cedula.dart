
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cargar_equipo.dart';
import 'registro_eventos.dart';
import 'registro_shootouts.dart';

class NuevaCedula extends StatefulWidget {
  const NuevaCedula({super.key});

  @override
  State<NuevaCedula> createState() => _NuevaCedulaState();
}

class _NuevaCedulaState extends State<NuevaCedula> {
  static const int maxJugadores = 20;

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

  int contar(
      String tipo,
      String lado, {
        int? numero,
      }) {
    return eventos.where((evento) {
      if (evento['tipo'] != tipo ||
          evento['lado'] != lado) {
        return false;
      }

      if (numero == null) return true;

      return int.tryParse(
        evento['numero'].toString(),
      ) ==
          numero;
    }).length;
  }

  int contarPeriodo(
      String tipo,
      String lado,
      String periodo,
      ) {
    return eventos.where(
          (evento) =>
      evento['tipo'] == tipo &&
          evento['lado'] == lado &&
          evento['periodo'] == periodo,
    ).length;
  }

  int shootoutsAcertados(String lado) {
    return shootouts.where(
          (intento) =>
      intento['lado'] == lado &&
          intento['resultado'] == 'gol',
    ).length;
  }

  List<Map<String, dynamic>> eventosDe(
      String tipo,
      String lado,
      ) {
    return eventos.where(
          (evento) =>
      evento['tipo'] == tipo &&
          evento['lado'] == lado,
    ).toList();
  }

  void mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> cargarEquipos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final datosEquipos =
      await prefs.getString('equipos');

      final datosSeleccion =
      await prefs.getString('partido_equipos');

      final equipos = (jsonDecode(
        datosEquipos ?? '[]',
      ) as List)
          .map(
            (item) =>
        Map<String, dynamic>.from(item as Map),
      )
          .toList();

      Map<String, dynamic>? local;
      Map<String, dynamic>? visitante;

      if (datosSeleccion != null) {
        final seleccion =
        Map<String, dynamic>.from(
          jsonDecode(datosSeleccion) as Map,
        );

        final localId =
        seleccion['localId']?.toString();

        final visitanteId =
        seleccion['visitanteId']?.toString();

        for (final equipo in equipos) {
          if (equipo['id'].toString() == localId) {
            local = equipo;
          }

          if (equipo['id'].toString() == visitanteId) {
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
        }

        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
        'No se pudieron cargar los equipos: $e';
        cargando = false;
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

    if (mounted) {
      await cargarEquipos();
    }
  }

  Future<void> abrirEventos() async {
    if (equipoLocal == null ||
        equipoVisitante == null) {
      mensaje('Selecciona primero los dos equipos');
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

  Future<void> abrirShootouts() async {
    if (equipoLocal == null ||
        equipoVisitante == null) {
      mensaje('Selecciona primero los dos equipos');
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

      final datos =
      await prefs.getString('cedulas_borrador');

      final lista = jsonDecode(
        datos ?? '[]',
      ) as List;

      lista.add({
        'id': DateTime.now()
            .microsecondsSinceEpoch
            .toString(),

        'estado': 'borrador',

        'creadaEn':
        DateTime.now().toIso8601String(),

        for (final entrada in campos.entries)
          entrada.key: entrada.value.text.trim(),

        'equipoLocal': equipoLocal,
        'equipoVisitante': equipoVisitante,

        'eventos': eventos,
        'shootouts': shootouts,

        'golesLocal': contar('gol', 'local'),
        'golesVisitante': contar('gol', 'visitante'),

        'faltasLocal': contar('falta', 'local'),
        'faltasVisitante': contar('falta', 'visitante'),

        'shootoutsGolLocal':
        shootoutsAcertados('local'),

        'shootoutsGolVisitante':
        shootoutsAcertados('visitante'),
      });

      await prefs.setString(
        'cedulas_borrador',
        jsonEncode(lista),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      mensaje(
        'No se pudo guardar la cédula: $e',
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
  // FORMULARIO DE CAPTURA
  // ==========================================

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

  Widget tituloSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
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

  Widget formularioAdaptable(
      List<Widget> widgets,
      ) {
    return LayoutBuilder(
      builder: (context, espacio) {
        if (espacio.maxWidth < 700) {
          return Column(children: widgets);
        }

        final ancho =
            (espacio.maxWidth - 14) / 2;

        return Wrap(
          spacing: 14,
          children: [
            for (final widget in widgets)
              SizedBox(
                width: ancho,
                child: widget,
              ),
          ],
        );
      },
    );
  }

  Widget resumenEquipo(
      String titulo,
      Map<String, dynamic>? equipo,
      ) {
    final jugadores =
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
              '${jugadores.length} '
                  'de $maxJugadores jugadores',
            ),
          ],
        ),
      ),
    );
  }

  Widget editor() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 950,
        ),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            tituloSeccion('DATOS DEL PARTIDO'),

            formularioAdaptable([
              campo('Ciudad', 'ciudad'),
              campo('Torneo', 'torneo'),
              campo('Cancha', 'cancha'),
              campo(
                'Fecha (DD/MM/AAAA)',
                'fecha',
              ),
              campo('Hora', 'hora'),
              campo('Jornada', 'jornada'),
              campo('Rama', 'rama'),
              campo('Categoría', 'categoria'),
              campo('Árbitro', 'arbitro'),
            ]),

            tituloSeccion('EQUIPOS PARTICIPANTES'),

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
                      resumenEquipo(
                        'LOCAL',
                        equipoLocal,
                      ),

                      resumenEquipo(
                        'VISITANTE',
                        equipoVisitante,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: resumenEquipo(
                        'LOCAL',
                        equipoLocal,
                      ),
                    ),

                    Expanded(
                      child: resumenEquipo(
                        'VISITANTE',
                        equipoVisitante,
                      ),
                    ),
                  ],
                );
              },
            ),

            tituloSeccion('CUERPO TÉCNICO'),

            formularioAdaptable([
              campo('D.T. local', 'dtLocal'),
              campo('A.T. local', 'atLocal'),
              campo('D.T. visitante', 'dtVisitante'),
              campo('A.T. visitante', 'atVisitante'),
            ]),

            tituloSeccion(
              'GOLES, TARJETAS Y FALTAS',
            ),

            Text(
              'Marcador: '
                  '${contar('gol', 'local')} - '
                  '${contar('gol', 'visitante')}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              'Acontecimientos: ${eventos.length}',
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: abrirEventos,
              icon: const Icon(Icons.edit_note),
              label: const Text(
                'REGISTRAR ACONTECIMIENTOS',
              ),
            ),

            tituloSeccion(
              'DEFINICIÓN EN SHOOT OUT',
            ),

            Text(
              'Local: ${shootoutsAcertados('local')} '
                  'aciertos | '
                  'Visitante: '
                  '${shootoutsAcertados('visitante')} '
                  'aciertos',
            ),

            Text(
              'Intentos registrados: '
                  '${shootouts.length}',
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: abrirShootouts,
              icon: const Icon(Icons.sports_soccer),
              label: const Text(
                'REGISTRAR SHOOT OUTS',
              ),
            ),

            tituloSeccion('OBSERVACIONES'),

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

  // ==========================================
  // ELEMENTOS DE LA HOJA VERTICAL
  // ==========================================

  Widget celda(
      String texto, {
        bool negrita = false,
        TextAlign alineacion = TextAlign.center,
      }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 21,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 3,
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alineacion,
        style: TextStyle(
          fontSize: 9,
          color: Colors.black,
          fontWeight: negrita
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  Widget tituloTabla(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black87,
        ),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget datoEncabezado(
      String titulo,
      String valor,
      ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black87,
          ),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(
              height: 8,
              color: Colors.black54,
            ),

            Text(
              valor.isEmpty ? ' ' : valor,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget encabezadoHoja() {
    return Column(
      children: [
        const Text(
          'ACTA DE JUEGO FÚTBOL 7',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'CÉDULA DIGITAL DEL PARTIDO',
          style: TextStyle(fontSize: 10),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            datoEncabezado(
              'CIUDAD',
              dato('ciudad'),
            ),
            datoEncabezado(
              'TORNEO',
              dato('torneo'),
            ),
            datoEncabezado(
              'RAMA',
              dato('rama'),
            ),
            datoEncabezado(
              'CATEGORÍA',
              dato('categoria'),
            ),
          ],
        ),

        Row(
          children: [
            datoEncabezado(
              'CANCHA',
              dato('cancha'),
            ),
            datoEncabezado(
              'FECHA',
              dato('fecha'),
            ),
            datoEncabezado(
              'HORA',
              dato('hora'),
            ),
            datoEncabezado(
              'JORNADA',
              dato('jornada'),
            ),
          ],
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ==========================================
  // TABLA DE 20 JUGADORES
  // ==========================================

  Widget tablaJugadores(
      String lado,
      Map<String, dynamic>? equipo,
      ) {
    final jugadores =
        (equipo?['jugadores'] as List?) ?? [];

    final nombre =
        equipo?['nombre']?.toString() ??
            'SIN SELECCIONAR';

    return Column(
      children: [
        tituloTabla(
          '${lado.toUpperCase()}: $nombre',
        ),

        const SizedBox(height: 3),

        Table(
          border: TableBorder.all(
            color: Colors.black54,
            width: 0.7,
          ),
          columnWidths: const {
            0: FlexColumnWidth(0.07),
            1: FlexColumnWidth(0.09),
            2: FlexColumnWidth(0.40),
            3: FlexColumnWidth(0.11),
            4: FlexColumnWidth(0.11),
            5: FlexColumnWidth(0.10),
            6: FlexColumnWidth(0.12),
          },
          children: [
            TableRow(
              children: [
                celda('Ini', negrita: true),
                celda('#', negrita: true),
                celda('NOMBRE', negrita: true),
                celda('G', negrita: true),
                celda('Am', negrita: true),
                celda('R', negrita: true),
                celda('F', negrita: true),
              ],
            ),

            for (int i = 0; i < maxJugadores; i++)
              TableRow(
                children: [
                  celda('${i + 1}'),

                  celda(
                    i < jugadores.length
                        ? '${jugadores[i]['numero']}'
                        : '',
                  ),

                  celda(
                    i < jugadores.length
                        ? '${jugadores[i]['nombre']}'
                        : '',
                    alineacion: TextAlign.left,
                  ),

                  celda(
                    i < jugadores.length
                        ? '${contar(
                      'gol',
                      lado,
                      numero: int.tryParse(
                        '${jugadores[i]['numero']}',
                      ),
                    )}'
                        : '',
                  ),

                  celda(
                    i < jugadores.length
                        ? '${contar(
                      'amarilla',
                      lado,
                      numero: int.tryParse(
                        '${jugadores[i]['numero']}',
                      ),
                    )}'
                        : '',
                  ),

                  celda(
                    i < jugadores.length
                        ? '${contar(
                      'roja',
                      lado,
                      numero: int.tryParse(
                        '${jugadores[i]['numero']}',
                      ),
                    )}'
                        : '',
                  ),

                  celda(
                    i < jugadores.length
                        ? '${contar(
                      'falta',
                      lado,
                      numero: int.tryParse(
                        '${jugadores[i]['numero']}',
                      ),
                    )}'
                        : '',
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget cuerpoTecnico(
      String dt,
      String at,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black54,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'D.T.: $dt',
            style: const TextStyle(fontSize: 10),
          ),
          const Divider(
            height: 10,
            color: Colors.black38,
          ),
          Text(
            'A.T.: $at',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  String periodoCorto(dynamic valor) {
    if (valor == 'Primer medio') return '1';
    if (valor == 'Segundo medio') return '2';

    return valor?.toString() ?? '';
  }

  // ==========================================
  // TABLA DE GOLES
  // ==========================================

  Widget tablaGoles(String lado) {
    final goles = eventosDe('gol', lado);

    final necesarios = (goles.length + 8) ~/ 9;
    final bloques = necesarios < 2 ? 2 : necesarios;

    return Column(
      children: [
        tituloTabla(
          'GOLES - ${lado.toUpperCase()}',
        ),

        for (int bloque = 0;
        bloque < bloques;
        bloque++)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Table(
              border: TableBorder.all(
                color: Colors.black54,
                width: 0.6,
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  children: [
                    celda('N.º', negrita: true),

                    for (int i = 0; i < 9; i++)
                      celda(
                        '${bloque * 9 + i + 1}',
                        negrita: true,
                      ),
                  ],
                ),

                TableRow(
                  children: [
                    celda('Jug.'),

                    for (int i = 0; i < 9; i++)
                      celda(
                        bloque * 9 + i < goles.length
                            ? '${goles[bloque * 9 + i]['numero']}'
                            : '',
                      ),
                  ],
                ),

                TableRow(
                  children: [
                    celda('Per.'),

                    for (int i = 0; i < 9; i++)
                      celda(
                        bloque * 9 + i < goles.length
                            ? periodoCorto(
                          goles[bloque * 9 + i]
                          ['periodo'],
                        )
                            : '',
                      ),
                  ],
                ),

                TableRow(
                  children: [
                    celda('Min.'),

                    for (int i = 0; i < 9; i++)
                      celda(
                        bloque * 9 + i < goles.length
                            ? '${goles[bloque * 9 + i]['minuto']}'
                            : '',
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // TABLA DE FALTAS
  // ==========================================

  Widget panelFaltas(String lado) {
    final faltas = eventosDe('falta', lado);

    return Column(
      children: [
        tituloTabla(
          'FALTAS - ${lado.toUpperCase()}',
        ),

        const SizedBox(height: 5),

        Text(
          '1.º tiempo: '
              '${contarPeriodo(
            'falta',
            lado,
            'Primer medio',
          )}  |  '
              '2.º tiempo: '
              '${contarPeriodo(
            'falta',
            lado,
            'Segundo medio',
          )}',
          style: const TextStyle(fontSize: 10),
        ),

        Text(
          'Total: ${faltas.length}',
          style: const TextStyle(fontSize: 10),
        ),

        for (final falta in faltas)
          Text(
            '#${falta['numero']} · '
                'Per. ${periodoCorto(falta['periodo'])} · '
                'Min. ${falta['minuto']}',
            style: const TextStyle(fontSize: 9),
          ),
      ],
    );
  }

  // ==========================================
  // NUEVA TABLA DE SHOOT OUTS
  // ==========================================

  Widget tablaShootouts(String lado) {
    final lista = shootouts.where(
          (intento) => intento['lado'] == lado,
    ).toList();

    return Column(
      children: [
        tituloTabla(
          'SHOOT OUT - ${lado.toUpperCase()}',
        ),

        Table(
          border: TableBorder.all(
            color: Colors.black54,
            width: 0.6,
          ),
          columnWidths: const {
            0: FlexColumnWidth(1.6),
          },
          children: [
            TableRow(
              children: [
                celda('Intento', negrita: true),

                for (int i = 1; i <= 8; i++)
                  celda('$i', negrita: true),
              ],
            ),

            TableRow(
              children: [
                celda('Jug.'),

                for (int i = 0; i < 8; i++)
                  celda(
                    i < lista.length
                        ? '${lista[i]['numero']}'
                        : '',
                  ),
              ],
            ),

            TableRow(
              children: [
                celda('G/F'),

                for (int i = 0; i < 8; i++)
                  celda(
                    i < lista.length
                        ? (lista[i]['resultado'] == 'gol'
                        ? 'G'
                        : 'F')
                        : '',
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 5),

        Text(
          'Aciertos: ${shootoutsAcertados(lado)} '
              'de ${lista.length}',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  // ==========================================
  // TABLA DE TARJETAS
  // ==========================================

  Widget panelTarjetas(String lado) {
    final tarjetas = eventos.where(
          (evento) =>
      evento['lado'] == lado &&
          (evento['tipo'] == 'amarilla' ||
              evento['tipo'] == 'roja'),
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tituloTabla(
          'TARJETAS - ${lado.toUpperCase()}',
        ),

        Text(
          'Amarillas: ${contar('amarilla', lado)} · '
              'Rojas: ${contar('roja', lado)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10),
        ),

        const Divider(color: Colors.black38),

        if (tarjetas.isEmpty)
          const Text(
            'Sin tarjetas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10),
          ),

        for (final tarjeta in tarjetas)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 2,
            ),
            child: Text(
              '${tarjeta['tipo'] == 'amarilla' ? 'AM' : 'R'} '
                  '#${tarjeta['numero']} · '
                  'Min. ${tarjeta['minuto']} · '
                  '${tarjeta['causa']}',
              style: const TextStyle(fontSize: 9),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // DISTRIBUCIÓN VERTICAL DE LA HOJA
  // ==========================================

  Widget seccion(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget dosColumnas(
      Widget local,
      Widget visitante,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: local),

        const SizedBox(width: 12),

        Expanded(child: visitante),
      ],
    );
  }

  Widget marcadorHoja() {
    return Row(
      children: [
        Expanded(
          child: tituloTabla(
            equipoLocal?['nombre']?.toString() ??
                'LOCAL',
          ),
        ),

        Container(
          width: 95,
          margin: const EdgeInsets.symmetric(
            horizontal: 6,
          ),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black87,
            ),
          ),
          child: Text(
            '${contar('gol', 'local')} - '
                '${contar('gol', 'visitante')}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Expanded(
          child: tituloTabla(
            equipoVisitante?['nombre']?.toString() ??
                'VISITANTE',
          ),
        ),
      ],
    );
  }

  Widget firmas() {
    const etiquetas = [
      'FIRMA LOCAL',
      'ÁRBITRO 1',
      'ÁRBITRO 2',
      'ARB. ASISTENTE',
      'CRONOMETRISTA',
      'FIRMA VISITANTE',
    ];

    return Row(
      children: [
        for (final texto in etiquetas)
          Expanded(
            child: Container(
              height: 55,
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.all(3),
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black87,
                ),
              ),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget hojaVertical(double ancho) {
    return Container(
      width: ancho,
      constraints: BoxConstraints(
        minHeight: ancho * 1.40,
      ),
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black26,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.black,
        ),
        child: Column(
          children: [
            encabezadoHoja(),

            marcadorHoja(),

            const SizedBox(height: 10),

            // LOCAL Y VISITANTE EN PARALELO
            // HASTA 20 JUGADORES POR EQUIPO

            dosColumnas(
              tablaJugadores(
                'local',
                equipoLocal,
              ),
              tablaJugadores(
                'visitante',
                equipoVisitante,
              ),
            ),

            const SizedBox(height: 10),

            dosColumnas(
              cuerpoTecnico(
                dato('dtLocal'),
                dato('atLocal'),
              ),
              cuerpoTecnico(
                dato('dtVisitante'),
                dato('atVisitante'),
              ),
            ),

            seccion('REGISTRO DE GOLES'),

            dosColumnas(
              tablaGoles('local'),
              tablaGoles('visitante'),
            ),

            seccion('FALTAS'),

            dosColumnas(
              panelFaltas('local'),
              panelFaltas('visitante'),
            ),

            seccion('DEFINICIÓN EN SHOOT OUT'),

            dosColumnas(
              tablaShootouts('local'),
              tablaShootouts('visitante'),
            ),

            seccion('TARJETAS'),

            dosColumnas(
              panelTarjetas('local'),
              panelTarjetas('visitante'),
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 80,
              ),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black87,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OBSERVACIONES:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    dato('observaciones'),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            firmas(),

            const SizedBox(height: 10),

            const Text(
              'VISTA PREVIA DIGITAL EN DESARROLLO',
              style: TextStyle(
                fontSize: 9,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget vistaPrevia() {
    return LayoutBuilder(
      builder: (context, espacio) {
        final ancho =
        (espacio.maxWidth - 24)
            .clamp(690.0, 850.0)
            .toDouble();

        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: espacio.maxWidth > ancho + 24
                  ? espacio.maxWidth
                  : ancho + 16,
              child: Center(
                child: hojaVertical(ancho),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (final controlador in campos.values) {
      controlador.dispose();
    }

    super.dispose();
  }

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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(error!),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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

          Expanded(
            child: vistaHoja
                ? vistaPrevia()
                : editor(),
          ),
        ],
      ),
    );
  }
}
