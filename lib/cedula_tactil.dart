
import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'firma_dialog.dart';

class CedulaTactil extends StatefulWidget {
  final Map<String, TextEditingController> campos;
  final Map<String, dynamic>? equipoLocal;
  final Map<String, dynamic>? equipoVisitante;

  final List<Map<String, dynamic>> eventos;
  final List<Map<String, dynamic>> shootouts;

  final Map<String, String> firmas;

  final VoidCallback onCamposActualizados;

  final ValueChanged<List<Map<String, dynamic>>>
  onEventosActualizados;

  final ValueChanged<Map<String, String>>
  onFirmasActualizadas;

  final Future<void> Function() onEditarEquipos;
  final Future<void> Function() onEditarShootouts;

  const CedulaTactil({
    super.key,
    required this.campos,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.eventos,
    required this.shootouts,
    required this.firmas,
    required this.onCamposActualizados,
    required this.onEventosActualizados,
    required this.onFirmasActualizadas,
    required this.onEditarEquipos,
    required this.onEditarShootouts,
  });

  @override
  State<CedulaTactil> createState() =>
      _CedulaTactilState();
}

class _CedulaTactilState extends State<CedulaTactil> {
  static const int maxJugadores = 20;

  static const List<String> clavesFirmas = [
    'firmaLocal',
    'firmaArbitro1',
    'firmaArbitro2',
    'firmaAsistente',
    'firmaCronometrista',
    'firmaVisitante',
  ];

  static const List<String> titulosFirmas = [
    'FIRMA LOCAL',
    'ÁRBITRO 1',
    'ÁRBITRO 2',
    'ARB. ASISTENTE',
    'CRONOMETRISTA',
    'FIRMA VISITANTE',
  ];

  String dato(String clave) {
    return widget.campos[clave]?.text.trim() ?? '';
  }

  Map<String, dynamic>? equipo(String lado) {
    return lado == 'local'
        ? widget.equipoLocal
        : widget.equipoVisitante;
  }

  List<Map<String, dynamic>> jugadores(String lado) {
    final lista =
        (equipo(lado)?['jugadores'] as List?) ?? [];

    return lista
        .map(
          (item) => Map<String, dynamic>.from(item as Map),
    )
        .toList();
  }

  List<Map<String, dynamic>> eventosDe(
      String lado,
      String tipo,
      ) {
    return widget.eventos
        .where(
          (item) =>
      item['lado'] == lado &&
          item['tipo'] == tipo,
    )
        .toList();
  }

  int contar(
      String lado,
      String tipo, {
        int? numero,
      }) {
    return widget.eventos.where((item) {
      if (item['lado'] != lado ||
          item['tipo'] != tipo) {
        return false;
      }

      if (numero == null) {
        return true;
      }

      return int.tryParse(
        item['numero'].toString(),
      ) ==
          numero;
    }).length;
  }

  void aviso(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  // =========================================
  // EDITAR DATOS GENERALES TOCANDO LA HOJA
  // =========================================

  Future<void> editarCampo(
      String clave,
      String titulo,
      ) async {
    final controlador = TextEditingController(
      text: dato(clave),
    );

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text('Editar $titulo'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          maxLines: clave == 'observaciones' ? 4 : 1,
          decoration: InputDecoration(
            labelText: titulo,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogo);
            },
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogo,
                controlador.text,
              );
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );

    if (!mounted) {
      controlador.dispose();
      return;
    }

    if (resultado != null) {
      widget.campos[clave]?.text = resultado.trim();
      widget.onCamposActualizados();
    }

