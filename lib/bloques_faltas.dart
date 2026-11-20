
import 'package:material_ui/material_ui.dart';
import 'arena_estilo.dart';

class BloquesFaltas extends StatefulWidget {
  final Map<String, dynamic>? equipoLocal;
  final Map<String, dynamic>? equipoVisitante;

  final List<Map<String, dynamic>> faltas;
  final List<Map<String, dynamic>> marcasVisuales;

  final ValueChanged<List<Map<String, dynamic>>>
  onFaltasActualizadas;

  final ValueChanged<List<Map<String, dynamic>>>
  onMarcasActualizadas;

  final bool soloLectura;

  const BloquesFaltas({
    super.key,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.faltas,
    required this.marcasVisuales,
    required this.onFaltasActualizadas,
    required this.onMarcasActualizadas,
    this.soloLectura = false,
  });

  @override
  State<BloquesFaltas> createState() =>
      _BloquesFaltasState();
}

class _CambioFalta {
  final int? numero;
  final bool eliminar;

  const _CambioFalta.guardar(this.numero)
      : eliminar = false;

  const _CambioFalta.eliminar()
      : numero = null,
        eliminar = true;
}

class _BloquesFaltasState extends State<BloquesFaltas> {
  static const int casillasPorBloque = 6;

  static const String imagenAlerta =
      'assets/alertas/sexta_falta.png';

  Map<String, dynamic>? equipo(String lado) {
    return lado == 'local'
        ? widget.equipoLocal
        : widget.equipoVisitante;
  }

