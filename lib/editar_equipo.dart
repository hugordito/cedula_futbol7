
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';

// ==========================================
// EDITAR EQUIPO - ARENA MOUSTACHE
// FILTROS Y MODIFICACIÓN DE CATEGORÍA
// ==========================================

const String _claveCategorias = 'torneos_categorias';
const String _sinAsignar = '__equipo_sin_asignar__';

String _normalizar(String texto) {
  return texto
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();
}

String _texto(dynamic valor) {
  return valor?.toString().trim() ?? '';
}

List<Map<String, dynamic>> _leerRegistros(String? datos) {
  return (jsonDecode(datos ?? '[]') as List)
      .map(
        (item) => Map<String, dynamic>.from(
      item as Map,
    ),
  )
      .toList();
}

bool _tieneClasificacion(Map<String, dynamic> equipo) {
  return _texto(equipo['torneo']).isNotEmpty &&
      _texto(equipo['categoria']).isNotEmpty;
}

// ==========================================
// OBTENER TORNEOS REGISTRADOS
// ==========================================

List<String> _obtenerTorneos(
    List<Map<String, dynamic>> categorias,
    List<Map<String, dynamic>> equipos,
    ) {
  final unicos = <String, String>{};

  for (final registro in categorias) {
    final torneo = _texto(registro['torneo']);

    if (torneo.isNotEmpty) {
      unicos.putIfAbsent(
        _normalizar(torneo),
            () => torneo,
      );
    }
  }

  for (final equipo in equipos) {
    if (!_tieneClasificacion(equipo)) continue;

    final torneo = _texto(equipo['torneo']);

    unicos.putIfAbsent(
      _normalizar(torneo),
          () => torneo,
    );
  }

  final lista = unicos.values.toList()
    ..sort(
          (a, b) => _normalizar(a).compareTo(
        _normalizar(b),
      ),
    );

  if (equipos.any(
        (equipo) => !_tieneClasificacion(equipo),
  )) {
    lista.add(_sinAsignar);
  }

  return lista;
}

// ==========================================
// OBTENER CATEGORÍAS SEGÚN TORNEO
// ==========================================

List<String> _obtenerCategorias(
    String? torneo,
    List<Map<String, dynamic>> categorias,
    List<Map<String, dynamic>> equipos,
    ) {
  if (torneo == null) return [];

  if (torneo == _sinAsignar) {
    return [_sinAsignar];
  }

  final unicas = <String, String>{};

  for (final registro in categorias) {
    if (_normalizar(_texto(registro['torneo'])) !=
        _normalizar(torneo)) {
      continue;
    }

    final categoria = _texto(registro['categoria']);

    if (categoria.isNotEmpty) {
      unicas.putIfAbsent(
        _normalizar(categoria),
            () => categoria,
      );
    }
  }

  for (final equipo in equipos) {
    if (!_tieneClasificacion(equipo)) continue;

    if (_normalizar(_texto(equipo['torneo'])) !=
        _normalizar(torneo)) {
      continue;
    }

    final categoria = _texto(equipo['categoria']);

    unicas.putIfAbsent(
      _normalizar(categoria),
          () => categoria,
    );
  }

  return unicas.values.toList()
    ..sort(
          (a, b) => _normalizar(a).compareTo(
        _normalizar(b),
      ),
    );
}

// ==========================================
// DISEÑO COMPARTIDO DE SELECTORES
// ==========================================

InputDecoration _decoracionSelector({
  required String titulo,
  required IconData icono,
}) {
  return InputDecoration(
    labelText: titulo,
    floatingLabelBehavior:
    FloatingLabelBehavior.always,
    labelStyle: const TextStyle(
      color: ArenaColores.negro,
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    ),
    floatingLabelStyle: const TextStyle(
      color: ArenaColores.negro,
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    ),
    prefixIcon: Icon(
      icono,
      color: ArenaColores.rojo,
      size: 21,
    ),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 16,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFD9B48F),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: ArenaColores.rojo,
        width: 1.5,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFBDBDBD),
      ),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

