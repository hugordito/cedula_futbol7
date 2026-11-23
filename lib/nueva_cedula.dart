import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cargar_equipo.dart';
import 'registro_shootouts.dart';
import 'cedula_tactil.dart';
import 'arena_estilo.dart';

class NuevaCedula extends StatefulWidget {
  const NuevaCedula({super.key});

  @override
  State<NuevaCedula> createState() => _NuevaCedulaState();
}

class _NuevaCedulaState extends State<NuevaCedula> {
  final Map<String, TextEditingController> campos = {
    'ciudad': TextEditingController(),
    'torneo': TextEditingController(),
    'cancha': TextEditingController(),
    'fecha': TextEditingController(),
    'hora': TextEditingController(),
    'jornada': TextEditingController(),
    'categoria': TextEditingController(),
    'rama': TextEditingController(),
    'arbitro': TextEditingController(),
    'observaciones': TextEditingController(),
    'dtLocal': TextEditingController(),
    'atLocal': TextEditingController(),
    'dtVisitante': TextEditingController(),
    'atVisitante': TextEditingController(),
  };

  Map<String, dynamic>? equipoLocal;
  Map<String, dynamic>? equipoVisitante;
  List<Map<String, dynamic>> eventos = [];
  List<Map<String, dynamic>> shootouts = [];
  List<Map<String, dynamic>> faltasBloques = [];
  List<Map<String, dynamic>> marcasVisuales = [];
  Map<String, String> firmas = {};
  bool cargando = true;
  bool guardando = false;
  String? error;

  String dato(String clave) => campos[clave]?.text.trim() ?? '';
  String normalizar(String texto) =>
      texto.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  bool perteneceAlPartido(Map<String, dynamic>? equipo) {
    if (equipo == null ||
        dato('torneo').isEmpty ||
        dato('categoria').isEmpty) {
      return false;
    }
    return normalizar(equipo['torneo']?.toString() ?? '') ==
        normalizar(dato('torneo')) &&
        normalizar(equipo['categoria']?.toString() ?? '') ==
            normalizar(dato('categoria'));
  }

  void limpiarRegistrosDelPartido() {
    eventos = [];
    shootouts = [];
    faltasBloques = [];
    marcasVisuales = [];
    firmas = {};
  }

  @override
  void initState() {
    super.initState();
    cargarEquipos();
  }

  // Si se cambió el torneo o la categoría, nunca mostrar ni conservar
  // equipos que pertenecen a otra combinación.
  void actualizarCampos() {
    setState(() {
      if ((equipoLocal != null && !perteneceAlPartido(equipoLocal)) ||
          (equipoVisitante != null && !perteneceAlPartido(equipoVisitante))) {
        equipoLocal = null;
        equipoVisitante = null;
        limpiarRegistrosDelPartido();
      }
    });
  }

  int contar(String lado, String tipo) {
    final eventosContados = eventos.where((item) =>
    item['lado'] == lado && item['tipo'] == tipo).length;
    if (tipo != 'falta') return eventosContados;
    return eventosContados +
        faltasBloques.where((item) => item['lado'] == lado).length;
  }

  int shootoutsAcertados(String lado) => shootouts.where((intento) =>
  intento['lado'] == lado && intento['resultado'] == 'gol').length;

  void mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> cargarEquipos() async {
    if (!mounted) return;
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = SharedPreferencesAsync();
      final textoEquipos = await prefs.getString('equipos');
      final textoSeleccion = await prefs.getString('partido_equipos');
      final equipos = (jsonDecode(textoEquipos ?? '[]') as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      Map<String, dynamic>? local;
      Map<String, dynamic>? visitante;
      if (textoSeleccion != null) {
        final seleccion = Map<String, dynamic>.from(
          jsonDecode(textoSeleccion) as Map,
        );
        final idLocal = seleccion['localId']?.toString();
        final idVisitante = seleccion['visitanteId']?.toString();
        for (final equipo in equipos) {
          if (equipo['id']?.toString() == idLocal &&
              perteneceAlPartido(equipo)) {
            local = equipo;
          }
          if (equipo['id']?.toString() == idVisitante &&
              perteneceAlPartido(equipo)) {
            visitante = equipo;
          }
        }
      }

      if (!mounted) return;
      final cambiaron = equipoLocal?['id'] != local?['id'] ||
          equipoVisitante?['id'] != visitante?['id'];
      setState(() {
        equipoLocal = local;
        equipoVisitante = visitante;
        if (cambiaron) limpiarRegistrosDelPartido();
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cargando = false;
        error = 'No se pudieron cargar equipos: $e';
      });
    }
  }

