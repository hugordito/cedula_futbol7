
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cedula_tactil.dart';

// =============================================
// HISTORIAL DE CÉDULAS
// =============================================

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
    cargarCedulas();
  }

  Future<void> cargarCedulas() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final texto = await prefs.getString(
        'cedulas_borrador',
      );

      final guardadas =
      jsonDecode(texto ?? '[]') as List;

      final lista = guardadas
          .map(
            (e) => Map<String, dynamic>.from(
          e as Map,
        ),
      )
          .toList();

      lista.sort(
            (a, b) => (b['creadaEn'] ?? '')
            .toString()
            .compareTo(
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
        error = 'No se pudo cargar el historial: $e';
      });
    }
  }

  String nombreEquipo(
      Map<String, dynamic> cedula,
      String clave,
      ) {
    final equipo = cedula[clave];

    if (equipo is Map) {
      return (equipo['nombre'] ?? 'SIN EQUIPO')
          .toString();
    }

    return 'SIN EQUIPO';
  }

  Future<void> eliminarCedula(
      Map<String, dynamic> cedula,
      ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar cédula'),
        content: const Text(
          'Se eliminarán los datos y las firmas '
              'de esta cédula. '
              'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogo, false);
            },
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogo, true);
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (!mounted || confirmar != true) return;

    try {
      final prefs = SharedPreferencesAsync();

      final texto = await prefs.getString(
        'cedulas_borrador',
      );

      final lista =
      (jsonDecode(texto ?? '[]') as List)
          .map(
            (e) => Map<String, dynamic>.from(
          e as Map,
        ),
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

      await cargarCedulas();
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

  Widget tarjetaCedula(
      Map<String, dynamic> cedula,
      ) {
    final local = nombreEquipo(
      cedula,
      'equipoLocal',
    );

    final visitante = nombreEquipo(
      cedula,
      'equipoVisitante',
    );

    final guardadas = cedula['firmas'];

    final totalFirmas =
    guardadas is Map ? guardadas.length : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Text(
              '$local VS $visitante',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Torneo: ${cedula['torneo'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            Text(
              'Fecha: ${cedula['fecha'] ?? ''}',
            ),

            const SizedBox(height: 6),

            Text(
              'MARCADOR: '
                  '${cedula['golesLocal'] ?? 0} - '
                  '${cedula['golesVisitante'] ?? 0}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text('Firmas: $totalFirmas de 6'),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => DetalleCedula(
                            cedula:
                            Map<String, dynamic>.from(
                              cedula,
                            ),
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
                  tooltip: 'Eliminar borrador',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    eliminarCedula(cedula);
                  },
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
        title: const Text('HISTORIAL DE CÉDULAS'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: cargarCedulas,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar historial',
          ),
        ],
      ),

      body: cargando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : error != null
          ? Center(child: Text(error!))
          : cedulas.isEmpty
          ? const Center(
        child: Text(
          'Aún no hay cédulas guardadas.\n'
              'Crea una cédula y guarda '
              'el borrador.',
          textAlign: TextAlign.center,
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
                itemCount: cedulas.length,
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  mainAxisExtent: 235,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, i) {
                  return tarjetaCedula(
                    cedulas[i],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================
// DETALLE DE CÉDULA
// UTILIZA LA MISMA CedulaTactil ORIGINAL
// =============================================

class DetalleCedula extends StatefulWidget {
  final Map<String, dynamic> cedula;

  const DetalleCedula({
    super.key,
    required this.cedula,
  });

  @override
  State<DetalleCedula> createState() =>
      _DetalleCedulaState();
}

class _DetalleCedulaState extends State<DetalleCedula> {
  final GlobalKey capturaKey = GlobalKey();

  // IMPORTANTE:
  // Este indicador reconstruye SOLO el botón.
  // No reconstruye la hoja ni sus firmas.
  final ValueNotifier<bool> exportandoPdf =
  ValueNotifier<bool>(false);

  late final Map<String, TextEditingController>
  campos;

  late final Map<String, dynamic>? equipoLocal;
  late final Map<String, dynamic>? equipoVisitante;

  late final List<Map<String, dynamic>> eventos;
  late final List<Map<String, dynamic>> shootouts;

  late final Map<String, String> firmas;

  static const List<String> clavesCampos = [
    'ciudad',
    'torneo',
    'cancha',
    'fecha',
    'hora',
    'jornada',
    'categoria',
    'rama',
    'arbitro',
    'observaciones',
    'dtLocal',
    'atLocal',
    'dtVisitante',
    'atVisitante',
  ];

  @override
  void initState() {
    super.initState();

    final guardada = widget.cedula;

    campos = {
      for (final clave in clavesCampos)
        clave: TextEditingController(
          text: (guardada[clave] ?? '').toString(),
        ),
    };

    equipoLocal = convertirEquipo(
      guardada['equipoLocal'],
    );

    equipoVisitante = convertirEquipo(
      guardada['equipoVisitante'],
    );

    eventos = convertirLista(
      guardada['eventos'],
    );

    shootouts = convertirLista(
      guardada['shootouts'],
    );

    firmas = convertirFirmas(
      guardada['firmas'],
    );
  }

  Map<String, dynamic>? convertirEquipo(
      dynamic valor,
      ) {
    if (valor is Map) {
      return Map<String, dynamic>.from(valor);
    }

    return null;
  }

  List<Map<String, dynamic>> convertirLista(
      dynamic valor,
      ) {
    if (valor is! List) return [];

    return valor
        .whereType<Map>()
        .map(
          (e) => Map<String, dynamic>.from(e),
    )
        .toList();
  }

  Map<String, String> convertirFirmas(
      dynamic valor,
      ) {
    if (valor is! Map) return {};

    return valor.map<String, String>(
          (clave, imagen) => MapEntry(
        clave.toString(),
        imagen.toString(),
      ),
    );
  }

  String nombreEquipo(
      Map<String, dynamic>? equipo,
      ) {
    return (equipo?['nombre'] ?? 'SIN EQUIPO')
        .toString();
  }

  void mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
      ),
    );
  }

  // =============================================
  // GENERAR EL PDF SIN RECONSTRUIR LAS FIRMAS
  // =============================================

  Future<void> guardarPdf() async {
    if (exportandoPdf.value) return;

    // No utilizamos setState en esta función.
    // Así no reiniciamos las imágenes de las firmas
    // que ya estaban visibles en el historial.
    exportandoPdf.value = true;

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      final render = capturaKey.currentContext
          ?.findRenderObject();

      if (render is! RenderRepaintBoundary) {
        throw Exception(
          'No se encontró la hoja para exportar.',
        );
      }

      if (render.size.isEmpty) {
        throw Exception(
          'La hoja no tiene un tamaño válido.',
        );
      }

      // Captura la misma hoja que muestra
      // el historial, sin reconstruir sus tablas.
      final escala = math.min(
        2.0,
        math.min(
          3000.0 / render.size.width,
          6000.0 / render.size.height,
        ),
      );

      final ui.Image imagen = await render.toImage(
        pixelRatio: escala,
      );

      final datos = await imagen.toByteData(
        format: ui.ImageByteFormat.png,
      );

      imagen.dispose();

      if (datos == null) {
        throw Exception(
          'No se pudo generar la imagen '
              'de la cédula.',
        );
      }

      final Uint8List png =
      datos.buffer.asUint8List();

      final documento = pw.Document();

      final imagenPdf = pw.MemoryImage(png);

      documento.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Center(
            child: pw.Image(
              imagenPdf,
              width: PdfPageFormat.a4.width,
              height: PdfPageFormat.a4.height,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );

      final bytesPdf = await documento.save();

      final nombre =
      'cedula_${nombreEquipo(equipoLocal)}_vs_'
          '${nombreEquipo(equipoVisitante)}.pdf'
          .replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );

      if (!mounted) return;

      await Printing.sharePdf(
        bytes: bytesPdf,
        filename: nombre,
      );
    } catch (e) {
      mensaje(
        'No se pudo generar el PDF: $e',
      );
    } finally {
      if (mounted) {
        exportandoPdf.value = false;
      }
    }
  }

  // =============================================
  // HOJA ORIGINAL EN MODO SOLO LECTURA
  // =============================================

  Widget hojaOriginal() {
    return RepaintBoundary(
      key: capturaKey,
      child: IgnorePointer(
        ignoring: true,
        child: SizedBox(
          width: 870,
          child: CedulaTactil(
            campos: campos,
            equipoLocal: equipoLocal,
            equipoVisitante: equipoVisitante,
            eventos: eventos,
            shootouts: shootouts,
            firmas: firmas,

            onCamposActualizados: () {},

            onEventosActualizados: (_) {},

            onFirmasActualizadas: (_) {},

            onEditarEquipos: () async {},

            onEditarShootouts: () async {},
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    exportandoPdf.dispose();

    for (final controlador in campos.values) {
      controlador.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CÉDULA GUARDADA'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 48,

              // Solo este botón cambia cuando
              // comienza o termina la exportación.
              child: ValueListenableBuilder<bool>(
                valueListenable: exportandoPdf,
                builder: (context, ocupada, _) {
                  return ElevatedButton.icon(
                    onPressed: ocupada
                        ? null
                        : guardarPdf,

                    icon: ocupada
                        ? const SizedBox(
                      width: 19,
                      height: 19,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      Icons.picture_as_pdf,
                    ),

                    label: Text(
                      ocupada
                          ? 'GENERANDO PDF...'
                          : 'GUARDAR PDF',
                    ),
                  );
                },
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Text(
              'Vista de la cédula original. '
                  'Desliza para recorrerla.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Expanded(
            child: LayoutBuilder(
              builder: (context, espacio) {
                final ancho = math.max(
                  espacio.maxWidth,
                  870.0,
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: ancho,
                      child: Center(
                        child: hojaOriginal(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
