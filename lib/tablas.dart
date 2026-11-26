import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';
import 'motor_tablas.dart';
import 'almacen_tablas.dart';

// ==============================================
// MÓDULO TABLAS
// ARENA MOUSTACHE
// ==============================================

class Tablas extends StatefulWidget {
  const Tablas({super.key});

  @override
  State<Tablas> createState() => _TablasState();
}

class _TablasState extends State<Tablas> {
  final SharedPreferencesAsync prefs =
  SharedPreferencesAsync();

  List<Map<String, dynamic>> registros = [];

  String? torneoSeleccionado;
  String? categoriaSeleccionada;

  bool cargando = true;
  String? error;

  // ==============================================
  // INICIALIZACIÓN
  // ==============================================

  @override
  void initState() {
    super.initState();
    cargarCategorias();
  }

  String normalizar(dynamic valor) {
    return MotorTablas.normalizar(
      MotorTablas.texto(valor),
    );
  }

  List<Map<String, dynamic>> convertirLista(
      String? texto,
      ) {
    final datos = jsonDecode(texto ?? '[]');

    if (datos is! List) {
      throw const FormatException(
        'Formato de almacenamiento inválido.',
      );
    }

    return datos
        .map(
          (item) => Map<String, dynamic>.from(
        item as Map,
      ),
    )
        .toList();
  }

  // ==============================================
  // CARGAR TORNEOS Y CATEGORÍAS
  // ==============================================

  Future<void> cargarCategorias() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final texto = await prefs.getString(
        'torneos_categorias',
      );

      final lista = convertirLista(texto);

      if (!mounted) return;