Widget _selector({
  Key? key,
  required String titulo,
  required IconData icono,
  required String ayuda,
  required String? valor,
  required List<DropdownMenuItem<String>> opciones,
  required ValueChanged<String?>? onChanged,
}) {
  return DropdownButtonFormField<String>(
    key: key,
    initialValue: valor,
    isExpanded: true,
    decoration: _decoracionSelector(
      titulo: titulo,
      icono: icono,
    ),
    hint: Text(
      ayuda,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF666666),
      ),
    ),
    style: const TextStyle(
      color: ArenaColores.negro,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    items: opciones,
    onChanged: onChanged,
  );
}

String _etiqueta(String valor) {
  return valor == _sinAsignar
      ? 'SIN ASIGNAR'
      : valor;
}

// ==========================================
// PANTALLA 1 - EDITAR EQUIPO
// ==========================================

class EditarEquipo extends StatefulWidget {
  const EditarEquipo({super.key});

  @override
  State<EditarEquipo> createState() =>
      _EditarEquipoState();
}

class _EditarEquipoState extends State<EditarEquipo> {
  List<Map<String, dynamic>> equipos = [];
  List<Map<String, dynamic>> categorias = [];

  String? torneoSeleccionado;
  String? categoriaSeleccionada;

  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  // ==========================================
  // CARGAR EQUIPOS Y CATEGORÍAS
  // ==========================================