    controlador.dispose();
  }

  // =========================================
  // FIRMAS DIGITALES
  // =========================================

  Uint8List? obtenerImagenFirma(String clave) {
    final texto = widget.firmas[clave];

    if (texto == null || texto.isEmpty) {
      return null;
    }

    try {
      return base64Decode(texto);
    } catch (_) {
      return null;
    }
  }

  Future<void> editarFirma(
      String clave,
      String titulo,
      ) async {
    final firmaAnterior = obtenerImagenFirma(clave);

    if (firmaAnterior != null) {
      final accion = await showModalBottomSheet<String>(
        context: context,
        builder: (modal) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.draw),
                title: const Text(
                  'FIRMAR DE NUEVO',
                ),
                onTap: () {
                  Navigator.pop(modal, 'reemplazar');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  'ELIMINAR FIRMA',
                ),
                onTap: () {
                  Navigator.pop(modal, 'eliminar');
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('CANCELAR'),
                onTap: () {
                  Navigator.pop(modal, 'cancelar');
                },
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;

      if (accion == 'eliminar') {
        final nuevasFirmas =
        Map<String, String>.from(widget.firmas);

        nuevasFirmas.remove(clave);

        widget.onFirmasActualizadas(nuevasFirmas);
        aviso('Firma eliminada');
        return;
      }

      if (accion != 'reemplazar') {
        return;
      }
    }

    if (!mounted) return;

    final imagen = await FirmaDialog.abrir(
      context,
      titulo: titulo,
      firmaAnterior: firmaAnterior,
    );

    if (!mounted || imagen == null) {
      return;
    }

    final nuevasFirmas =
    Map<String, String>.from(widget.firmas);

    nuevasFirmas[clave] = base64Encode(imagen);

    widget.onFirmasActualizadas(nuevasFirmas);

    aviso('Firma guardada en la cédula');
  }

  Widget casillaFirma(
      String clave,
      String titulo,
      ) {
    final imagen = obtenerImagenFirma(clave);

    return Expanded(
      child: InkWell(
        onTap: () => editarFirma(clave, titulo),
        child: Container(
          height: 93,
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: imagen == null
                ? const Color(0xFFF1F8F3)
                : Colors.white,
            border: Border.all(
              color: Colors.black87,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: imagen == null
                    ? const Center(
                  child: Icon(
                    Icons.draw,
                    size: 23,
                    color: Colors.green,
                  ),
                )
                    : Image.memory(
                  imagen,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget panelFirmas() {
    return Column(
      children: [
        seccion('FIRMAS DEL PARTIDO'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < clavesFirmas.length; i++)
              casillaFirma(
                clavesFirmas[i],
                titulosFirmas[i],
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Toca cualquier recuadro para firmar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // =========================================
  // REGISTRO TACTIL DE ACONTECIMIENTOS
  // =========================================

  Future<void> editarEvento(
      String lado,
      String tipo, {
        Map<String, dynamic>? existente,
        int? numeroInicial,
        bool elegirTipoTarjeta = false,
      }) async {
    final plantilla = jugadores(lado);

    if (plantilla.isEmpty) {
      aviso('Primero registra y carga los jugadores');
      return;
    }

    String tipoSeleccionado =
        existente?['tipo']?.toString() ?? tipo;

    String periodo =
        existente?['periodo']?.toString() ??
            'Primer medio';

    int? numeroSeleccionado = int.tryParse(
      existente?['numero']?.toString() ?? '',
    ) ??
        numeroInicial;

    final numerosValidos = plantilla
        .map(
          (jugador) => int.tryParse(
        jugador['numero'].toString(),
      ),
    )
        .whereType<int>()
        .toSet();

    if (!numerosValidos.contains(numeroSeleccionado)) {
      numeroSeleccionado = null;
    }

    final minuto = TextEditingController(
      text: existente?['minuto']?.toString() ?? '',
    );

    final causa = TextEditingController(
      text: existente?['causa']?.toString() ?? '',
    );

    String? error;

    final respuesta =
    await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (modal) => StatefulBuilder(
        builder: (modal, actualizarModal) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.of(modal).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${existente == null ? 'REGISTRAR' : 'EDITAR'} '
                        '${tipoSeleccionado.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lado == 'local'
                        ? 'EQUIPO LOCAL'
                        : 'EQUIPO VISITANTE',
                  ),
                  const SizedBox(height: 18),

                  if (elegirTipoTarjeta) ...[
                    const Text('Tipo de tarjeta'),
                    DropdownButton<String>(
                      value: tipoSeleccionado,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'amarilla',
                          child: Text('Amarilla'),
                        ),
                        DropdownMenuItem(
                          value: 'roja',
                          child: Text('Roja'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) return;
                        actualizarModal(() {
                          tipoSeleccionado = valor;
                        });
                      },
                    ),
                  ],

                  const Text('Jugador'),
                  DropdownButton<int>(
                    value: numeroSeleccionado,
                    isExpanded: true,
                    hint: const Text(
                      'Selecciona un jugador',
                    ),
                    items: plantilla.map((jugador) {
                      final numero = int.parse(
                        jugador['numero'].toString(),
                      );

                      return DropdownMenuItem<int>(
                        value: numero,
                        child: Text(
                          '#$numero - ${jugador['nombre']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      actualizarModal(() {
                        numeroSeleccionado = valor;
                        error = null;
                      });
                    },
                  ),

                  const SizedBox(height: 12),
                  const Text('Periodo'),
                  DropdownButton<String>(
                    value: periodo,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Primer medio',
                        child: Text('Primer medio'),
                      ),
                      DropdownMenuItem(
                        value: 'Segundo medio',
                        child: Text('Segundo medio'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor == null) return;
                      actualizarModal(() {
                        periodo = valor;
                      });
                    },
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: minuto,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minuto',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  if (tipoSeleccionado == 'amarilla' ||
                      tipoSeleccionado == 'roja') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: causa,
                      decoration: const InputDecoration(
                        labelText: 'Causa de la tarjeta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'GUARDAR REGISTRO',
                    ),
                    onPressed: () {
                      final valorMinuto = int.tryParse(
                        minuto.text.trim(),
                      );

                      if (numeroSeleccionado == null ||
                          valorMinuto == null ||
                          valorMinuto < 0) {
                        actualizarModal(() {
                          error =
                          'Selecciona jugador y '
                              'escribe un minuto válido.';
                        });
                        return;
                      }

                      if ((tipoSeleccionado == 'amarilla' ||
                          tipoSeleccionado == 'roja') &&
                          causa.text.trim().isEmpty) {
                        actualizarModal(() {
                          error =
                          'Indica la causa de la tarjeta.';
                        });
                        return;
                      }

                      final coincidencias = plantilla.where(
                            (jugador) =>
                        int.tryParse(
                          jugador['numero'].toString(),
                        ) ==
                            numeroSeleccionado,
                      );

                      if (coincidencias.isEmpty) {
                        return;
                      }

                      final jugador = coincidencias.first;

                      Navigator.pop(modal, {
                        'tipo': tipoSeleccionado,
                        'lado': lado,
                        'equipoId':
                        equipo(lado)?['id'].toString(),
                        'numero': numeroSeleccionado,
                        'jugador':
                        jugador['nombre'].toString(),
                        'periodo': periodo,
                        'minuto': valorMinuto,
                        'causa':
                        tipoSeleccionado == 'amarilla' ||
                            tipoSeleccionado == 'roja'
                            ? causa.text.trim()
                            : '',
                      });
                    },
                  ),

                  if (existente != null)
                    TextButton.icon(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'ELIMINAR ESTE REGISTRO',
                      ),
                      onPressed: () {
                        Navigator.pop(modal, {
                          '_eliminar': true,
                        });
                      },
                    ),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(modal);
                    },
                    child: const Text('CANCELAR'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (!mounted || respuesta == null) {
      minuto.dispose();
      causa.dispose();
      return;
    }

    final actualizados = widget.eventos
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();

    final indice = existente == null
        ? -1
        : widget.eventos.indexOf(existente);

    if (respuesta['_eliminar'] == true) {
      if (indice >= 0) {
        actualizados.removeAt(indice);
      }
    } else if (indice >= 0) {
      actualizados[indice] = respuesta;
    } else {
      actualizados.add(respuesta);
    }

    widget.onEventosActualizados(actualizados);

    minuto.dispose();
    causa.dispose();
  }

  String periodoCorto(dynamic valor) {
    if (valor == 'Primer medio') return '1';
    if (valor == 'Segundo medio') return '2';
    return valor?.toString() ?? '';
  }

  // =========================================
  // CELDAS TACTILES
  // =========================================

  Widget celda(
      String texto, {
        bool negrita = false,
        TextAlign alineacion = TextAlign.center,
        VoidCallback? tocar,
      }) {
    return InkWell(
      onTap: tocar,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 24,
        ),
        alignment: Alignment.center,
        color: tocar == null
            ? null
            : const Color(0xFFEAF7EE),
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 4,
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
      ),
    );
  }

  Widget encabezadoDato(
      String etiqueta,
      String clave,
      ) {
    return Expanded(
      child: InkWell(
        onTap: () => editarCampo(clave, etiqueta),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F3),
            border: Border.all(
              color: Colors.black87,
            ),
          ),
          child: Column(
            children: [
              Text(
                etiqueta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Divider(
                height: 8,
                color: Colors.black54,
              ),
              Text(
                dato(clave).isEmpty
                    ? 'TOCAR'
                    : dato(clave),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tituloTabla(
      String texto, {
        VoidCallback? tocar,
      }) {
    return InkWell(
      onTap: tocar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: tocar == null
              ? Colors.white
              : const Color(0xFFEAF7EE),
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
      ),
    );
  }

  Widget encabezado() {
    return Column(
      children: [
        const Text(
          'ACTA DE JUEGO FÚTBOL 7',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'CÉDULA DIGITAL INTERACTIVA',
          style: TextStyle(
            fontSize: 10,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            encabezadoDato('CIUDAD', 'ciudad'),
            encabezadoDato('TORNEO', 'torneo'),
            encabezadoDato('RAMA', 'rama'),
            encabezadoDato('CATEGORÍA', 'categoria'),
          ],
        ),
        Row(
          children: [
            encabezadoDato('CANCHA', 'cancha'),
            encabezadoDato('FECHA', 'fecha'),
            encabezadoDato('HORA', 'hora'),
            encabezadoDato('JORNADA', 'jornada'),
          ],
        ),
        Row(
          children: [
            encabezadoDato('ÁRBITRO', 'arbitro'),
          ],
        ),
      ],
    );
  }

  // =========================================
  // 20 JUGADORES POR EQUIPO
  // =========================================

  Widget tablaJugadores(String lado) {
    final plantilla = jugadores(lado);

    return Column(
      children: [
        tituloTabla(
          '${lado.toUpperCase()}: '
              '${equipo(lado)?['nombre'] ?? 'SIN SELECCIONAR'}',
          tocar: widget.onEditarEquipos,
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
                    i < plantilla.length
                        ? '${plantilla[i]['numero']}'
                        : '',
                  ),
                  celda(
                    i < plantilla.length
                        ? '${plantilla[i]['nombre']}'
                        : '',
                    alineacion: TextAlign.left,
                    tocar: i < plantilla.length
                        ? () => editarEvento(
                      lado,
                      'gol',
                      numeroInicial: int.tryParse(
                        '${plantilla[i]['numero']}',
                      ),
                    )
                        : null,
                  ),
                  for (final tipo in [
                    'gol',
                    'amarilla',
                    'roja',
                    'falta',
                  ])
                    celda(
                      i < plantilla.length
                          ? '${contar(
                        lado,
                        tipo,
                        numero: int.tryParse(
                          '${plantilla[i]['numero']}',
                        ),
                      )}'
                          : '',
                      tocar: i < plantilla.length
                          ? () => editarEvento(
                        lado,
                        tipo,
                        numeroInicial: int.tryParse(
                          '${plantilla[i]['numero']}',
                        ),
                        elegirTipoTarjeta:
                        tipo == 'amarilla' ||
                            tipo == 'roja',
                      )
                          : null,
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  // =========================================
  // GOLES
  // =========================================

  Widget tablaGoles(String lado) {
    final goles = eventosDe(lado, 'gol');

    final necesarios = (goles.length + 8) ~/ 9;
    final bloques = necesarios < 2 ? 2 : necesarios;

    Widget casillaGol(
        int indice,
        String datoCelda,
        ) {
      final existe = indice < goles.length;
      final gol = existe ? goles[indice] : null;

      String texto;

      if (!existe) {
        texto = datoCelda == 'jug' ? '+' : '';
      } else if (datoCelda == 'jug') {
        texto = '${gol!['numero']}';
      } else if (datoCelda == 'periodo') {
        texto = periodoCorto(gol!['periodo']);
      } else {
        texto = '${gol!['minuto']}';
      }

      return celda(
        texto,
        tocar: () => editarEvento(
          lado,
          'gol',
          existente: gol,
        ),
      );
    }

    return Column(
      children: [
        tituloTabla(
          'GOLES - ${lado.toUpperCase()}',
          tocar: () => editarEvento(lado, 'gol'),
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
                    celda(
                      'JUG.',
                      negrita: true,
                      tocar: () =>
                          editarEvento(lado, 'gol'),
                    ),
                    for (int i = 0; i < 9; i++)
                      casillaGol(
                        bloque * 9 + i,
                        'jug',
                      ),
                  ],
                ),
                TableRow(
                  children: [
                    celda('PER.', negrita: true),
                    for (int i = 0; i < 9; i++)
                      casillaGol(
                        bloque * 9 + i,
                        'periodo',
                      ),
                  ],
                ),
                TableRow(
                  children: [
                    celda('MIN.', negrita: true),
                    for (int i = 0; i < 9; i++)
                      casillaGol(
                        bloque * 9 + i,
                        'minuto',
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // =========================================
  // FALTAS
  // =========================================

  Widget panelFaltas(String lado) {
    final faltas = eventosDe(lado, 'falta');

    final primero = faltas.where(
          (e) => e['periodo'] == 'Primer medio',
    ).length;

    final segundo = faltas.where(
          (e) => e['periodo'] == 'Segundo medio',
    ).length;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        tituloTabla(
          'FALTAS - ${lado.toUpperCase()} · TOCAR',
          tocar: () => editarEvento(lado, 'falta'),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            '1.º tiempo: $primero   '
                '2.º tiempo: $segundo   '
                'Total: ${faltas.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
            ),
          ),
        ),
        for (final falta in faltas)
          InkWell(
            onTap: () => editarEvento(
              lado,
              'falta',
              existente: falta,
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Text(
                '#${falta['numero']} · '
                    'Periodo ${periodoCorto(falta['periodo'])} · '
                    'Min. ${falta['minuto']}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =========================================
  // TARJETAS
  // =========================================

  Widget panelTarjetas(String lado) {
    final tarjetas = widget.eventos
        .where(
          (e) =>
      e['lado'] == lado &&
          (e['tipo'] == 'amarilla' ||
              e['tipo'] == 'roja'),
    )
        .toList();

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        tituloTabla(
          'TARJETAS - ${lado.toUpperCase()} · TOCAR',
          tocar: () => editarEvento(
            lado,
            'amarilla',
            elegirTipoTarjeta: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            'Amarillas: ${contar(lado, 'amarilla')}  '
                'Rojas: ${contar(lado, 'roja')}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
            ),
          ),
        ),
        for (final tarjeta in tarjetas)
          InkWell(
            onTap: () => editarEvento(
              lado,
              tarjeta['tipo'].toString(),
              existente: tarjeta,
              elegirTipoTarjeta: true,
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Text(
                '${tarjeta['tipo'] == 'amarilla' ? 'AM' : 'R'} '
                    '#${tarjeta['numero']} · '
                    'Min. ${tarjeta['minuto']} · '
                    '${tarjeta['causa']}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =========================================
  // SHOOT OUTS
  // =========================================

  Widget tablaShootouts(String lado) {
    final lista = widget.shootouts
        .where((e) => e['lado'] == lado)
        .toList();

    final aciertos = lista.where(
          (e) => e['resultado'] == 'gol',
    ).length;

    return Column(
      children: [
        tituloTabla(
          'SHOOT OUT - ${lado.toUpperCase()} · TOCAR',
          tocar: widget.onEditarShootouts,
        ),
        Table(
          border: TableBorder.all(
            color: Colors.black54,
          ),
          children: [
            TableRow(
              children: [
                celda('N.º'),
                for (int i = 1; i <= 8; i++)
                  celda('$i'),
              ],
            ),
            TableRow(
              children: [
                celda(
                  'JUG.',
                  tocar: widget.onEditarShootouts,
                ),
                for (int i = 0; i < 8; i++)
                  celda(
                    i < lista.length
                        ? '${lista[i]['numero']}'
                        : '+',
                    tocar: widget.onEditarShootouts,
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
                    tocar: widget.onEditarShootouts,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Aciertos: $aciertos de ${lista.length}',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // =========================================
  // CUERPO TECNICO
  // =========================================

  Widget cuerpoTecnico(String lado) {
    final esLocal = lado == 'local';

    final claveDt =
    esLocal ? 'dtLocal' : 'dtVisitante';

    final claveAt =
    esLocal ? 'atLocal' : 'atVisitante';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black54,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text(
              'D.T.: '
                  '${dato(claveDt).isEmpty ? 'TOCAR' : dato(claveDt)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
              ),
            ),
            onTap: () => editarCampo(
              claveDt,
              'D.T. ${esLocal ? 'local' : 'visitante'}',
            ),
          ),
          ListTile(
            dense: true,
            title: Text(
              'A.T.: '
                  '${dato(claveAt).isEmpty ? 'TOCAR' : dato(claveAt)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
              ),
            ),
            onTap: () => editarCampo(
              claveAt,
              'A.T. ${esLocal ? 'local' : 'visitante'}',
            ),
          ),
        ],
      ),
    );
  }

  Widget seccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Text(
        titulo,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
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

  Widget marcador() {
    return Row(
      children: [
        Expanded(
          child: tituloTabla(
            '${widget.equipoLocal?['nombre'] ?? 'LOCAL'}',
            tocar: widget.onEditarEquipos,
          ),
        ),
        Container(
          width: 95,
          margin: const EdgeInsets.symmetric(
            horizontal: 6,
          ),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black87,
            ),
          ),
          child: Text(
            '${contar('local', 'gol')} - '
                '${contar('visitante', 'gol')}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: tituloTabla(
            '${widget.equipoVisitante?['nombre'] ?? 'VISITANTE'}',
            tocar: widget.onEditarEquipos,
          ),
        ),
      ],
    );
  }

  Widget observaciones() {
    return InkWell(
      onTap: () => editarCampo(
        'observaciones',
        'Observaciones',
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 85,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F3),
          border: Border.all(
            color: Colors.black87,
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'OBSERVACIONES · TOCAR PARA ESCRIBIR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dato('observaciones'),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // HOJA VERTICAL COMPLETA
  // =========================================

  Widget hoja(double ancho) {
    return Container(
      width: ancho,
      constraints: BoxConstraints(
        minHeight: ancho * 1.41,
      ),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(18),
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
            encabezado(),

            const SizedBox(height: 12),

            marcador(),

            const SizedBox(height: 10),

            dosColumnas(
              tablaJugadores('local'),
              tablaJugadores('visitante'),
            ),

            const SizedBox(height: 10),

            dosColumnas(
              cuerpoTecnico('local'),
              cuerpoTecnico('visitante'),
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

            const SizedBox(height: 16),

            observaciones(),

            const SizedBox(height: 14),

            panelFirmas(),

            const SizedBox(height: 12),

            const Text(
              'CÉDULA INTERACTIVA EN DESARROLLO',
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, espacio) {
        final anchoHoja =
        (espacio.maxWidth - 24)
            .clamp(720.0, 850.0)
            .toDouble();

        final anchoContenedor =
        espacio.maxWidth > anchoHoja + 16
            ? espacio.maxWidth
            : anchoHoja + 16;

        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: anchoContenedor,
              child: Center(
                child: hoja(anchoHoja),
              ),
            ),
          ),
        );
      },
    );
  }
}