  Future<void> seleccionarEquipos() async {
    final torneo = dato('torneo');
    final categoria = dato('categoria');
    if (torneo.isEmpty) {
      mensaje('Primero toca TORNEO en la hoja y selecciona uno');
      return;
    }
    if (categoria.isEmpty) {
      mensaje('Primero selecciona la CATEGORÍA en la hoja');
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CargarEquipo(
          torneo: torneo,
          categoria: categoria,
        ),
      ),
    );
    if (!mounted) return;
    await cargarEquipos();
  }

  Future<void> abrirShootouts() async {
    if (equipoLocal == null || equipoVisitante == null) {
      mensaje('Primero selecciona los equipos');
      return;
    }
    final resultado = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute<List<Map<String, dynamic>>>(
        builder: (context) => RegistroShootouts(
          equipoLocal: equipoLocal!,
          equipoVisitante: equipoVisitante!,
          intentosIniciales: shootouts,
        ),
      ),
    );
    if (!mounted || resultado == null) return;
    setState(() => shootouts = resultado);
  }

  Future<void> guardarBorrador() async {
    if (guardando) return;
    if (dato('torneo').isEmpty || dato('categoria').isEmpty) {
      mensaje('Selecciona el torneo y la categoría');
      return;
    }
    if (equipoLocal == null || equipoVisitante == null) {
      mensaje('Selecciona los dos equipos');
      return;
    }
    if (!perteneceAlPartido(equipoLocal) ||
        !perteneceAlPartido(equipoVisitante)) {
      mensaje('Los equipos deben pertenecer al torneo y categoría elegidos');
      return;
    }
    if (equipoLocal!['id'] == equipoVisitante!['id']) {
      mensaje('Los equipos deben ser diferentes');
      return;
    }
    if (dato('fecha').isEmpty) {
      mensaje('Completa la fecha');
      return;
    }

    setState(() => guardando = true);
    try {
      final prefs = SharedPreferencesAsync();
      final texto = await prefs.getString('cedulas_borrador');
      final lista = jsonDecode(texto ?? '[]') as List;
      final ahora = DateTime.now();
      final nuevaCedula = <String, dynamic>{
        'id': ahora.microsecondsSinceEpoch.toString(),
        'estado': 'borrador',
        'creadaEn': ahora.toIso8601String(),
        for (final entrada in campos.entries)
          entrada.key: entrada.value.text.trim(),
        'equipoLocal': equipoLocal,
        'equipoVisitante': equipoVisitante,
        'eventos': eventos,
        'shootouts': shootouts,
        'faltasBloques': faltasBloques,
        'marcasVisuales': marcasVisuales,
        'firmas': Map<String, String>.from(firmas),
        'golesLocal': contar('local', 'gol'),
        'golesVisitante': contar('visitante', 'gol'),
        'faltasLocal': contar('local', 'falta'),
        'faltasVisitante': contar('visitante', 'falta'),
        'shootoutsGolLocal': shootoutsAcertados('local'),
        'shootoutsGolVisitante': shootoutsAcertados('visitante'),
      };
      lista.add(nuevaCedula);
      await prefs.setString('cedulas_borrador', jsonEncode(lista));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      mensaje('Error al guardar borrador: $e');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  void dispose() {
    for (final controlador in campos.values) {
      controlador.dispose();
    }
    super.dispose();
  }

  Widget botonMetalico({
    required String texto,
    required IconData icono,
    required VoidCallback? onPressed,
    Color acento = ArenaColores.dorado,
    double altura = 43,
  }) {
    return SizedBox(
      height: altura,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: acento, width: 1.3),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF50302E),
                Color(0xFF2D1B1D),
                Color(0xFF100B0D),
              ],
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            splashColor: acento.withValues(alpha: 0.22),
            child: Opacity(
              opacity: onPressed == null ? 0.5 : 1,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icono, size: 19, color: acento),
                        const SizedBox(width: 8),
                        Text(
                          texto,
                          maxLines: 1,
                          style: TextStyle(
                            color: acento,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(titulo: 'NUEVA CÉDULA'),
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
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(maxWidth: 260),
                  child: SizedBox(
                    width: double.infinity,
                    child: botonMetalico(
                      texto: guardando
                          ? 'GUARDANDO...'
                          : 'GUARDAR CÉDULA',
                      icono: guardando
                          ? Icons.hourglass_top
                          : Icons.save,
                      onPressed:
                      guardando ? null : guardarBorrador,
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 5,
              ),
              child: Text(
                'Toca las casillas de la hoja para introducir datos y firmas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 5),
                  ],
                ),
              ),
            ),
            Expanded(
              child: CedulaTactil(
                campos: campos,
                equipoLocal: equipoLocal,
                equipoVisitante: equipoVisitante,
                eventos: eventos,
                shootouts: shootouts,
                faltasBloques: faltasBloques,
                marcasVisuales: marcasVisuales,
                firmas: firmas,
                onFaltasBloquesActualizadas: (nuevas) {
                  setState(() => faltasBloques = nuevas);
                },
                onMarcasVisualesActualizadas: (nuevas) {
                  setState(() => marcasVisuales = nuevas);
                },
                onCamposActualizados: actualizarCampos,
                onEventosActualizados: (nuevosEventos) {
                  setState(() => eventos = nuevosEventos);
                },
                onFirmasActualizadas: (nuevasFirmas) {
                  setState(() =>
                  firmas = Map<String, String>.from(nuevasFirmas));
                },
                onEditarEquipos: seleccionarEquipos,
                onEditarShootouts: abrirShootouts,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
