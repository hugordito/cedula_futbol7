import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';

// ==========================================
// CARGAR EQUIPOS - ARENA MOUSTACHE
// FILTRADO POR TORNEO Y CATEGORÍA
// ==========================================

class CargarEquipo extends StatefulWidget {
  final String? torneo;
  final String? categoria;

  const CargarEquipo({
    super.key,
    this.torneo,
    this.categoria,
  });

  @override
  State<CargarEquipo> createState() => _CargarEquipoState();
}

class _CargarEquipoState extends State<CargarEquipo> {
  List<Map<String, dynamic>> equipos = [];
  List<Map<String, dynamic>> categorias = [];
  String? torneoActual;
  String? categoriaActual;
  String? localId;
  String? visitanteId;
  bool cargando = true;
  bool guardando = false;
  String? error;

  bool get filtrosFijos =>
      (widget.torneo?.trim().isNotEmpty ?? false) &&
          (widget.categoria?.trim().isNotEmpty ?? false);

  String normalizar(String texto) =>
      texto.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  List<String> get torneosDisponibles {
    final unicos = <String, String>{};
    for (final registro in categorias) {
      final valor = registro['torneo']?.toString().trim() ?? '';
      if (valor.isNotEmpty) {
        unicos.putIfAbsent(normalizar(valor), () => valor);
      }
    }
    return unicos.values.toList()
      ..sort((a, b) => normalizar(a).compareTo(normalizar(b)));
  }

  List<String> get categoriasDisponibles {
    final unicas = <String, String>{};
    if (torneoActual == null) return [];
    for (final registro in categorias) {
      if (normalizar(registro['torneo']?.toString() ?? '') !=
          normalizar(torneoActual!)) {
        continue;
      }
      final valor = registro['categoria']?.toString().trim() ?? '';
      if (valor.isNotEmpty) {
        unicas.putIfAbsent(normalizar(valor), () => valor);
      }
    }
    return unicas.values.toList()
      ..sort((a, b) => normalizar(a).compareTo(normalizar(b)));
  }

  bool perteneceAlFiltro(Map<String, dynamic> equipo) {
    if (torneoActual == null || categoriaActual == null) return false;
    return normalizar(equipo['torneo']?.toString() ?? '') ==
        normalizar(torneoActual!) &&
        normalizar(equipo['categoria']?.toString() ?? '') ==
            normalizar(categoriaActual!);
  }

  List<Map<String, dynamic>> get equiposFiltrados {
    final lista = equipos.where(perteneceAlFiltro).toList();
    lista.sort((a, b) =>
        normalizar(a['nombre']?.toString() ?? '').compareTo(
          normalizar(b['nombre']?.toString() ?? ''),
        ));
    return lista;
  }

  Map<String, dynamic>? buscarEquipo(String? id) {
    if (id == null) return null;
    for (final equipo in equiposFiltrados) {
      if (equipo['id']?.toString() == id) return equipo;
    }
    return null;
  }

