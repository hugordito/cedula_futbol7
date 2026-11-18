
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistorialCedulas extends StatefulWidget {
  const HistorialCedulas({super.key});

  @override
  State<HistorialCedulas> createState() =>
      _HistorialCedulasState();
}

class _HistorialCedulasState
    extends State<HistorialCedulas> {
  List<Map<String, dynamic>> cedulas = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final texto =
      await prefs.getString('cedulas_borrador');

      final lista = (jsonDecode(texto ?? '[]') as List)
          .map(
            (e) => Map<String, dynamic>.from(e as Map),
      )
          .toList();

      lista.sort(
            (a, b) =>
            (b['creadaEn'] ?? '').toString().compareTo(
              (a['creadaEn'] ?? '').toString(),
            ),
      );

      if (!mounted) return;

      setState(() {
        cedulas = lista;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = 'Error al leer las cédulas: $e';
      });
    }
  }

  Future<void> eliminar(
      Map<String, dynamic> cedula,
      ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar borrador'),
        content: const Text(
          'Esta acción eliminará la cédula guardada. '
              'No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (!mounted || confirmar != true) return;

    try {
      final prefs = SharedPreferencesAsync();

      final texto =
      await prefs.getString('cedulas_borrador');

      final lista = (jsonDecode(texto ?? '[]') as List)
          .map(
            (e) => Map<String, dynamic>.from(e as Map),
      )
          .where(
            (e) =>
        e['id'].toString() !=
            cedula['id'].toString(),
      )
          .toList();

      await prefs.setString(
        'cedulas_borrador',
        jsonEncode(lista),
      );

      if (!mounted) return;

      await cargar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar: $e',
          ),
        ),
      );
    }
  }

  String nombreEquipo(
      Map<String, dynamic> cedula,
      String clave,
      ) {
    final equipo = cedula[clave];

    if (equipo is Map) {
      return (equipo['nombre'] ?? 'Sin equipo')
          .toString();
    }

    return 'Sin equipo';
  }

  Widget tarjeta(Map<String, dynamic> cedula) {
    final local =
    nombreEquipo(cedula, 'equipoLocal');

    final visitante =
    nombreEquipo(cedula, 'equipoVisitante');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Text(
              '$local  vs  $visitante',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Torneo: ${cedula['torneo'] ?? ''}',
            ),

            Text(
              'Fecha: ${cedula['fecha'] ?? ''}',
            ),

            Text(
              'Marcador: '
                  '${cedula['golesLocal'] ?? 0} - '
                  '${cedula['golesVisitante'] ?? 0}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              DetalleCedula(
                                cedula: cedula,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.visibility,
                    ),
                    label: const Text('VER CÉDULA'),
                  ),
                ),

                IconButton(
                  onPressed: () => eliminar(cedula),
                  tooltip: 'Eliminar borrador',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HISTORIAL DE CÉDULAS',
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: cargar,
            tooltip: 'Actualizar historial',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: cargando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : error != null
          ? Center(
        child: Text(error!),
      )
          : cedulas.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No hay borradores guardados todavía.\n'
                'Crea una cédula y toca '
                'GUARDAR BORRADOR.',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : LayoutBuilder(
        builder: (context, espacio) {
          final columnas =
          espacio.maxWidth >= 760
              ? 2
              : 1;

          return Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 1100,
              ),
              child: GridView.builder(
                padding:
                const EdgeInsets.all(16),
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  mainAxisExtent: 205,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: cedulas.length,
                itemBuilder: (context, i) =>
                    tarjeta(cedulas[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// DETALLE DE UNA CÉDULA GUARDADA
// ==========================================

class DetalleCedula extends StatelessWidget {
  final Map<String, dynamic> cedula;

  const DetalleCedula({
    super.key,
    required this.cedula,
  });

  Map<String, dynamic> equipo(String clave) {
    final dato = cedula[clave];

    if (dato is Map) {
      return Map<String, dynamic>.from(dato);
    }

    return {};
  }

  List<Map<String, dynamic>> lista(String clave) {
    final datos = cedula[clave];

    if (datos is! List) return [];

    return datos
        .whereType<Map>()
        .map(
          (e) => Map<String, dynamic>.from(e),
    )
        .toList();
  }

  int cantidad(
      String tipo,
      String lado,
      int numero,
      ) {
    return lista('eventos').where(
          (e) =>
      e['tipo'] == tipo &&
          e['lado'] == lado &&
          int.tryParse(
            '${e['numero']}',
          ) ==
              numero,
    ).length;
  }

  Widget titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget celda(
      String valor, {
        bool negrita = false,
      }) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        valor,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: negrita
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  Widget tablaEquipo(
      String lado,
      String clave,
      ) {
    final datosEquipo = equipo(clave);

    final jugadores =
        (datosEquipo['jugadores'] as List?) ?? [];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black54,
            ),
          ),
          child: Text(
            '${lado.toUpperCase()}: '
                '${datosEquipo['nombre'] ?? 'Sin seleccionar'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        Table(
          border: TableBorder.all(
            color: Colors.black54,
          ),
          columnWidths: const {
            0: FixedColumnWidth(26),
            1: FixedColumnWidth(30),
            2: FlexColumnWidth(5),
            3: FixedColumnWidth(25),
            4: FixedColumnWidth(25),
            5: FixedColumnWidth(25),
            6: FixedColumnWidth(25),
          },
          children: [
            TableRow(
              children: [
                celda('Nº', negrita: true),
                celda('#', negrita: true),
                celda('Jugador', negrita: true),
                celda('G', negrita: true),
                celda('A', negrita: true),
                celda('R', negrita: true),
                celda('F', negrita: true),
              ],
            ),

            for (int i = 0; i < 20; i++)
              TableRow(
                children: [
                  celda('${i + 1}'),

                  celda(
                    i < jugadores.length
                        ? '${(jugadores[i] as Map)['numero']}'
                        : '',
                  ),

                  celda(
                    i < jugadores.length
                        ? '${(jugadores[i] as Map)['nombre']}'
                        : '',
                  ),

                  celda(
                    i < jugadores.length
                        ? '${cantidad(
                      'gol',
                      lado,
                      int.tryParse(
                        '${(jugadores[i] as Map)['numero']}',
                      ) ??
                          -1,
                    )}'
                        : '',
                  ),

                  celda(
                    i < jugadores.length
                        ? '${cantidad(
                      'amarilla',
                      lado,
                      int.tryParse(
                        '${(jugadores[i] as Map)['numero']}',
                      ) ??
                          -1,
                    )}'
                        : '',
                  ),

                  celda(
                    i < jugadores.length
                        ? '${cantidad(
                      'roja',
                      lado,
                      int.tryParse(
                        '${(jugadores[i] as Map)['numero']}',
                      ) ??
                          -1,
                    )}'
                        : '',
                  ),

                  celda(
                    i < jugadores.length
                        ? '${cantidad(
                      'falta',
                      lado,
                      int.tryParse(
                        '${(jugadores[i] as Map)['numero']}',
                      ) ??
                          -1,
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

  Widget listaEventos() {
    final eventos = lista('eventos');
    final shootouts = lista('shootouts');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        titulo('GOLES, FALTAS Y TARJETAS'),

        if (eventos.isEmpty)
          const Text(
            'Sin acontecimientos registrados.',
          ),

        for (final e in eventos)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 3,
            ),
            child: Text(
              '${e['lado'] == 'local' ? 'LOCAL' : 'VISITANTE'} · '
                  '${(e['tipo'] ?? '').toString().toUpperCase()} · '
                  '#${e['numero']} ${e['jugador']} · '
                  '${e['periodo']} · Min ${e['minuto']}'
                  '${(e['causa'] ?? '').toString().isEmpty ? '' : ' · ${e['causa']}'}',
              style: const TextStyle(fontSize: 12),
            ),
          ),

        titulo('SHOOT OUTS'),

        if (shootouts.isEmpty)
          const Text(
            'Sin intentos registrados.',
          ),

        for (final s in shootouts)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 3,
            ),
            child: Text(
              '${s['lado'] == 'local' ? 'LOCAL' : 'VISITANTE'} · '
                  '#${s['numero']} ${s['jugador']} · '
                  '${s['resultado'] == 'gol' ? 'GOL' : 'FALLÓ'}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BORRADOR GUARDADO'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),

      body: LayoutBuilder(
        builder: (context, espacio) {
          final ancho = espacio.maxWidth < 730
              ? 730.0
              : espacio.maxWidth
              .clamp(730.0, 960.0)
              .toDouble();

          return SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: ancho,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'ACTA DE JUEGO FÚTBOL 7',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Torneo: ${cedula['torneo'] ?? ''} · '
                            'Fecha: ${cedula['fecha'] ?? ''} · '
                            'Cancha: ${cedula['cancha'] ?? ''}',
                        textAlign: TextAlign.center,
                      ),

                      titulo(
                        'MARCADOR: '
                            '${cedula['golesLocal'] ?? 0} - '
                            '${cedula['golesVisitante'] ?? 0}',
                      ),

                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: tablaEquipo(
                              'local',
                              'equipoLocal',
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: tablaEquipo(
                              'visitante',
                              'equipoVisitante',
                            ),
                          ),
                        ],
                      ),

                      listaEventos(),

                      titulo('OBSERVACIONES'),

                      Text(
                        '${cedula['observaciones'] ?? ''}',
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Vista de borrador. '
                            'Aún no es un PDF ni '
                            'una cédula final.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