  Future<void> cargarDatos({
    bool conservarFiltros = false,
  }) async {
    if (!mounted) return;

    final torneoAnterior =
    conservarFiltros ? torneoSeleccionado : null;

    final categoriaAnterior =
    conservarFiltros ? categoriaSeleccionada : null;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final datosEquipos =
      await prefs.getString('equipos');

      final datosCategorias =
      await prefs.getString(_claveCategorias);

      final equiposCargados =
      _leerRegistros(datosEquipos);

      final categoriasCargadas =
      _leerRegistros(datosCategorias);

      if (!mounted) return;

      setState(() {
        equipos = equiposCargados;
        categorias = categoriasCargadas;

        torneoSeleccionado = torneoAnterior;
        categoriaSeleccionada = categoriaAnterior;

        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = 'No se pudieron cargar los equipos: $e';
      });
    }
  }

  // ==========================================
  // EQUIPOS FILTRADOS
  // ==========================================

  List<Map<String, dynamic>> get equiposFiltrados {
    if (torneoSeleccionado == null ||
        categoriaSeleccionada == null) {
      return [];
    }

    final lista = equipos.where((equipo) {
      if (torneoSeleccionado == _sinAsignar) {
        return !_tieneClasificacion(equipo);
      }

      return _normalizar(_texto(equipo['torneo'])) ==
          _normalizar(torneoSeleccionado!) &&
          _normalizar(_texto(equipo['categoria'])) ==
              _normalizar(categoriaSeleccionada!);
    }).toList();

    lista.sort((a, b) {
      return _normalizar(_texto(a['nombre'])).compareTo(
        _normalizar(_texto(b['nombre'])),
      );
    });

    return lista;
  }

  // ==========================================
  // ABRIR FORMULARIO DE EDICIÓN
  // ==========================================

  Future<void> abrirFormulario(
      Map<String, dynamic> equipo,
      ) async {
    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => FormularioEditarEquipo(
          equipo: equipo,
        ),
      ),
    );

    if (!mounted) return;

    if (actualizado == true) {
      await cargarDatos(conservarFiltros: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Equipo actualizado correctamente',
          ),
          backgroundColor: ArenaColores.negro,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // ENCABEZADO
  // ==========================================

  Widget crearEncabezado() {
    return Column(
      children: [
        const Icon(
          Icons.groups,
          size: 55,
          color: ArenaColores.dorado,
        ),
        const SizedBox(height: 12),
        const ArenaTextoMetalico(
          texto: 'EQUIPOS REGISTRADOS',
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
            'Selecciona un torneo, una categoría '
                'y el equipo que deseas modificar.',
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
  // SELECTORES DE LA PRIMERA PANTALLA
  // ==========================================

  Widget crearFiltros() {
    final torneos = _obtenerTorneos(
      categorias,
      equipos,
    );

    final categoriasDisponibles =
    _obtenerCategorias(
      torneoSeleccionado,
      categorias,
      equipos,
    );

    return ArenaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.filter_list,
                color: ArenaColores.rojo,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'TORNEO Y CATEGORÍA',
                  style: TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          LayoutBuilder(
            builder: (context, espacio) {
              final selectorDeTorneo = _selector(
                titulo: 'TORNEO *',
                icono: Icons.emoji_events,
                ayuda: 'Selecciona torneo',
                valor: torneoSeleccionado,
                opciones: torneos.map((torneo) {
                  return DropdownMenuItem<String>(
                    value: torneo,
                    child: Text(
                      _etiqueta(torneo),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    torneoSeleccionado = valor;
                    categoriaSeleccionada = null;
                  });
                },
              );

              final selectorDeCategoria = _selector(
                key: ValueKey(
                  'filtro_${torneoSeleccionado ?? "ninguno"}',
                ),
                titulo: 'CATEGORÍA *',
                icono: Icons.groups_rounded,
                ayuda: 'Selecciona categoría',
                valor: categoriaSeleccionada,
                opciones: categoriasDisponibles.map(
                      (categoria) {
                    return DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(
                        _etiqueta(categoria),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ).toList(),
                onChanged: torneoSeleccionado == null
                    ? null
                    : (valor) {
                  setState(() {
                    categoriaSeleccionada = valor;
                  });
                },
              );

              if (espacio.maxWidth >= 600) {
                return Row(
                  children: [
                    Expanded(child: selectorDeTorneo),
                    const SizedBox(width: 14),
                    Expanded(child: selectorDeCategoria),
                  ],
                );
              }

              return Column(
                children: [
                  selectorDeTorneo,
                  const SizedBox(height: 18),
                  selectorDeCategoria,
                ],
              );
            },
          ),
          if (equipos.any(
                (equipo) => !_tieneClasificacion(equipo),
          )) ...[
            const SizedBox(height: 13),
            const Text(
              'Los equipos antiguos sin categoría '
                  'aparecen en SIN ASIGNAR.',
              style: TextStyle(
                color: Color(0xFF655C54),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TARJETA DE EQUIPO
  // ==========================================

  Widget crearTarjetaEquipo(
      Map<String, dynamic> equipo,
      ) {
    final nombre =
    _texto(equipo['nombre']).isEmpty
        ? 'Sin nombre'
        : _texto(equipo['nombre']);

    final jugadores =
        (equipo['jugadores'] as List?) ?? [];

    final torneo = _texto(equipo['torneo']);
    final categoria = _texto(equipo['categoria']);

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE4C5A6),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 48,
          height: 48,
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
            size: 27,
          ),
        ),
        title: Text(
          nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ArenaColores.negro,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${jugadores.length} de 20 jugadores\n'
                '${torneo.isEmpty ? "Sin torneo" : torneo}'
                ' · '
                '${categoria.isEmpty ? "Sin categoría" : categoria}',
            style: const TextStyle(
              color: Color(0xFF655C54),
              fontSize: 12,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.edit,
          color: ArenaColores.rojo,
          size: 25,
        ),
        onTap: () => abrirFormulario(equipo),
      ),
    );
  }

  // ==========================================
  // LISTA DE EQUIPOS
  // ==========================================

  Widget crearListaEquipos() {
    final lista = equiposFiltrados;

    return ArenaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_open,
                color: ArenaColores.rojo,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'MIS EQUIPOS',
                  style: TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                '${lista.length}',
                style: const TextStyle(
                  color: ArenaColores.rojo,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (lista.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'No hay equipos registrados '
                    'en esta combinación.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ArenaColores.negro,
                  fontSize: 14,
                ),
              ),
            )
          else
            for (final equipo in lista)
              crearTarjetaEquipo(equipo),
        ],
      ),
    );
  }

  // ==========================================
  // PANTALLA DE SELECCIÓN
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ArenaPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: cargarDatos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('REINTENTAR'),
                ),
              ],
            ),
          ),
        ),
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
            crearFiltros(),
            const SizedBox(height: 18),
            if (equipos.isEmpty)
              const ArenaPanel(
                child: Text(
                  'Todavía no hay equipos registrados.',
                  textAlign: TextAlign.center,
                ),
              )
            else if (torneoSeleccionado == null)
              const ArenaPanel(
                child: Text(
                  'Selecciona un torneo para comenzar.',
                  textAlign: TextAlign.center,
                ),
              )
            else if (categoriaSeleccionada == null)
                const ArenaPanel(
                  child: Text(
                    'Ahora selecciona una categoría.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                crearListaEquipos(),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'EDITAR EQUIPO',
      ),
      body: ArenaFondo(
        child: crearContenido(),
      ),
    );
  }
}

