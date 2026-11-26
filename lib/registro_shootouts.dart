import 'package:material_ui/material_ui.dart';

class RegistroShootouts extends StatefulWidget {
  final Map<String, dynamic> equipoLocal;
  final Map<String, dynamic> equipoVisitante;
  final List<Map<String, dynamic>> intentosIniciales;

  const RegistroShootouts({
    super.key,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.intentosIniciales,
  });

  @override
  State<RegistroShootouts> createState() => _RegistroShootoutsState();
}

class _RegistroShootoutsState extends State<RegistroShootouts> {
  static const Color vinoOscuro = Color(0xFF24060A);
  static const Color vinoMedio = Color(0xFF4A1017);
  static const Color dorado = Color(0xFFE8C15B);
  static const Color doradoSuave = Color(0xFFF4D983);
  static const Color blancoPanel = Color(0xFFF8F5F0);
  static const Color rojoArena = Color(0xFFC91C1C);
  static const Color verdeExito = Color(0xFF2E7D32);

  late List<Map<String, dynamic>> intentos;

  String ladoSeleccionado = 'local';
  int? numeroJugadorSeleccionado;
  String? nombreJugadorSeleccionado;
  String resultadoSeleccionado = 'gol';

  @override
  void initState() {
    super.initState();

    intentos = widget.intentosIniciales
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    _sincronizarJugadorSeleccionado();
  }

  Map<String, dynamic> equipoDe(String lado) {
    return lado == 'local'
        ? widget.equipoLocal
        : widget.equipoVisitante;
  }

  String nombreEquipo(String lado) {
    return (equipoDe(lado)['nombre'] ?? '').toString();
  }