      setState(() {
        registros = lista;
        torneoSeleccionado = null;
        categoriaSeleccionada = null;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error =
        'No se pudieron cargar los torneos: $e';
      });
    }
  }

  // ==============================================
  // TORNEOS DISPONIBLES
  // ==============================================

  List<String> get torneos {
    final unicos = <String, String>{};

    for (final registro in registros) {
      final nombre = MotorTablas.texto(
        registro['torneo'],
      );

      if (nombre.isNotEmpty) {
        unicos.putIfAbsent(
          normalizar(nombre),
              () => nombre,
        );
      }
    }

    final resultado = unicos.values.toList();

    resultado.sort(
          (a, b) => normalizar(a).compareTo(
        normalizar(b),
      ),
    );

    return resultado;
  }

  // ==============================================
  // CATEGORÍAS DEL TORNEO SELECCIONADO
  // ==============================================

  List<String> get categorias {
    if (torneoSeleccionado == null) {
      return [];
    }

    final unicas = <String, String>{};

    for (final registro in registros) {
      if (normalizar(registro['torneo']) !=
          normalizar(torneoSeleccionado)) {
        continue;
      }

      final categoria = MotorTablas.texto(
        registro['categoria'],
      );

      if (categoria.isNotEmpty) {
        unicas.putIfAbsent(
          normalizar(categoria),
              () => categoria,
        );
      }
    }

    final resultado = unicas.values.toList();

    resultado.sort(
          (a, b) => normalizar(a).compareTo(
        normalizar(b),
      ),
    );

    return resultado;
  }

  // ==============================================
  // ABRIR TABLA GENERAL
  // ==============================================

  Future<void> abrirTabla() async {
    final torneo = torneoSeleccionado;
    final categoria = categoriaSeleccionada;

    if (torneo == null || categoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona el torneo y la categoría.',
          ),
        ),
      );

      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TablaGeneral(
          torneo: torneo,
          categoria: categoria,
        ),
      ),
    );
  }

  // ==============================================
  // DISEÑO DE LOS SELECTORES
  // ==============================================

  Widget selector({
    required String titulo,
    required String indicacion,
    required IconData icono,
    required String? valor,
    required List<String> opciones,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1,
            color: ArenaColores.negro,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ArenaColores.dorado,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icono,
                color: ArenaColores.rojo,
                size: 23,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: valor,
                    isExpanded: true,
                    hint: Text(
                      indicacion,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    items: opciones.map((opcion) {
                      return DropdownMenuItem<String>(
                        value: opcion,
                        child: Text(
                          opcion.toUpperCase(),
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ArenaColores.negro,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================
  // BOTÓN METÁLICO
  // ==============================================

  Widget botonAceptar() {
    final habilitado =
        torneoSeleccionado != null &&
            categoriaSeleccionada != null;

    return SizedBox(
      width: double.infinity,
      height: 53,
      child: ElevatedButton.icon(
        onPressed: habilitado ? abrirTabla : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ArenaColores.negro,
          foregroundColor: ArenaColores.dorado,
          disabledBackgroundColor:
          const Color(0xFF77706B),
          disabledForegroundColor: Colors.white54,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: ArenaColores.dorado,
              width: 1.5,
            ),
          ),
        ),
        icon: const Icon(
          Icons.check_circle_outline,
          size: 25,
        ),
        label: const Text(
          'ACEPTAR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ==============================================
  // FORMULARIO DE FILTROS
  // ==============================================

  Widget formulario() {
    return ArenaPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          const Text(
            'TORNEO Y CATEGORÍA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: ArenaColores.negro,
            ),
          ),

          const SizedBox(height: 8),

          const Divider(
            color: ArenaColores.dorado,
          ),

          const SizedBox(height: 16),

          selector(
            titulo: 'TORNEO',
            indicacion: 'Selecciona un torneo',
            icono: Icons.emoji_events,
            valor: torneoSeleccionado,
            opciones: torneos,
            onChanged: (valor) {
              setState(() {
                torneoSeleccionado = valor;
                categoriaSeleccionada = null;
              });
            },
          ),

          const SizedBox(height: 22),

          selector(
            titulo: 'CATEGORÍA',
            indicacion: 'Selecciona una categoría',
            icono: Icons.category,
            valor: categoriaSeleccionada,
            opciones: categorias,
            onChanged: torneoSeleccionado == null
                ? null
                : (valor) {
              setState(() {
                categoriaSeleccionada = valor;
              });
            },
          ),

          const SizedBox(height: 28),

          botonAceptar(),
        ],
      ),
    );
  }

  // ==============================================
  // CONTENIDO PRINCIPAL
  // ==============================================

  Widget contenido() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: ArenaColores.dorado,
        ),
      );
    }

    if (error != null || torneos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ArenaPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 52,
                  color: ArenaColores.rojo,
                ),

                const SizedBox(height: 16),

                Text(
                  error ??
                      'No hay torneos registrados.\n'
                          'Registra un torneo y una categoría.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: cargarCategorias,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ACTUALIZAR'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 650,
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/ui/logo_arena.png',
                width: 145,
                height: 145,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 18),

              const ArenaTextoMetalico(
                texto: 'TABLA DE POSICIONES',
                tamano: 27,
                dorado: true,
              ),

              const SizedBox(height: 12),

              const Text(
                'Selecciona el torneo y la categoría '
                    'que deseas consultar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              formulario(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'TABLAS',
      ),
      body: ArenaFondo(
        child: contenido(),
      ),
    );
  }
}

// ==============================================
// PANTALLA DE CLASIFICACIÓN GENERAL
// ==============================================

class TablaGeneral extends StatefulWidget {
  final String torneo;
  final String categoria;

  const TablaGeneral({
    super.key,
    required this.torneo,
    required this.categoria,
  });

  @override
  State<TablaGeneral> createState() =>
      _TablaGeneralState();
}