// ==========================================
// PANTALLA 2 - MODIFICAR EQUIPO
// ==========================================

class FormularioEditarEquipo extends StatefulWidget {
  final Map<String, dynamic> equipo;

  const FormularioEditarEquipo({
    super.key,
    required this.equipo,
  });

  @override
  State<FormularioEditarEquipo> createState() =>
      _FormularioEditarEquipoState();
}

class _FormularioEditarEquipoState
    extends State<FormularioEditarEquipo> {
  static const int maxJugadores = 20;

  late final TextEditingController nombreEquipo;
  late final List<TextEditingController> numeros;
  late final List<TextEditingController> nombres;

  List<Map<String, dynamic>> categoriasRegistradas = [];

  String? torneoSeleccionado;
  String? categoriaIdSeleccionada;

  bool cargandoCategorias = true;
  bool clasificacionModificada = false;
  bool guardando = false;

  String? errorCategorias;

  @override
  void initState() {
    super.initState();

    nombreEquipo = TextEditingController(
      text: _texto(widget.equipo['nombre']),
    );

    numeros = List.generate(
      maxJugadores,
          (_) => TextEditingController(),
    );

    nombres = List.generate(
      maxJugadores,
          (_) => TextEditingController(),
    );

    final jugadores =
        (widget.equipo['jugadores'] as List?) ?? [];

    for (int i = 0;
    i < jugadores.length && i < maxJugadores;
    i++) {
      final jugador = jugadores[i] as Map;

      numeros[i].text =
          _texto(jugador['numero']);

      nombres[i].text =
          _texto(jugador['nombre']);
    }

    cargarCategorias();
  }

  // ==========================================
  // CARGAR CLASIFICACIÓN ACTUAL
  // ==========================================

  Future<void> cargarCategorias() async {
    if (!mounted) return;

    setState(() {
      cargandoCategorias = true;
      errorCategorias = null;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final datos =
      await prefs.getString(_claveCategorias);

      final registros = _leerRegistros(datos);

      final torneoActual =
      _texto(widget.equipo['torneo']);

      final categoriaActual =
      _texto(widget.equipo['categoria']);

      final idActual =
      _texto(widget.equipo['categoriaId']);

      String? torneoEncontrado;
      String? categoriaEncontrada;

      for (final registro in registros) {
        final torneo = _texto(registro['torneo']);

        if (_normalizar(torneo) ==
            _normalizar(torneoActual)) {
          torneoEncontrado = torneo;
          break;
        }
      }

      if (torneoEncontrado != null) {
        for (final registro in registros) {
          final torneo = _texto(registro['torneo']);
          final categoria =
          _texto(registro['categoria']);
          final id = _texto(registro['id']);

          if (_normalizar(torneo) !=
              _normalizar(torneoEncontrado)) {
            continue;
          }

          final coincideId =
              idActual.isNotEmpty && id == idActual;

          final coincideNombre =
              _normalizar(categoria) ==
                  _normalizar(categoriaActual);

          if (coincideId || coincideNombre) {
            categoriaEncontrada = id;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        categoriasRegistradas = registros;
        torneoSeleccionado = torneoEncontrado;
        categoriaIdSeleccionada = categoriaEncontrada;

        clasificacionModificada = false;
        cargandoCategorias = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoCategorias = false;
        errorCategorias =
        'No se pudieron cargar las categorías: $e';
      });
    }
  }

  // ==========================================
  // MENSAJES
  // ==========================================

  void mostrarMensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: ArenaColores.negro,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // CAMBIAR TORNEO
  // ==========================================

  void cambiarTorneo(String? valor) {
    setState(() {
      torneoSeleccionado = valor;
      categoriaIdSeleccionada = null;
      clasificacionModificada = true;
    });
  }

  // ==========================================
  // CATEGORÍAS REGISTRADAS DEL TORNEO
  // ==========================================

  List<Map<String, dynamic>> get categoriasDelTorneo {
    if (torneoSeleccionado == null) return [];

    final lista = categoriasRegistradas.where(
          (registro) {
        return _normalizar(
          _texto(registro['torneo']),
        ) ==
            _normalizar(torneoSeleccionado!);
      },
    ).toList();

    lista.sort((a, b) {
      return _normalizar(
        _texto(a['categoria']),
      ).compareTo(
        _normalizar(_texto(b['categoria'])),
      );
    });

    return lista;
  }

  // ==========================================
  // SELECTORES EN EL FORMULARIO
  // ==========================================

  Widget crearSelectoresEdicion() {
    final torneos = _obtenerTorneos(
      categoriasRegistradas,
      [],
    );

    final selectorTorneo = _selector(
      titulo: 'TORNEO',
      icono: Icons.emoji_events,
      ayuda: 'Selecciona torneo',
      valor: torneoSeleccionado,
      opciones: torneos.map((torneo) {
        return DropdownMenuItem<String>(
          value: torneo,
          child: Text(
            torneo,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: cargandoCategorias || guardando
          ? null
          : cambiarTorneo,
    );

    final selectorCategoria = _selector(
      key: ValueKey(
        'editar_categoria_${torneoSeleccionado ?? "ninguno"}',
      ),
      titulo: 'CATEGORÍA',
      icono: Icons.groups_rounded,
      ayuda: 'Selecciona categoría',
      valor: categoriaIdSeleccionada,
      opciones: categoriasDelTorneo.map((registro) {
        return DropdownMenuItem<String>(
          value: _texto(registro['id']),
          child: Text(
            _texto(registro['categoria']),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: cargandoCategorias ||
          guardando ||
          torneoSeleccionado == null
          ? null
          : (valor) {
        setState(() {
          categoriaIdSeleccionada = valor;
          clasificacionModificada = true;
        });
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, espacio) {
            if (espacio.maxWidth >= 600) {
              return Row(
                children: [
                  Expanded(child: selectorTorneo),
                  const SizedBox(width: 14),
                  Expanded(child: selectorCategoria),
                ],
              );
            }

            return Column(
              children: [
                selectorTorneo,
                const SizedBox(height: 18),
                selectorCategoria,
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'Puedes conservar el torneo y la categoría '
              'actuales. Solo cambia estos campos si lo '
              'necesitas.',
          style: TextStyle(
            color: Color(0xFF655C54),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VALIDAR JUGADORES
  // ==========================================

  List<Map<String, dynamic>>? obtenerJugadores() {
    final jugadores = <Map<String, dynamic>>[];
    final usados = <int>{};

    for (int i = 0; i < maxJugadores; i++) {
      final numeroTexto = numeros[i].text.trim();
      final nombreTexto = nombres[i].text.trim();

      if (numeroTexto.isEmpty &&
          nombreTexto.isEmpty) {
        continue;
      }

      if (numeroTexto.isEmpty ||
          nombreTexto.isEmpty) {
        mostrarMensaje(
          'Completa los datos del jugador ${i + 1}',
        );
        return null;
      }

      final numero = int.tryParse(numeroTexto);

      if (numero == null ||
          numero < 1 ||
          numero > 99) {
        mostrarMensaje(
          'El número del jugador ${i + 1} '
              'debe estar entre 1 y 99',
        );
        return null;
      }

      if (usados.contains(numero)) {
        mostrarMensaje(
          'El número $numero está repetido',
        );
        return null;
      }

      usados.add(numero);

      jugadores.add({
        'numero': numero,
        'nombre': nombreTexto,
      });
    }

    if (jugadores.isEmpty) {
      mostrarMensaje(
        'El equipo debe tener al menos un jugador',
      );
      return null;
    }

    return jugadores;
  }

  // ==========================================
  // GUARDAR MODIFICACIONES
  // ==========================================

  Future<void> guardarCambios() async {
    if (guardando || cargandoCategorias) return;

    final nombre = nombreEquipo.text.trim();

    if (nombre.isEmpty) {
      mostrarMensaje('Escribe el nombre del equipo');
      return;
    }

    final jugadores = obtenerJugadores();

    if (jugadores == null) return;

    if (clasificacionModificada &&
        (torneoSeleccionado == null ||
            categoriaIdSeleccionada == null)) {
      mostrarMensaje(
        'Selecciona el torneo y la categoría '
            'para completar el cambio.',
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final equipos = _leerRegistros(
        await prefs.getString('equipos'),
      );

      final idActual =
      _texto(widget.equipo['id']);

      final indice = equipos.indexWhere(
            (equipo) =>
        _texto(equipo['id']) == idActual,
      );

      if (indice == -1) {
        mostrarMensaje(
          'No se encontró el equipo para editar',
        );
        return;
      }

      String torneoFinal =
      _texto(equipos[indice]['torneo']);

      String categoriaFinal =
      _texto(equipos[indice]['categoria']);

      String categoriaIdFinal =
      _texto(equipos[indice]['categoriaId']);

      // Solo actualizar el torneo y la categoría
      // si el usuario decidió modificarlos.
      if (clasificacionModificada) {
        final registros = _leerRegistros(
          await prefs.getString(_claveCategorias),
        );

        Map<String, dynamic>? seleccion;

        for (final registro in registros) {
          if (_texto(registro['id']) ==
              categoriaIdSeleccionada &&
              _normalizar(_texto(registro['torneo'])) ==
                  _normalizar(torneoSeleccionado!)) {
            seleccion = registro;
            break;
          }
        }

        if (seleccion == null) {
          mostrarMensaje(
            'La categoría seleccionada '
                'ya no está disponible.',
          );
          return;
        }

        torneoFinal = _texto(seleccion['torneo']);
        categoriaFinal = _texto(seleccion['categoria']);
        categoriaIdFinal = _texto(seleccion['id']);
      }

      // Mismo nombre permitido en otras
      // categorías o torneos.
      final repetido = equipos.any((equipo) {
        if (_texto(equipo['id']) == idActual) {
          return false;
        }

        return _normalizar(_texto(equipo['nombre'])) ==
            _normalizar(nombre) &&
            _normalizar(_texto(equipo['torneo'])) ==
                _normalizar(torneoFinal) &&
            _normalizar(_texto(equipo['categoria'])) ==
                _normalizar(categoriaFinal);
      });

      if (repetido) {
        mostrarMensaje(
          'Ya existe un equipo con ese nombre '
              'en el mismo torneo y categoría.',
        );
        return;
      }

      final actualizado = <String, dynamic>{
        ...equipos[indice],
        'id': idActual,
        'nombre': nombre,
        'jugadores': jugadores,
      };

      if (clasificacionModificada) {
        actualizado['torneo'] = torneoFinal;
        actualizado['categoria'] = categoriaFinal;
        actualizado['categoriaId'] = categoriaIdFinal;
      }

      equipos[indice] = actualizado;

      await prefs.setString(
        'equipos',
        jsonEncode(equipos),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      mostrarMensaje(
        'No se pudo actualizar el equipo: $e',
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
  // TARJETA DE JUGADOR
  // ==========================================

  Widget crearCampoJugador(int indice) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE4C5A6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: ArenaColores.rojo,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'JUGADOR ${indice + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ArenaColores.negro,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: numeros[indice],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'N.º',
                      filled: true,
                      fillColor:
                      const Color(0xFFF8F7F5),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: nombres[indice],
                    textCapitalization:
                    TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre del jugador',
                      filled: true,
                      fillColor:
                      const Color(0xFFF8F7F5),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ENCABEZADO DE MODIFICACIÓN
  // ==========================================

  Widget crearEncabezado() {
    return Column(
      children: [
        const Icon(
          Icons.edit,
          color: ArenaColores.dorado,
          size: 55,
        ),
        const SizedBox(height: 12),
        const ArenaTextoMetalico(
          texto: 'EDITAR PLANTILLA',
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
            'Modifica el nombre o los jugadores. '
                'También puedes cambiar el torneo '
                'y la categoría si lo necesitas.',
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
  // FORMULARIO DE MODIFICACIÓN
  // ==========================================

  Widget crearFormulario() {
    final torneoOriginal =
    _texto(widget.equipo['torneo']);

    final categoriaOriginal =
    _texto(widget.equipo['categoria']);

    return ArenaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shield,
                color: ArenaColores.rojo,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'DATOS DEL EQUIPO',
                  style: TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          TextField(
            controller: nombreEquipo,
            textCapitalization:
            TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nombre del equipo',
              prefixIcon: const Icon(
                Icons.shield,
                color: ArenaColores.rojo,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: ArenaColores.rojo,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'TORNEO Y CATEGORÍA',
                  style: TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (cargandoCategorias)
            const Center(
              child: CircularProgressIndicator(
                color: ArenaColores.rojo,
              ),
            )
          else if (errorCategorias != null)
            Column(
              children: [
                Text(
                  errorCategorias!,
                  style: const TextStyle(
                    color: ArenaColores.rojo,
                  ),
                ),
                TextButton.icon(
                  onPressed: cargarCategorias,
                  icon: const Icon(Icons.refresh),
                  label: const Text('REINTENTAR'),
                ),
              ],
            )
          else
            crearSelectoresEdicion(),

          const SizedBox(height: 12),

          if (!clasificacionModificada &&
              (torneoSeleccionado == null ||
                  categoriaIdSeleccionada == null))
            Text(
              'Clasificación actual: '
                  '${torneoOriginal.isEmpty ? "Sin torneo" : torneoOriginal}'
                  ' · '
                  '${categoriaOriginal.isEmpty ? "Sin categoría" : categoriaOriginal}'
                  '. Puedes conservarla o asignar '
                  'una categoría registrada.',
              style: const TextStyle(
                color: Color(0xFF655C54),
                fontSize: 12,
              ),
            ),

          const SizedBox(height: 20),

          const Divider(
            color: Color(0xFFD9B48F),
          ),

          const SizedBox(height: 14),

          const Row(
            children: [
              Icon(
                Icons.groups,
                color: ArenaColores.rojo,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'JUGADORES (1-20)',
                  style: TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, espacio) {
              if (espacio.maxWidth < 700) {
                return Column(
                  children: [
                    for (int i = 0;
                    i < maxJugadores;
                    i++)
                      crearCampoJugador(i),
                  ],
                );
              }

              const separacion = 14.0;

              final anchoTarjeta =
                  (espacio.maxWidth - separacion) / 2;

              return Wrap(
                spacing: separacion,
                runSpacing: 4,
                children: [
                  for (int i = 0;
                  i < maxJugadores;
                  i++)
                    SizedBox(
                      width: anchoTarjeta,
                      child: crearCampoJugador(i),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed:
              guardando || cargandoCategorias
                  ? null
                  : guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                ArenaColores.negro,
                foregroundColor:
                ArenaColores.dorado,
                disabledBackgroundColor:
                Colors.grey,
                elevation: 5,
                shadowColor:
                ArenaColores.rojo,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
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
                    : 'GUARDAR CAMBIOS',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LIBERAR CONTROLADORES
  // ==========================================

  @override
  void dispose() {
    nombreEquipo.dispose();

    for (final controlador in numeros) {
      controlador.dispose();
    }

    for (final controlador in nombres) {
      controlador.dispose();
    }

    super.dispose();
  }

  // ==========================================
  // PANTALLA DE MODIFICACIÓN
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'MODIFICAR EQUIPO',
      ),
      body: ArenaFondo(
        child: Center(
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
                crearFormulario(),
                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