  List<Map<String, dynamic>> jugadoresDe(String lado) {
    final lista = (equipoDe(lado)['jugadores'] as List?) ?? [];

    return lista
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> intentosDe(String lado) {
    final lista = intentos
        .where((e) => e['lado'] == lado)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    lista.sort((a, b) {
      final oa = int.tryParse(a['orden'].toString()) ?? 0;
      final ob = int.tryParse(b['orden'].toString()) ?? 0;
      return oa.compareTo(ob);
    });

    return lista;
  }

  int aciertosDe(String lado) {
    return intentosDe(lado)
        .where((e) => e['resultado'] == 'gol')
        .length;
  }

  void mostrarMensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: vinoOscuro,
      ),
    );
  }

  void _sincronizarJugadorSeleccionado() {
    final jugadores = jugadoresDe(ladoSeleccionado);

    if (jugadores.isEmpty) {
      numeroJugadorSeleccionado = null;
      nombreJugadorSeleccionado = null;
      return;
    }

    final existe = jugadores.any((j) {
      return int.tryParse(j['numero'].toString()) ==
          numeroJugadorSeleccionado;
    });

    if (!existe) {
      numeroJugadorSeleccionado = int.tryParse(
        jugadores.first['numero'].toString(),
      );
      nombreJugadorSeleccionado =
          jugadores.first['nombre'].toString();
    } else {
      final jugador = jugadores.firstWhere(
            (j) =>
        int.tryParse(j['numero'].toString()) ==
            numeroJugadorSeleccionado,
      );
      nombreJugadorSeleccionado =
          jugador['nombre'].toString();
    }
  }

  void agregarIntento() {
    if (numeroJugadorSeleccionado == null ||
        nombreJugadorSeleccionado == null ||
        nombreJugadorSeleccionado!.trim().isEmpty) {
      mostrarMensaje('Selecciona un jugador');
      return;
    }

    final listaLado = intentosDe(ladoSeleccionado);

    if (listaLado.length >= 8) {
      mostrarMensaje(
        'Solo se permiten 8 intentos por equipo',
      );
      return;
    }

    setState(() {
      intentos.add({
        'lado': ladoSeleccionado,
        'numero': numeroJugadorSeleccionado,
        'nombre': nombreJugadorSeleccionado,
        'resultado': resultadoSeleccionado,
        'orden': listaLado.length + 1,
      });
    });

    mostrarMensaje('Intento agregado');
  }

  void eliminarIntento(Map<String, dynamic> intento) {
    setState(() {
      intentos.remove(intento);

      final local = intentosDe('local');
      final visitante = intentosDe('visitante');

      for (int i = 0; i < local.length; i++) {
        local[i]['orden'] = i + 1;
      }

      for (int i = 0; i < visitante.length; i++) {
        visitante[i]['orden'] = i + 1;
      }

      intentos = [...local, ...visitante];
    });

    mostrarMensaje('Intento eliminado');
  }

  Widget _fondoPantalla({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/ui/fondo_inicio.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.20),
        ),
        child: child,
      ),
    );
  }

  Widget _panelPrincipal({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(22),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: blancoPanel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dorado,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _tituloMetalico(String texto, {double tamano = 18}) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Color(0xFFFFF2A6),
            Color(0xFFE8C15B),
            Color(0xFFB8860B),
          ],
        ).createShader(bounds);
      },
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: tamano,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            vinoMedio,
            vinoOscuro,
          ],
        ),
        border: Border.all(
          color: dorado,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.sports_soccer,
            size: 42,
            color: dorado,
          ),
          const SizedBox(height: 10),
          _tituloMetalico(
            'DEFINICIÓN EN SHOOT OUT',
            tamano: 27,
          ),
          const SizedBox(height: 8),
          Text(
            'Registra hasta 8 intentos por equipo.\nEstos goles se cuentan por separado del marcador principal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 14.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionEtiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: vinoOscuro,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _dropdownLado() {
    return DropdownButtonFormField<String>(
      value: ladoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Equipo',
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: vinoOscuro,
        ),
        prefixIcon: const Icon(
          Icons.shield,
          color: rojoArena,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: dorado.withOpacity(0.75),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: dorado,
            width: 1.8,
          ),
        ),
      ),
      dropdownColor: Colors.white,
      items: [
        DropdownMenuItem<String>(
          value: 'local',
          child: Text(
            'LOCAL: ${nombreEquipo('local')}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DropdownMenuItem<String>(
          value: 'visitante',
          child: Text(
            'VISITANTE: ${nombreEquipo('visitante')}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      onChanged: (valor) {
        if (valor == null) return;

        setState(() {
          ladoSeleccionado = valor;
          _sincronizarJugadorSeleccionado();
        });
      },
    );
  }

  Widget _dropdownJugador() {
    final jugadores = jugadoresDe(ladoSeleccionado);

    return DropdownButtonFormField<int>(
      value: numeroJugadorSeleccionado,
      decoration: InputDecoration(
        labelText: 'Jugador',
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: vinoOscuro,
        ),
        prefixIcon: const Icon(
          Icons.person,
          color: rojoArena,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: dorado.withOpacity(0.75),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: dorado,
            width: 1.8,
          ),
        ),
      ),
      items: jugadores.map((jugador) {
        final numero = int.tryParse(
          jugador['numero'].toString(),
        );
        final nombre = jugador['nombre'].toString();

        return DropdownMenuItem<int>(
          value: numero,
          child: Text(
            '#${jugador['numero']} · $nombre',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
      onChanged: jugadores.isEmpty
          ? null
          : (valor) {
        if (valor == null) return;

        final jugador = jugadores.firstWhere(
              (j) =>
          int.tryParse(j['numero'].toString()) ==
              valor,
        );

        setState(() {
          numeroJugadorSeleccionado = valor;
          nombreJugadorSeleccionado =
              jugador['nombre'].toString();
        });
      },
    );
  }

  Widget _dropdownResultado() {
    return DropdownButtonFormField<String>(
      value: resultadoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Resultado',
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: vinoOscuro,
        ),
        prefixIcon: Icon(
          resultadoSeleccionado == 'gol'
              ? Icons.check_circle
              : Icons.cancel,
          color: resultadoSeleccionado == 'gol'
              ? verdeExito
              : rojoArena,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: dorado.withOpacity(0.75),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: dorado,
            width: 1.8,
          ),
        ),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: 'gol',
          child: Text(
            'Gol',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DropdownMenuItem<String>(
          value: 'fallo',
          child: Text(
            'Falló',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
      onChanged: (valor) {
        if (valor == null) return;

        setState(() {
          resultadoSeleccionado = valor;
        });
      },
    );
  }

  Widget _botonMetalico({
    required String texto,
    required IconData icono,
    required VoidCallback? onPressed,
    double altura = 52,
  }) {
    return SizedBox(
      width: double.infinity,
      height: altura,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [vinoMedio, vinoOscuro],
              ),
              border: Border.all(
                color: dorado,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icono,
                  color: doradoSuave,
                ),
                const SizedBox(width: 10),
                Text(
                  texto,
                  style: const TextStyle(
                    color: doradoSuave,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumenEquipo(String lado) {
    final lista = intentosDe(lado);
    final aciertos = aciertosDe(lado);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dorado.withOpacity(0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lado == 'local'
                    ? Icons.home_filled
                    : Icons.flight_takeoff,
                color: rojoArena,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${lado.toUpperCase()}: ${nombreEquipo(lado)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: vinoOscuro,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Aciertos: $aciertos de ${lista.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (lista.isEmpty)
            const Text(
              'Aún no hay intentos registrados.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...lista.map((intento) {
              return Container(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F2),
                  borderRadius:
                  BorderRadius.circular(16),
                  border: Border.all(
                    color: dorado.withOpacity(0.55),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black87,
                            height: 1.4,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text:
                              '${intento['orden']}. ',
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text:
                              '#${intento['numero']} ${intento['nombre']}\n',
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: intento[
                              'resultado'] ==
                                  'gol'
                                  ? 'GOL'
                                  : 'FALLÓ',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.w900,
                                color: intento[
                                'resultado'] ==
                                    'gol'
                                    ? verdeExito
                                    : rojoArena,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          eliminarIntento(intento),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: vinoOscuro,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SHOOT OUTS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: vinoOscuro,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _fondoPantalla(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _encabezado(),
                    const SizedBox(height: 18),
                    _panelPrincipal(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REGISTRO DE INTENTOS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.w900,
                              color: vinoOscuro,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: dorado),
                          const SizedBox(height: 16),
                          _seccionEtiqueta('Equipo'),
                          _dropdownLado(),
                          const SizedBox(height: 14),
                          _seccionEtiqueta('Jugador'),
                          _dropdownJugador(),
                          const SizedBox(height: 14),
                          _seccionEtiqueta('Resultado'),
                          _dropdownResultado(),
                          const SizedBox(height: 18),
                          _botonMetalico(
                            texto: 'AGREGAR INTENTO',
                            icono: Icons.add,
                            onPressed: agregarIntento,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, espacio) {
                        final dosColumnas =
                            espacio.maxWidth >= 780;

                        if (!dosColumnas) {
                          return Column(
                            children: [
                              _resumenEquipo('local'),
                              const SizedBox(height: 16),
                              _resumenEquipo(
                                  'visitante'),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _resumenEquipo(
                                  'local'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _resumenEquipo(
                                  'visitante'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _botonMetalico(
                      texto:
                      'GUARDAR SHOOT OUTS EN LA CÉDULA',
                      icono: Icons.save_alt,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          intentos,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}