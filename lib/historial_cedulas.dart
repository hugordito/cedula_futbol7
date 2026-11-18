
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';
import 'cedula_tactil.dart';

// =============================================
// HISTORIAL DE CEDULAS
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
      final preferencias = SharedPreferencesAsync();

      final texto = await preferencias.getString(
        'cedulas_borrador',
      );

      final datos = jsonDecode(texto ?? '[]') as List;

      final lista = datos
          .map(
            (item) =>
        Map<String, dynamic>.from(item as Map),
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
        error = 'Error al cargar el historial: $e';
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
        title: const Text('ELIMINAR CÉDULA'),
        content: const Text(
          'Se eliminará esta cédula junto con '
              'sus datos y firmas. '
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
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirmar != true) return;

    try {
      final preferencias = SharedPreferencesAsync();

      final texto = await preferencias.getString(
        'cedulas_borrador',
      );

      final lista = (jsonDecode(texto ?? '[]') as List)
          .map(
            (item) =>
        Map<String, dynamic>.from(item as Map),
      )
          .toList();

      lista.removeWhere(
            (item) =>
        item['id'].toString() ==
            cedula['id'].toString(),
      );

      await preferencias.setString(
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
            'No se pudo eliminar la cédula: $e',
          ),
        ),
      );
    }
  }

  void abrirCedula(
      Map<String, dynamic> cedula,
      ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => DetalleCedula(
          cedula: Map<String, dynamic>.from(cedula),
        ),
      ),
    );
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

    final mapaFirmas = cedula['firmas'];

    final totalFirmas =
    mapaFirmas is Map ? mapaFirmas.length : 0;

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

            Text(
              'Firmas: $totalFirmas de 6',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => abrirCedula(cedula),
                    icon: const Icon(
                      Icons.visibility,
                    ),
                    label: const Text(
                      'VER CÉDULA',
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                IconButton(
                  tooltip: 'Eliminar cédula',
                  onPressed: () {
                    eliminarCedula(cedula);
                  },
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
        title: const Text('HISTORIAL DE CÉDULAS'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar historial',
            onPressed: cargarCedulas,
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
            'No hay cédulas guardadas.\n'
                'Crea una cédula y guarda '
                'el borrador.',
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
// DETALLE: MISMA CEDULA ORIGINAL
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

  late final Map<String, TextEditingController> campos;

  late final Map<String, dynamic>? equipoLocal;
  late final Map<String, dynamic>? equipoVisitante;

  late final List<Map<String, dynamic>> eventos;
  late final List<Map<String, dynamic>> shootouts;
  late final Map<String, String> firmas;

  bool exportandoPdf = false;

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

    // Creamos los mismos controladores que
    // utiliza la cédula durante su edición.
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
          (item) =>
      Map<String, dynamic>.from(item),
    )
        .toList();
  }

  Map<String, String> convertirFirmas(
      dynamic valor,
      ) {
    if (valor is! Map) return {};

    return valor.map<String, String>(
          (clave, firma) => MapEntry(
        clave.toString(),
        firma.toString(),
      ),
    );
  }

  String nombreEquipo(
      Map<String, dynamic>? equipo,
      ) {
    return (equipo?['nombre'] ?? 'SIN EQUIPO')
        .toString();
  }

  void mostrarError(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  // =============================================
  // CAPTURA DE LA HOJA Y GENERACION DEL PDF
  // =============================================

  Future<void> guardarPdf() async {
    if (exportandoPdf) return;

    setState(() {
      exportandoPdf = true;
    });

    try {
      // Espera a que la hoja y las firmas
      // terminen de dibujarse.
      await WidgetsBinding.instance.endOfFrame;

      final objeto = capturaKey.currentContext
          ?.findRenderObject();

      if (objeto is! RenderRepaintBoundary) {
        throw Exception(
          'No se encontró la hoja para exportar.',
        );
      }

      if (objeto.size.width <= 0 ||
          objeto.size.height <= 0) {
        throw Exception(
          'La hoja todavía no tiene tamaño válido.',
        );
      }

      // Limitamos el tamaño de la captura para
      // evitar imágenes excesivamente grandes
      // en teléfonos y tablets.
      final escala = math.min(
        2.0,
        math.min(
          3000.0 / objeto.size.width,
          6000.0 / objeto.size.height,
        ),
      );

      final ui.Image imagen = await objeto.toImage(
        pixelRatio: escala,
      );

      final datos = await imagen.toByteData(
        format: ui.ImageByteFormat.png,
      );

      imagen.dispose();

      if (datos == null) {
        throw Exception(
          'No fue posible capturar la cédula.',
        );
      }

      final Uint8List bytesImagen =
      datos.buffer.asUint8List();

      // Usamos la captura original.
      // No reconstruimos tablas, texto ni firmas.
      final documento = pw.Document();

      final imagenPdf = pw.MemoryImage(
        bytesImagen,
      );

      documento.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Image(
                imagenPdf,
                width: PdfPageFormat.a4.width,
                height: PdfPageFormat.a4.height,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      final pdfBytes = await documento.save();

      final local = nombreEquipo(equipoLocal);
      final visitante = nombreEquipo(equipoVisitante);

      final nombreArchivo =
      'cedula_${local}_vs_${visitante}.pdf'
          .replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );

      if (!mounted) return;

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: nombreArchivo,
      );
    } catch (e) {
      mostrarError(
        'No se pudo generar el PDF: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          exportandoPdf = false;
        });
      }
    }
  }


  // CEDULA ORIGINAL EN SOLO LECTURA


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

            // En el historial nada se edita.
            onCamposActualizados: () {},

            onEventosActualizados: (nuevos) {},

            onFirmasActualizadas: (nuevas) {},

            onEditarEquipos: () async {},

            onEditarShootouts: () async {},
          ),
        ),
      ),
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
              child: ElevatedButton.icon(
                onPressed:
                exportandoPdf ? null : guardarPdf,
                icon: exportandoPdf
                    ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.picture_as_pdf,
                ),
                label: Text(
                  exportandoPdf
                      ? 'GENERANDO PDF...'
                      : 'GUARDAR PDF',
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Text(
              'Vista de la cédula original. '
                  'Desliza para recorrer la hoja.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
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