  void mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: ArenaColores.negro,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> cargarDatos() async {
    try {
      final prefs = SharedPreferencesAsync();
      final textos = await Future.wait([
        prefs.getString('equipos'),
        prefs.getString('torneos_categorias'),
        prefs.getString('partido_equipos'),
      ]);
      final listaEquipos = (jsonDecode(textos[0] ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final listaCategorias = (jsonDecode(textos[1] ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final seleccion = textos[2] == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(textos[2]!) as Map);

      final torneo = filtrosFijos
          ? widget.torneo!.trim()
          : seleccion['torneo']?.toString();
      final categoria = filtrosFijos
          ? widget.categoria!.trim()
          : seleccion['categoria']?.toString();

      bool coincide(Map<String, dynamic> equipo) =>
          torneo != null && categoria != null &&
              normalizar(equipo['torneo']?.toString() ?? '') == normalizar(torneo) &&
              normalizar(equipo['categoria']?.toString() ?? '') ==
                  normalizar(categoria);

      String? idSiValido(dynamic id) {
        if (id == null) return null;
        for (final equipo in listaEquipos) {
          if (equipo['id']?.toString() == id.toString() && coincide(equipo)) {
            return id.toString();
          }
        }
        return null;
      }

      if (!mounted) return;
      setState(() {
        equipos = listaEquipos;
        categorias = listaCategorias;
        torneoActual = torneo;
        categoriaActual = categoria;
        localId = idSiValido(seleccion['localId']);
        visitanteId = idSiValido(seleccion['visitanteId']);
        cargando = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cargando = false;
        error = 'No se pudieron cargar los equipos: $e';
      });
    }
  }

  void cambiarTorneo(String? nuevo) {
    setState(() {
      torneoActual = nuevo;
      categoriaActual = null;
      localId = null;
      visitanteId = null;
    });
  }

  void cambiarCategoria(String? nueva) {
    setState(() {
      categoriaActual = nueva;
      localId = null;
      visitanteId = null;
    });
  }

  Future<void> guardarSeleccion() async {
    if (guardando) return;
    if (torneoActual == null || categoriaActual == null) {
      mensaje('Primero selecciona el torneo y la categoría');
      return;
    }
    if (localId == null || visitanteId == null) {
      mensaje('Selecciona ambos equipos');
      return;
    }
    if (localId == visitanteId) {
      mensaje('El equipo local y visitante deben ser diferentes');
      return;
    }
    if (buscarEquipo(localId) == null || buscarEquipo(visitanteId) == null) {
      mensaje('Los equipos deben pertenecer al torneo y categoría elegidos');
      return;
    }

    setState(() => guardando = true);
    try {
      final prefs = SharedPreferencesAsync();
      // Validar nuevamente los equipos almacenados antes de guardar.
      final textoEquipos = await prefs.getString('equipos');
      final actuales = (jsonDecode(textoEquipos ?? '[]') as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      bool valido(String? id) => actuales.any(
            (e) => e['id']?.toString() == id && perteneceAlFiltro(e),
      );
      if (!valido(localId) || !valido(visitanteId)) {
        mensaje('Un equipo ya no está disponible en esta categoría');
        return;
      }
      await prefs.setString(
        'partido_equipos',
        jsonEncode({
          'localId': localId,
          'visitanteId': visitanteId,
          'torneo': torneoActual,
          'categoria': categoriaActual,
        }),
      );
      if (!mounted) return;
      mensaje('Selección guardada correctamente');
    } catch (e) {
      mensaje('No se pudo guardar la selección: $e');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Widget crearEncabezado() => Column(
    children: [
      const Icon(Icons.sports_soccer,
          size: 55, color: ArenaColores.dorado),
      const SizedBox(height: 12),
      const ArenaTextoMetalico(
        texto: 'SELECCIÓN DE EQUIPOS',
        tamano: 25,
        dorado: true,
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xD91B0505),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x80FFD36B)),
        ),
        child: const Text(
          'Selecciona un equipo LOCAL y otro VISITANTE del mismo torneo y categoría.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    ],
  );

  Widget crearFiltros() {
    final torneos = torneosDisponibles;
    final posibles = categoriasDisponibles;
    final t = torneoActual;
    final c = categoriaActual;
    return ArenaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'TORNEO Y CATEGORÍA',
            style: TextStyle(
              color: ArenaColores.negro,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (filtrosFijos) ...[
            Row(
              children: [
                const Icon(Icons.emoji_events, color: ArenaColores.rojo),
                const SizedBox(width: 10),
                Expanded(child: Text('TORNEO: $t',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: ArenaColores.rojo),
                const SizedBox(width: 10),
                Expanded(child: Text('CATEGORÍA: $c',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
              ],
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              key: const ValueKey('torneo_cargar'),
              initialValue: torneos.any((e) => e == t) ? t : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'TORNEO *',
                prefixIcon: Icon(Icons.emoji_events, color: ArenaColores.rojo),
                border: OutlineInputBorder(),
              ),
              items: torneos
                  .map((valor) => DropdownMenuItem(
                value: valor,
                child: Text(valor, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: guardando ? null : cambiarTorneo,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey('categoria_cargar_${t ?? 'ninguna'}'),
              initialValue: posibles.any((e) => e == c) ? c : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'CATEGORÍA *',
                prefixIcon: Icon(Icons.groups_rounded, color: ArenaColores.rojo),
                border: OutlineInputBorder(),
              ),
              items: posibles
                  .map((valor) => DropdownMenuItem(
                value: valor,
                child: Text(valor, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: guardando || t == null ? null : cambiarCategoria,
            ),
          ],
          if (t == null || c == null) ...[
            const SizedBox(height: 10),
            const Text(
              'Selecciona el torneo y la categoría para ver los equipos registrados.',
              style: TextStyle(color: ArenaColores.rojo, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget crearPanel({
    required String titulo,
    required Color color,
    required String? seleccionado,
    required ValueChanged<String?> alCambiar,
  }) {
    final equipo = buscarEquipo(seleccionado);
    final jugadores = (equipo?['jugadores'] as List?) ?? [];
    final disponibles = equiposFiltrados;

    return ArenaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ArenaColores.negro,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ArenaColores.dorado),
                ),
                child: const Icon(
                  Icons.shield,
                  color: ArenaColores.dorado,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: ArenaColores.negro,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD9B48F), width: 1.2),
            ),
            child: DropdownButton<String>(
              value: disponibles.any((e) => e['id']?.toString() == seleccionado)
                  ? seleccionado
                  : null,
              isExpanded: true,
              dropdownColor: Colors.white,
              underline: const SizedBox.shrink(),
              hint: const Text('Selecciona un equipo',
                  style: TextStyle(color: Color(0xFF756D66))),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: ArenaColores.rojo),
              style: const TextStyle(
                color: ArenaColores.negro,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              items: disponibles
                  .map((e) => DropdownMenuItem<String>(
                value: e['id'].toString(),
                child: Text(e['nombre']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: guardando ||
                  torneoActual == null ||
                  categoriaActual == null ||
                  disponibles.isEmpty
                  ? null
                  : alCambiar,
            ),
          ),
          if (equipo == null) ...[
            const SizedBox(height: 17),
            Center(
              child: Text(
                disponibles.isEmpty && categoriaActual != null
                    ? 'No hay equipos registrados en esta categoría.'
                    : 'Aún no has seleccionado un equipo.',
                style: const TextStyle(
                  color: Color(0xFF756D66),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'JUGADORES: ${jugadores.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final jugador in jugadores)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ArenaColores.negro,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: ArenaColores.dorado),
                      ),
                      child: Text(
                        '#${(jugador as Map)['numero']}',
                        style: const TextStyle(
                          color: ArenaColores.dorado,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${jugador['nombre']}',
                        style: const TextStyle(
                          color: ArenaColores.negro,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget crearBotonGuardar() => SizedBox(
    height: 58,
    child: ElevatedButton.icon(
      onPressed: guardando ? null : guardarSeleccion,
      style: ElevatedButton.styleFrom(
        backgroundColor: ArenaColores.negro,
        foregroundColor: ArenaColores.dorado,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ArenaColores.dorado, width: 1.5),
        ),
      ),
      icon: Icon(guardando ? Icons.hourglass_top : Icons.save),
      label: Text(
        guardando ? 'GUARDANDO...' : 'GUARDAR SELECCIÓN',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(titulo: 'CARGAR EQUIPOS'),
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
            padding: const EdgeInsets.all(20),
            child: ArenaPanel(
              child: Text(error!, textAlign: TextAlign.center),
            ),
          ),
        )
            : Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const SizedBox(height: 14),
                crearEncabezado(),
                const SizedBox(height: 26),
                crearFiltros(),
                const SizedBox(height: 16),
                crearPanel(
                  titulo: 'EQUIPO LOCAL',
                  color: const Color(0xFFB31212),
                  seleccionado: localId,
                  alCambiar: (id) => setState(() => localId = id),
                ),
                const SizedBox(height: 16),
                crearPanel(
                  titulo: 'EQUIPO VISITANTE',
                  color: const Color(0xFF1F1A17),
                  seleccionado: visitanteId,
                  alCambiar: (id) => setState(() => visitanteId = id),
                ),
                const SizedBox(height: 26),
                crearBotonGuardar(),
                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