  List<Map<String, dynamic>> jugadores(String lado) {
    final datos = equipo(lado)?['jugadores'];

    if (datos is! List) return [];

    return datos
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  Map<String, dynamic>? buscarFalta(
      String lado,
      int bloque,
      int casilla,
      ) {
    for (final item in widget.faltas) {
      if (item['lado'] == lado &&
          item['bloque'] == bloque &&
          item['casilla'] == casilla) {
        return item;
      }
    }

    return null;
  }

  bool tieneMarca(
      String lado,
      int bloque,
      String columna,
      ) {
    return widget.marcasVisuales.any(
          (item) =>
      item['lado'] == lado &&
          item['bloque'] == bloque &&
          item['columna'] == columna,
    );
  }

  // =========================================
  // CONTAR CASILLAS LLENAS DE UN BLOQUE
  // =========================================

  int contarFaltasBloque(
      List<Map<String, dynamic>> lista,
      String lado,
      int bloque,
      ) {
    return lista.where((item) {
      if (item['lado'] != lado ||
          item['bloque'] != bloque) {
        return false;
      }

      final casilla = item['casilla'];

      if (casilla is! int ||
          casilla < 1 ||
          casilla > casillasPorBloque) {
        return false;
      }

      return item['numero'] != null &&
          item['numero'].toString().isNotEmpty;
    }).map((item) {
      return item['casilla'];
    }).toSet().length;
  }

  // =========================================
  // ALERTA PERSONALIZADA DE SEXTA FALTA
  // ESTILO ARENA MOUSTACHE
  // SOLO IMAGEN Y BOTÓN ACEPTAR
  // =========================================

  Future<void> mostrarAlertaSextaFalta() async {
    if (!mounted || widget.soloLectura) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogo) {
        final alturaPantalla =
            MediaQuery.sizeOf(dialogo).height;

        return Dialog(
          backgroundColor: ArenaColores.negro,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(
              color: ArenaColores.dorado,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Marco rojo alrededor de la imagen.
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ArenaColores.rojo,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: alturaPantalla * 0.65,
                      ),
                      child: Image.asset(
                        imagenAlerta,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Botón negro con borde dorado.
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogo);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF2D1B1D),
                        foregroundColor: ArenaColores.dorado,
                        elevation: 4,
                        shadowColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            color: ArenaColores.dorado,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text(
                        'ACEPTAR',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================
  // MARCAS VISUALES DE SHOOT OUT
  // =========================================

  void alternarMarca(
      String lado,
      int bloque,
      String columna,
      ) {
    if (widget.soloLectura) return;

    final nuevas = widget.marcasVisuales
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();

    if (tieneMarca(lado, bloque, columna)) {
      nuevas.removeWhere(
            (item) =>
        item['lado'] == lado &&
            item['bloque'] == bloque &&
            item['columna'] == columna,
      );
    } else {
      nuevas.add({
        'lado': lado,
        'bloque': bloque,
        'columna': columna,
      });
    }

    // Estas X son únicamente visuales.
    // No modifican goles ni shoot outs reales.
    widget.onMarcasActualizadas(nuevas);
  }

  // =========================================
  // REGISTRO MANUAL DE FALTAS
  // =========================================

  Future<void> editarFalta(
      String lado,
      int bloque,
      int casilla,
      ) async {
    if (widget.soloLectura) return;

    final anterior = buscarFalta(
      lado,
      bloque,
      casilla,
    );

    final controlador = TextEditingController(
      text: anterior?['numero']?.toString() ?? '',
    );

    final plantilla = jugadores(lado);

    final resultado = await showDialog<_CambioFalta>(
      context: context,
      builder: (dialogo) {
        return AlertDialog(
          title: Text(
            'Falta $casilla · Bloque $bloque',
          ),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  Text(
                    lado == 'local'
                        ? 'EQUIPO LOCAL'
                        : 'EQUIPO VISITANTE',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Seleccionar jugador registrado',
                  ),

                  const SizedBox(height: 6),

                  if (plantilla.isNotEmpty)
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Elegir jugador'),
                      items: plantilla.map((jugador) {
                        final numero = int.tryParse(
                          '${jugador['numero']}',
                        );

                        if (numero == null) {
                          return null;
                        }

                        return DropdownMenuItem<int>(
                          value: numero,
                          child: Text(
                            '#$numero - ${jugador['nombre']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).whereType<
                          DropdownMenuItem<int>>().toList(),
                      onChanged: (numero) {
                        if (numero != null) {
                          controlador.text =
                              numero.toString();
                        }
                      },
                    )
                  else
                    const Text(
                      'No hay jugadores registrados.',
                    ),

                  const SizedBox(height: 20),

                  const Text(
                    'O escribir número manualmente',
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: controlador,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número de camiseta',
                      hintText: 'Ejemplo: 10',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Puedes escribir un número aunque '
                        'no esté registrado en la plantilla.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (anterior != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogo,
                    const _CambioFalta.eliminar(),
                  );
                },
                child: const Text(
                  'BORRAR FALTA',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogo);
              },
              child: const Text('CANCELAR'),
            ),

            ElevatedButton(
              onPressed: () {
                final numero = int.tryParse(
                  controlador.text.trim(),
                );

                if (numero == null || numero <= 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Escribe un número válido.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogo,
                  _CambioFalta.guardar(numero),
                );
              },
              child: const Text('GUARDAR'),
            ),
          ],
        );
      },
    );

    controlador.dispose();

    if (!mounted || resultado == null) return;

    // Contar las faltas antes de modificar.
    final faltasAntes = contarFaltasBloque(
      widget.faltas,
      lado,
      bloque,
    );

    final nuevas = widget.faltas
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();

    // Evita duplicar una misma casilla.
    nuevas.removeWhere(
          (item) =>
      item['lado'] == lado &&
          item['bloque'] == bloque &&
          item['casilla'] == casilla,
    );

    if (!resultado.eliminar) {
      nuevas.add({
        'lado': lado,
        'bloque': bloque,
        'casilla': casilla,
        'numero': resultado.numero,
      });
    }

    // Contar las faltas después de modificar.
    final faltasDespues = contarFaltasBloque(
      nuevas,
      lado,
      bloque,
    );

    // Primero actualizamos los datos.
    widget.onFaltasActualizadas(nuevas);

    // Mostrar la alerta solamente cuando
    // el bloque pasa de incompleto a completo.
    if (faltasAntes < casillasPorBloque &&
        faltasDespues == casillasPorBloque) {
      await mostrarAlertaSextaFalta();
    }
  }

  // =========================================
  // DISEÑO DE LAS CELDAS
  // =========================================

  Widget textoCelda(
      String valor, {
        bool encabezado = false,
        VoidCallback? tocar,
      }) {
    return InkWell(
      onTap: widget.soloLectura ? null : tocar,
      child: Container(
        height: 25,
        alignment: Alignment.center,
        color: tocar == null || widget.soloLectura
            ? Colors.white
            : const Color(0xFFF0F7F1),
        padding: const EdgeInsets.symmetric(
          horizontal: 1,
        ),
        child: Text(
          valor,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black,
            fontSize: encabezado ? 8 : 10,
            fontWeight: encabezado
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // =========================================
  // DISEÑO DE CADA BLOQUE
  // =========================================

  Widget bloque(
      String lado,
      int numeroBloque,
      ) {
    final nombres = [
      'Gol',
      'Falló',
      'Jug.',
    ];

    final claves = [
      'gol',
      'fallo',
      'jug',
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black87,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.black87,
                      ),
                      bottom: BorderSide(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  child: const Text(
                    'FALTAS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Container(
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Shoot Out',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Table(
            border: TableBorder.all(
              color: Colors.black54,
              width: 0.65,
            ),
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
              5: FlexColumnWidth(),
              6: FlexColumnWidth(),
              7: FlexColumnWidth(),
              8: FlexColumnWidth(),
            },
            children: [
              TableRow(
                children: [
                  for (int i = 1;
                  i <= casillasPorBloque;
                  i++)
                    textoCelda(
                      '$i',
                      encabezado: true,
                    ),

                  for (final nombre in nombres)
                    textoCelda(
                      nombre,
                      encabezado: true,
                    ),
                ],
              ),

              TableRow(
                children: [
                  for (int casilla = 1;
                  casilla <= casillasPorBloque;
                  casilla++)
                    textoCelda(
                      buscarFalta(
                        lado,
                        numeroBloque,
                        casilla,
                      )?['numero']
                          ?.toString() ??
                          '',
                      tocar: () => editarFalta(
                        lado,
                        numeroBloque,
                        casilla,
                      ),
                    ),

                  for (final columna in claves)
                    textoCelda(
                      tieneMarca(
                        lado,
                        numeroBloque,
                        columna,
                      )
                          ? 'X'
                          : '',
                      tocar: () => alternarMarca(
                        lado,
                        numeroBloque,
                        columna,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================
  // DOS BLOQUES POR FILA
  // =========================================

  Widget filaDeDosBloques(
      String lado,
      int primerBloque,
      int segundoBloque,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          child: bloque(lado, primerBloque),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: bloque(lado, segundoBloque),
        ),
      ],
    );
  }

  // =========================================
  // CUATRO BLOQUES POR EQUIPO (2 X 2)
  // =========================================

  Widget filaEquipo(String lado) {
    final nombre = equipo(lado)?['nombre']
        ?.toString() ??
        (lado == 'local' ? 'LOCAL' : 'VISITANTE');

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 7,
          ),
          child: Text(
            '${lado.toUpperCase()} — $nombre',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // Bloques 1 y 2 arriba.
        filaDeDosBloques(lado, 1, 2),

        const SizedBox(height: 8),

        // Bloques 3 y 4 abajo.
        filaDeDosBloques(lado, 3, 4),
      ],
    );
  }

  // =========================================
  // LOCAL IZQUIERDA, VISITANTE DERECHA
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          child: filaEquipo('local'),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: filaEquipo('visitante'),
        ),
      ],
    );
  }
}