class _TablaGeneralState
    extends State<TablaGeneral> {
  List<FilaTabla> filas = [];

  bool cargando = true;
  String? error;

  int omitidas = 0;

  static const Color dorado =
  Color(0xFFE8BD62);

  @override
  void initState() {
    super.initState();
    cargarTabla();
  }

  // ==============================================
  // CONSULTA DE RESULTADOS OFICIALES
  // ==============================================

  Future<void> cargarTabla() async {
    if (!mounted) return;
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final resultado = await AlmacenTablas.cargarTabla(
        torneo: widget.torneo,
        categoria: widget.categoria,
      );
      final incidencias = await AlmacenTablas.cargarIncidenciasMigracion();
      if (!mounted) return;
      setState(() {
        filas = resultado;
        omitidas = incidencias.length;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cargando = false;
        error = 'No se pudo cargar la tabla: $e';
      });
    }
  }

  // ==============================================
  // ENCABEZADO CON LOS DOS LOGOTIPOS
  // ==============================================

  Widget encabezado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: dorado, width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B1416), Color(0xFF100D10)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Image.asset(
              'assets/ui/logo_arena.png',
              height: 92,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 4,
            child: Column(
              children: [
                Text(
                  'CLASIFICACIÓN GENERAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: dorado,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ARENA MOUSTACHE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Image.asset(
              'assets/ui/logo_arbitros.png',
              height: 92,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================
  // ENCABEZADO INTEGRADO A LA TABLA
  // ==============================================

  Widget tituloTabla() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF750F15), Color(0xFF29090E)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TORNEO',
                  style: TextStyle(
                    color: dorado,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.torneo.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${filas.length} EQUIPOS REGISTRADOS',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF190C10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB18B45)),
              ),
              child: Column(
                children: [
                  const Text(
                    'CATEGORÍA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dorado,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.categoria.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================
  // COLUMNAS PROPORCIONALES
  // ==============================================

  Widget celda(
      String texto, {
        int flex = 8,
        Color color = Colors.white,
        bool negrita = false,
        bool izquierda = false,
      }) {
    return Expanded(
      flex: flex,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        alignment: izquierda ? Alignment.centerLeft : Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(
          texto,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: izquierda ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: negrita ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget encabezadoColumnas() {
    return Container(
      color: const Color(0xFF101012),
      child: Row(
        children: [
          celda('POS', color: dorado, negrita: true),
          celda('EQUIPO', flex: 31, color: dorado, negrita: true, izquierda: true),
          for (final titulo in ['PJ', 'PG', 'PE', 'PP', 'GF', 'GC', 'DG', 'PTS'])
            celda(titulo, flex: titulo == 'PTS' ? 10 : 8, color: dorado, negrita: true),
        ],
      ),
    );
  }

  Widget filaEquipo(FilaTabla fila) {
    final clasificado = fila.clasificado;
    final fondo = fila.posicion.isEven
        ? const Color(0xFF202126)
        : const Color(0xFF18191D);
    final diferencia = fila.diferenciaGoles > 0
        ? '+${fila.diferenciaGoles}'
        : '${fila.diferenciaGoles}';

    return Container(
      decoration: BoxDecoration(
        color: clasificado ? null : fondo,
        gradient: clasificado
            ? const LinearGradient(
          colors: [Color(0xFF393022), Color(0xFF252226), Color(0xFF18191D)],
          stops: [0, 0.3, 1],
        )
            : null,
        border: Border(
          bottom: BorderSide(color: dorado.withValues(alpha: 0.20)),
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 8,
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: clasificado
                          ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFF2C0), Color(0xFFE1B85C), Color(0xFFA97B2E)],
                      )
                          : null,
                      color: clasificado ? null : const Color(0xFF36383E),
                    ),
                    child: Text(
                      '${fila.posicion}',
                      style: TextStyle(
                        color: clasificado ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              celda(
                fila.nombre.toUpperCase(),
                flex: 31,
                negrita: true,
                izquierda: true,
                color: clasificado ? const Color(0xFFF0E5CA) : Colors.white,
              ),
              celda('${fila.jugados}'),
              celda('${fila.ganados}'),
              celda('${fila.empatados}'),
              celda('${fila.perdidos}'),
              celda('${fila.golesFavor}'),
              celda('${fila.golesContra}'),
              celda(diferencia),
              Expanded(
                flex: 10,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171519),
                      border: Border.all(
                        color: clasificado ? dorado : const Color(0xFF505158),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${fila.puntos}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: clasificado ? const Color(0xFFF4CE7A) : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (clasificado)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 4,
                child: ColoredBox(color: dorado),
              ),
            ),
        ],
      ),
    );
  }

  // ==============================================
  // TABLA RESPONSIVA SIN ESPACIO VACÍO
  // ==============================================

  Widget tablaPosiciones() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151417),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dorado, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tituloTabla(),
          if (filas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(Icons.groups_outlined, color: dorado, size: 50),
                  SizedBox(height: 12),
                  Text(
                    'No hay equipos registrados en esta categoría.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, espacio) {
                final ancho = espacio.maxWidth < 760 ? 760.0 : espacio.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: ancho,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        encabezadoColumnas(),
                        for (final fila in filas) filaEquipo(fila),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==============================================
  // LEYENDA DE CLASIFICACIÓN
  // ==============================================

  Widget leyenda() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xF218191D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dorado.withValues(alpha: 0.5),
        ),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: dorado,
                size: 24,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'ZONA DE CLASIFICACIÓN: '
                      'PRIMEROS 4 LUGARES',
                  style: TextStyle(
                    color: dorado,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            'PJ: Jugados · PG: Ganados · '
                'PE: Empatados · PP: Perdidos\n'
                'GF: Goles a favor · GC: Goles en contra\n'
                'DG: Diferencia de goles · PTS: Puntos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================
  // SISTEMA DE PUNTUACIÓN
  // ==============================================

  Widget sistemaPuntos() {
    return ArenaPanel(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SISTEMA DE PUNTUACIÓN',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ArenaColores.negro,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          const Divider(
            color: ArenaColores.dorado,
          ),

          regla('Victoria en tiempo regular', '3'),
          regla('Victoria por shootouts', '2'),
          regla('Derrota por shootouts', '1'),
          regla('Derrota en tiempo regular', '0'),
        ],
      ),
    );
  }

  Widget regla(String texto, String puntos) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: ArenaColores.negro,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            '$puntos PTS',
            style: const TextStyle(
              color: ArenaColores.rojo,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================
  // CONTENIDO GENERAL
  // ==============================================

  Widget contenido() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: dorado,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ArenaPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error!,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 15),

                ElevatedButton.icon(
                  onPressed: cargarTabla,
                  icon: const Icon(Icons.refresh),
                  label: const Text('REINTENTAR'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              encabezado(),

              const SizedBox(height: 20),

              tablaPosiciones(),

              const SizedBox(height: 10),

              const Text(
                'RESULTADOS OFICIALES · REGISTRO LOCAL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dorado,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),

              if (omitidas > 0) ...[
                const SizedBox(height: 12),

                ArenaPanel(
                  child: Text(
                    '$omitidas incidencia(s) en la migración histórica '
                        '(todos los torneos). Los registros inválidos o '
                        'duplicados no suman puntos.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ArenaColores.rojo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              leyenda(),

              const SizedBox(height: 18),

              sistemaPuntos(),

              const SizedBox(height: 20),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: cargarTabla,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArenaColores.negro,
                    foregroundColor: dorado,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      side: const BorderSide(
                        color: dorado,
                        width: 1.5,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'ACTUALIZAR TABLA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dorado,
                    backgroundColor:
                    const Color(0xFF211416),
                    side: const BorderSide(
                      color: dorado,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text(
                    'CAMBIAR TORNEO O CATEGORÍA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'CLASIFICACIÓN GENERAL',
      ),
      body: ArenaFondo(
        child: contenido(),
      ),
    );
  }
}
