
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';

// ==========================================
// EQUIPOS GUARDADOS - ARENA MOUSTACHE
// CONSULTA POR TORNEO Y CATEGORÍA
// ==========================================

class EquiposGuardados extends StatefulWidget {
  const EquiposGuardados({super.key});

  @override
  State<EquiposGuardados> createState() =>
      _EquiposGuardadosState();
}

class _EquiposGuardadosState
    extends State<EquiposGuardados> {
  static const String claveCategorias =
      'torneos_categorias';

  List<Map<String, dynamic>> categorias = [];
  List<Map<String, dynamic>> equipos = [];

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
  // NORMALIZAR TEXTOS
  // ==========================================

  String normalizar(String texto) {
    return texto
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  // ==========================================
  // CARGAR INFORMACIÓN GUARDADA
  // ==========================================

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final textoCategorias =
      await prefs.getString(claveCategorias);

      final textoEquipos =
      await prefs.getString('equipos');

      final categoriasCargadas =
      (jsonDecode(textoCategorias ?? '[]') as List)
          .map(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

      final equiposCargados =
      (jsonDecode(textoEquipos ?? '[]') as List)
          .map(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        categorias = categoriasCargadas;
        equipos = equiposCargados;

        torneoSeleccionado = null;
        categoriaSeleccionada = null;

        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = 'No se pudieron cargar los datos: $e';
      });
    }
  }

  // ==========================================
  // LISTA DE TORNEOS
  // ==========================================

  List<String> get torneosDisponibles {
    final unicos = <String, String>{};

    for (final registro in categorias) {
      final torneo =
          registro['torneo']?.toString().trim() ?? '';

      if (torneo.isEmpty) continue;

      unicos.putIfAbsent(
        normalizar(torneo),
            () => torneo,
      );
    }

    return unicos.values.toList()
      ..sort(
            (a, b) =>
            normalizar(a).compareTo(normalizar(b)),
      );
  }

  // ==========================================
  // CATEGORÍAS DEL TORNEO
  // ==========================================

  List<String> get categoriasDisponibles {
    if (torneoSeleccionado == null) {
      return [];
    }

    final unicas = <String, String>{};

    for (final registro in categorias) {
      final torneo =
          registro['torneo']?.toString() ?? '';

      if (normalizar(torneo) !=
          normalizar(torneoSeleccionado!)) {
        continue;
      }

      final categoria =
          registro['categoria']?.toString().trim() ?? '';

      if (categoria.isEmpty) continue;

      unicas.putIfAbsent(
        normalizar(categoria),
            () => categoria,
      );
    }

    return unicas.values.toList()
      ..sort(
            (a, b) =>
            normalizar(a).compareTo(normalizar(b)),
      );
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
      final torneo =
          equipo['torneo']?.toString() ?? '';

      final categoria =
          equipo['categoria']?.toString() ?? '';

      return normalizar(torneo) ==
          normalizar(torneoSeleccionado!) &&
          normalizar(categoria) ==
              normalizar(categoriaSeleccionada!);
    }).toList();

    // Orden alfabético por nombre de equipo.
    lista.sort((a, b) {
      final nombreA =
          a['nombre']?.toString() ?? '';

      final nombreB =
          b['nombre']?.toString() ?? '';

      return normalizar(nombreA).compareTo(
        normalizar(nombreB),
      );
    });

    return lista;
  }

  // ==========================================
  // ESTILO DE SELECTORES
  // ==========================================

  InputDecoration decoracionSelector({
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
      ),

      filled: true,
      fillColor: Colors.white,
      isDense: true,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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
    );
  }

  // ==========================================
  // SELECTOR DE TORNEO
  // ==========================================

  Widget selectorTorneo() {
    return DropdownButtonFormField<String>(
      initialValue: torneoSeleccionado,
      isExpanded: true,

      decoration: decoracionSelector(
        titulo: 'TORNEO *',
        icono: Icons.emoji_events,
      ),

      hint: const Text(
        'Selecciona un torneo',
        overflow: TextOverflow.ellipsis,
      ),

      items: torneosDisponibles.map((torneo) {
        return DropdownMenuItem<String>(
          value: torneo,
          child: Text(
            torneo,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),

      onChanged: (String? valor) {
        setState(() {
          torneoSeleccionado = valor;

          // Reiniciar la categoría al cambiar
          // el torneo seleccionado.
          categoriaSeleccionada = null;
        });
      },
    );
  }

  // ==========================================
  // SELECTOR DE CATEGORÍA
  // ==========================================

  Widget selectorCategoria() {
    return DropdownButtonFormField<String>(
      key: ValueKey(
        'categoria_${torneoSeleccionado ?? "ninguno"}',
      ),

      initialValue: categoriaSeleccionada,
      isExpanded: true,

      decoration: decoracionSelector(
        titulo: 'CATEGORÍA *',
        icono: Icons.groups_rounded,
      ),

      hint: const Text(
        'Selecciona una categoría',
        overflow: TextOverflow.ellipsis,
      ),

      items: categoriasDisponibles.map((categoria) {
        return DropdownMenuItem<String>(
          value: categoria,
          child: Text(
            categoria,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),

      onChanged: torneoSeleccionado == null
          ? null
          : (String? valor) {
        setState(() {
          categoriaSeleccionada = valor;
        });
      },
    );
  }

  // ==========================================
  // PANEL DE FILTROS
  // ==========================================

  Widget panelFiltros() {
    return ArenaPanel(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
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
              if (espacio.maxWidth >= 600) {
                return Row(
                  children: [
                    Expanded(child: selectorTorneo()),
                    const SizedBox(width: 14),
                    Expanded(child: selectorCategoria()),
                  ],
                );
              }

              return Column(
                children: [
                  selectorTorneo(),
                  const SizedBox(height: 18),
                  selectorCategoria(),
                ],
              );
            },
          ),

          if (categorias.isEmpty) ...[
            const SizedBox(height: 15),
            const Text(
              'Todavía no hay torneos ni '
                  'categorías registrados.',
              style: TextStyle(
                color: ArenaColores.rojo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TARJETA DE EQUIPO GUARDADO
  // ==========================================

  Widget tarjetaEquipo(
      Map<String, dynamic> equipo,
      ) {
    final nombre =
        equipo['nombre']?.toString() ?? 'Sin nombre';

    final jugadores =
        (equipo['jugadores'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD9B48F),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ArenaColores.negro,
              borderRadius: BorderRadius.circular(12),
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

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Jugadores registrados: '
                      '${jugadores.length}',
                  style: const TextStyle(
                    color: Color(0xFF625A58),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.check_circle,
            color: ArenaColores.rojo,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LISTA DE EQUIPOS GUARDADOS
  // ==========================================

  Widget listaEquipos() {
    final lista = equiposFiltrados;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        ArenaPanel(
          child: Row(
            children: [
              const Icon(
                Icons.groups,
                color: ArenaColores.rojo,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'EQUIPOS REGISTRADOS',
                  style: TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              Text(
                '${lista.length}',
                style: const TextStyle(
                  color: ArenaColores.rojo,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        if (lista.isEmpty)
          ArenaPanel(
            child: const Text(
              'No hay equipos guardados en '
                  'este torneo y categoría.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ArenaColores.negro,
                fontSize: 14,
              ),
            ),
          )
        else
          for (final equipo in lista)
            tarjetaEquipo(equipo),
      ],
    );
  }

  // ==========================================
  // ENCABEZADO
  // ==========================================

  Widget encabezado() {
    return const Column(
      children: [
        Icon(
          Icons.folder_open,
          size: 48,
          color: ArenaColores.dorado,
        ),

        SizedBox(height: 12),

        ArenaTextoMetalico(
          texto: 'EQUIPOS GUARDADOS',
          tamano: 25,
          dorado: true,
        ),

        SizedBox(height: 12),

        Text(
          'Consulta los equipos registrados '
              'según su torneo y categoría.',
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
      ],
    );
  }

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'EQUIPOS GUARDADOS',
      ),

      body: ArenaFondo(
        child: cargando
            ? const Center(
          child: CircularProgressIndicator(
            color: ArenaColores.dorado,
          ),
        )
            : error != null
            ? Center(
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
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'REINTENTAR',
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            : Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1100,
            ),
            child: ListView(
              padding:
              const EdgeInsets.all(18),
              children: [
                const SizedBox(height: 12),

                encabezado(),

                const SizedBox(height: 27),

                panelFiltros(),

                const SizedBox(height: 20),

                if (torneoSeleccionado == null)
                  const ArenaPanel(
                    child: Text(
                      'Selecciona un torneo '
                          'para comenzar.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (
                categoriaSeleccionada == null
                )
                  const ArenaPanel(
                    child: Text(
                      'Ahora selecciona '
                          'una categoría.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  listaEquipos(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
