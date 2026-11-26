import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'almacen_tablas.dart';

import 'cedula_tactil.dart';
import 'arena_estilo.dart';

// ================================================
// DATOS DE UNA FIRMA LOCALIZADA EN LA HOJA
// ================================================

class _FirmaLocalizada {
  final String clave;
  final Uint8List imagen;
  final ui.Rect rectangulo;

  const _FirmaLocalizada({
    required this.clave,
    required this.imagen,
    required this.rectangulo,
  });
}

// ================================================
// HISTORIAL DE CEDULAS
// ================================================

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
      final lista = await AlmacenTablas.cargarHistorial();
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
    final valor = cedula[clave];

    if (valor is Map) {
      return (valor['nombre'] ?? 'SIN EQUIPO')
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
          'Se eliminará el documento con sus firmas del historial. '
              'Los puntos y estadísticas oficiales permanecerán. '
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
      await AlmacenTablas.eliminarCedula(cedula['id'].toString());

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

  // ================================================
  // TARJETA METÁLICA DE PARTIDO GUARDADO
  // ================================================

  Widget tarjetaCedula(Map<String, dynamic> cedula) {
    final local = nombreEquipo(cedula, 'equipoLocal');
    final visitante = nombreEquipo(cedula, 'equipoVisitante');

    final firmasGuardadas = cedula['firmas'];
    final cantidadFirmas = firmasGuardadas is Map
        ? firmasGuardadas.values
        .where((valor) => valor.toString().isNotEmpty)
        .length
        : 0;

    return Card(
      color: const Color(0xFFFCFAF7),
      elevation: 5,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(
          color: ArenaColores.dorado,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sports_soccer,
                  color: ArenaColores.rojo,
                  size: 23,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$local VS $visitante',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ArenaColores.negro,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            const Divider(
              color: Color(0xFFD9B48F),
              height: 1,
            ),
            const SizedBox(height: 10),
            Text(
              'Torneo: ${cedula['torneo'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ArenaColores.negro,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Fecha: ${cedula['fecha'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ArenaColores.negro,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'MARCADOR: '
                  '${cedula['golesLocal'] ?? 0} - '
                  '${cedula['golesVisitante'] ?? 0}',
              style: const TextStyle(
                color: ArenaColores.rojo,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Firmas: $cantidadFirmas de 6',
              style: const TextStyle(
                color: Color(0xFF665B54),
                fontSize: 12,
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
                          builder: (_) => DetalleCedula(
                            cedula: Map<String, dynamic>.from(
                              cedula,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArenaColores.negro,
                      foregroundColor: ArenaColores.dorado,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: ArenaColores.dorado,
                          width: 1.2,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 20),
                    label: const Text(
                      'VER CÉDULA',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Eliminar cédula',
                  onPressed: () => eliminarCedula(cedula),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: ArenaColores.rojo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================
  // HISTORIAL CON FONDO ARENA MOUSTACHE
  // ================================================

  Widget contenidoHistorial() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: ArenaColores.dorado,
        ),
      );
    }

    if (error != null || cedulas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: ArenaPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    error != null
                        ? Icons.error_outline
                        : Icons.folder_open,
                    size: 50,
                    color: ArenaColores.rojo,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    error ??
                        'No hay cédulas guardadas.\n'
                            'Crea una nueva cédula y guarda el resultado definitivo.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ArenaColores.negro,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, espacio) {
        final columnas = espacio.maxWidth >= 760 ? 2 : 1;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cedulas.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas,
                mainAxisExtent: 265,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, i) {
                return tarjetaCedula(cedulas[i]);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'HISTORIAL DE CÉDULAS',
      ),
      body: ArenaFondo(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: ArenaTextoMetalico(
                      texto: 'CÉDULAS GUARDADAS',
                      tamano: 21,
                      dorado: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: cargarCedulas,
                    tooltip: 'Actualizar historial',
                    style: IconButton.styleFrom(
                      backgroundColor: ArenaColores.negro,
                      side: const BorderSide(
                        color: ArenaColores.dorado,
                        width: 1.3,
                      ),
                    ),
                    icon: const Icon(
                      Icons.refresh,
                      color: ArenaColores.dorado,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: contenidoHistorial()),
          ],
        ),
      ),
    );
  }
}

// ================================================
// DETALLE DE CEDULA
// ================================================

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

  final ValueNotifier<bool> exportandoPdf =
  ValueNotifier<bool>(false);

  late final Map<String, TextEditingController>
  campos;

  late final Map<String, dynamic>? equipoLocal;
  late final Map<String, dynamic>? equipoVisitante;

  late final List<Map<String, dynamic>> eventos;
  late final List<Map<String, dynamic>> shootouts;
  late final List<Map<String, dynamic>> faltasBloques;
  late final List<Map<String, dynamic>> marcasVisuales;
  late final Map<String, String> firmas;

  // Claves de las firmas originales.
  static const List<String> clavesFirmas = [
    'firmaLocal',
    'firmaArbitro1',
    'firmaArbitro2',
    'firmaAsistente',
    'firmaCronometrista',
    'firmaVisitante',
  ];

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
    faltasBloques = convertirLista(guardada['faltasBloques']);
    marcasVisuales = convertirLista(guardada['marcasVisuales']);

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

  void mostrarMensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  // ================================================
  // ENCONTRAR LAS IMAGENES REALES DE LAS FIRMAS
  // ================================================

  List<_FirmaLocalizada> localizarFirmas(
      RenderRepaintBoundary limite,
      ) {
    final contextHoja = capturaKey.currentContext;

    if (contextHoja is! Element) {
      throw StateError(
        'No se puede acceder a la hoja original.',
      );
    }

    final localizadas = <String, _FirmaLocalizada>{};

    void recorrer(Element elemento) {
      final componente = elemento.widget;

      if (componente is Image &&
          componente.image is MemoryImage) {
        final proveedor =
        componente.image as MemoryImage;

        final firmaBase64 = base64Encode(
          proveedor.bytes,
        );

        for (final clave in clavesFirmas) {
          if (localizadas.containsKey(clave)) {
            continue;
          }

          if (firmas[clave] != firmaBase64) {
            continue;
          }

          final objeto = elemento.findRenderObject();

          if (objeto is! RenderBox ||
              !objeto.attached ||
              objeto.size.isEmpty) {
            continue;
          }

          final transformacion =
          objeto.getTransformTo(limite);

          final rectangulo = MatrixUtils.transformRect(
            transformacion,
            ui.Offset.zero & objeto.size,
          );

          if (rectangulo.isEmpty ||
              !rectangulo.left.isFinite ||
              !rectangulo.top.isFinite) {
            continue;
          }

          localizadas[clave] = _FirmaLocalizada(
            clave: clave,
            imagen: proveedor.bytes,
            rectangulo: rectangulo,
          );

          break;
        }
      }

      elemento.visitChildren(recorrer);
    }

    recorrer(contextHoja);

    return [
      for (final clave in clavesFirmas)
        if (localizadas.containsKey(clave))
          localizadas[clave]!,
    ];
  }

  int contarFirmasEsperadas() {
    return clavesFirmas.where(
          (clave) =>
      (firmas[clave] ?? '').trim().isNotEmpty,
    ).length;
  }

  // ================================================
  // EXPORTACION PDF CON FIRMAS SUPERPUESTAS
  // ================================================

  Future<void> guardarPdf() async {
    if (exportandoPdf.value) return;

    exportandoPdf.value = true;

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      final objeto = capturaKey.currentContext
          ?.findRenderObject();

      if (objeto is! RenderRepaintBoundary) {
        throw StateError(
          'No se encontró la hoja para exportar.',
        );
      }

      if (objeto.size.isEmpty) {
        throw StateError(
          'La hoja no tiene un tamaño válido.',
        );
      }

      // Identificamos las imágenes originales
      // de las firmas y sus coordenadas.
      final firmasLocalizadas = localizarFirmas(
        objeto,
      );

      final esperadas = contarFirmasEsperadas();

      if (firmasLocalizadas.length != esperadas) {
        throw StateError(
          'Se localizaron ${firmasLocalizadas.length} '
              'de $esperadas firmas guardadas. '
              'No se exportó el PDF para evitar '
              'generar una cédula incompleta.',
        );
      }

      // Capturamos la misma hoja que aparece
      // dentro de HISTORIAL.
      final escala = math.min(
        2.0,
        math.min(
          3000.0 / objeto.size.width,
          6000.0 / objeto.size.height,
        ),
      );

      final ui.Image captura = await objeto.toImage(
        pixelRatio: escala,
      );

      final datos = await captura.toByteData(
        format: ui.ImageByteFormat.png,
      );

      captura.dispose();

      if (datos == null) {
        throw StateError(
          'No se pudo capturar la cédula.',
        );
      }

      final Uint8List pngHoja =
      datos.buffer.asUint8List();

      final documento = pw.Document();

      final imagenHoja = pw.MemoryImage(pngHoja);

      // Formato A4 vertical.
      final anchoPagina = PdfPageFormat.a4.width;
      final altoPagina = PdfPageFormat.a4.height;

      final factor = math.min(
        anchoPagina / objeto.size.width,
        altoPagina / objeto.size.height,
      );

      final anchoDibujado =
          objeto.size.width * factor;

      final altoDibujado =
          objeto.size.height * factor;

      final margenX =
          (anchoPagina - anchoDibujado) / 2;

      final margenY =
          (altoPagina - altoDibujado) / 2;

      // Aquí está la corrección:
      // pw.Positioned recibe la ubicación.
      // pw.SizedBox recibe el ancho y alto.
      final capasPdf = <pw.Widget>[
        pw.Positioned(
          left: margenX,
          top: margenY,
          child: pw.SizedBox(
            width: anchoDibujado,
            height: altoDibujado,
            child: pw.Image(
              imagenHoja,
              fit: pw.BoxFit.fill,
            ),
          ),
        ),
      ];

      // Incorporar los PNG de las firmas
      // sobre sus posiciones originales.
      for (final firma in firmasLocalizadas) {
        final rectangulo = firma.rectangulo;

        final izquierda =
            margenX + rectangulo.left * factor;

        final arriba =
            margenY + rectangulo.top * factor;

        final ancho =
            rectangulo.width * factor;

        final alto =
            rectangulo.height * factor;

        if (ancho <= 0 || alto <= 0) {
          throw StateError(
            'La posición de ${firma.clave} '
                'no es válida.',
          );
        }

        // Segunda corrección:
        // Las medidas también pertenecen
        // a pw.SizedBox, no a pw.Positioned.
        capasPdf.add(
          pw.Positioned(
            left: izquierda,
            top: arriba,
            child: pw.SizedBox(
              width: ancho,
              height: alto,
              child: pw.Image(
                pw.MemoryImage(firma.imagen),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        );
      }

      documento.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Stack(
            fit: pw.StackFit.expand,
            children: capasPdf,
          ),
        ),
      );

      final bytesPdf = await documento.save();

      final archivo =
      'cedula_${nombreEquipo(equipoLocal)}_vs_'
          '${nombreEquipo(equipoVisitante)}.pdf'
          .replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );

      if (!mounted) return;

      await Printing.sharePdf(
        bytes: bytesPdf,
        filename: archivo,
      );

      if (!mounted) return;

      mostrarMensaje(
        'PDF generado con '
            '${firmasLocalizadas.length} firmas.',
      );
    } catch (e) {
      mostrarMensaje(
        'No se pudo exportar el PDF: $e',
      );
    } finally {
      if (mounted) {
        exportandoPdf.value = false;
      }
    }
  }

  // ================================================
  // REUTILIZAR LA CEDULA ORIGINAL SIN EDITARLA
  // ================================================

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
            faltasBloques: faltasBloques,
            marcasVisuales: marcasVisuales,
            firmas: firmas,

            onCamposActualizados: () {},

            onEventosActualizados: (_) {},
            onFaltasBloquesActualizadas: (_) {},
            onMarcasVisualesActualizadas: (_) {},

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

  // ================================================
  // DETALLE CON DISEÑO ARENA MOUSTACHE
  // LA HOJA Y LA GENERACIÓN DEL PDF NO CAMBIAN
  // ================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'CÉDULA GUARDADA',
      ),
      body: ArenaFondo(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ValueListenableBuilder<bool>(
                  valueListenable: exportandoPdf,
                  builder: (context, ocupada, _) {
                    return ElevatedButton.icon(
                      onPressed: ocupada ? null : guardarPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArenaColores.negro,
                        foregroundColor: ArenaColores.dorado,
                        disabledBackgroundColor: const Color(0xFF625858),
                        disabledForegroundColor: Colors.white70,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: ArenaColores.dorado,
                            width: 1.5,
                          ),
                        ),
                      ),
                      icon: ocupada
                          ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ArenaColores.dorado,
                        ),
                      )
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(
                        ocupada ? 'GENERANDO PDF...' : 'GUARDAR PDF',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xD91B0505),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0x80FFD36B),
                  ),
                ),
                child: const Text(
                  'Vista de la cédula original. '
                      'Desliza para recorrer la hoja.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
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
      ),
    );
  }
}
