
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';

// ==========================================
// AGREGAR EQUIPO - ARENA MOUSTACHE
// TORNEO Y CATEGORÍA OBLIGATORIOS
// ==========================================

class AgregarEquipo extends StatefulWidget {
  const AgregarEquipo({super.key});

  @override
  State<AgregarEquipo> createState() =>
      _AgregarEquipoState();
}

class _AgregarEquipoState extends State<AgregarEquipo> {
  static const int maxJugadores = 20;

  static const String claveCategorias =
      'torneos_categorias';

  final nombreEquipo = TextEditingController();

  final numeros = List.generate(
    maxJugadores,
        (_) => TextEditingController(),
  );

  final nombres = List.generate(
    maxJugadores,
        (_) => TextEditingController(),
  );

  List<Map<String, dynamic>> categoriasRegistradas = [];

  String? torneoSeleccionado;
  String? categoriaIdSeleccionada;

  bool cargandoCategorias = true;
  bool guardando = false;

  String? errorCategorias;

  @override
  void initState() {
    super.initState();
    cargarCategorias();
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  String normalizar(String texto) {
    return texto
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

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
  // CARGAR CATEGORÍAS GUARDADAS
  // ==========================================

  Future<void> cargarCategorias() async {
    try {
      final prefs = SharedPreferencesAsync();

      final datos = await prefs.getString(
        claveCategorias,
      );

      final lista = (jsonDecode(datos ?? '[]') as List)
          .map(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        categoriasRegistradas = lista;
        torneoSeleccionado = null;
        categoriaIdSeleccionada = null;
        cargandoCategorias = false;
        errorCategorias = null;
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
  // OBTENER TORNEOS SIN DUPLICADOS
  // ==========================================

  List<String> get torneosDisponibles {
    final mapa = <String, String>{};

    for (final registro in categoriasRegistradas) {
      final torneo =
          registro['torneo']?.toString().trim() ?? '';

      if (torneo.isEmpty) continue;

      mapa.putIfAbsent(
        normalizar(torneo),
            () => torneo,
      );
    }

    final lista = mapa.values.toList();

    lista.sort(
          (a, b) => normalizar(a).compareTo(
        normalizar(b),
      ),
    );

    return lista;
  }

  // ==========================================
  // CATEGORÍAS DEL TORNEO SELECCIONADO
  // ==========================================

  List<Map<String, dynamic>> get categoriasDisponibles {
    if (torneoSeleccionado == null) {
      return [];
    }

    final lista = categoriasRegistradas.where(
          (registro) {
        final torneo =
            registro['torneo']?.toString() ?? '';

        return normalizar(torneo) ==
            normalizar(torneoSeleccionado!);
      },
    ).toList();

    lista.sort((a, b) {
      final primera =
          a['categoria']?.toString() ?? '';

      final segunda =
          b['categoria']?.toString() ?? '';

      return normalizar(primera).compareTo(
        normalizar(segunda),
      );
    });

    return lista;
  }

  // ==========================================
  // CAMBIAR TORNEO
  // ==========================================

  void cambiarTorneo(String? torneo) {
    setState(() {
      torneoSeleccionado = torneo;

      // Evita conservar una categoría
      // que pertenezca a otro torneo.
      categoriaIdSeleccionada = null;
    });
  }

  // ==========================================
  // DISEÑO DE LOS SELECTORES
  // TIPOGRAFÍA IGUAL A "JUGADOR 1"
  // ==========================================

  InputDecoration decoracionSelector({
    required String titulo,
    required IconData icono,
  }) {
    return InputDecoration(
      labelText: titulo,

      floatingLabelBehavior:
      FloatingLabelBehavior.always,

      // LETRAS NEGRAS Y GRUESAS
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
        horizontal: 10,
        vertical: 15,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFD9B48F),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: ArenaColores.rojo,
          width: 1.6,
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
        'Selecciona torneo',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
        ),
      ),

      items: torneosDisponibles.map((torneo) {
        return DropdownMenuItem<String>(
          value: torneo,
          child: Text(
            torneo,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        );
      }).toList(),

      onChanged: guardando || cargandoCategorias
          ? null
          : cambiarTorneo,
    );
  }

  // ==========================================
  // SELECTOR DE CATEGORÍA
  // ==========================================

  Widget selectorCategoria() {
    final disponibles = categoriasDisponibles;

    return DropdownButtonFormField<String>(
      key: ValueKey(
        'categoria_${torneoSeleccionado ?? "ninguno"}',
      ),

      initialValue: categoriaIdSeleccionada,
      isExpanded: true,

      decoration: decoracionSelector(
        titulo: 'CATEGORÍA *',
        icono: Icons.groups_rounded,
      ),

      hint: const Text(
        'Selecciona categoría',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
        ),
      ),

      items: disponibles.map((registro) {
        final id =
            registro['id']?.toString() ?? '';

        final categoria =
            registro['categoria']?.toString() ?? '';

        return DropdownMenuItem<String>(
          value: id,
          child: Text(
            categoria,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        );
      }).toList(),

      onChanged: guardando ||
          cargandoCategorias ||
          torneoSeleccionado == null ||
          disponibles.isEmpty
          ? null
          : (String? valor) {
        setState(() {
          categoriaIdSeleccionada = valor;
        });
      },
    );
  }

  // ==========================================
  // TÍTULO DATOS DEL EQUIPO
  // ==========================================

  Widget tituloDatosEquipo() {
    return const Row(
      children: [
        Icon(
          Icons.shield,
          color: ArenaColores.rojo,
        ),

        SizedBox(width: 10),

        Flexible(
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
    );
  }

  // ==========================================
  // CABECERA CON DOS SELECTORES
  // ==========================================

  Widget cabeceraDatosEquipo() {
    return LayoutBuilder(
      builder: (context, espacio) {
        if (espacio.maxWidth >= 790) {
          return Row(
            children: [
              Expanded(
                child: tituloDatosEquipo(),
              ),

              const SizedBox(width: 12),

              SizedBox(
                width: 210,
                child: selectorTorneo(),
              ),

              const SizedBox(width: 12),

              SizedBox(
                width: 210,
                child: selectorCategoria(),
              ),
            ],
          );
        }

        // En celular se colocan debajo del título.
        return Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            tituloDatosEquipo(),

            const SizedBox(height: 20),

            selectorTorneo(),

            const SizedBox(height: 15),

            selectorCategoria(),
          ],
        );
      },
    );
  }

  // ==========================================
  // VALIDAR JUGADORES
  // ==========================================

  List<Map<String, dynamic>>? obtenerJugadores() {
    final jugadores = <Map<String, dynamic>>[];
    final numerosRegistrados = <int>{};

    for (int i = 0; i < maxJugadores; i++) {
      final textoNumero = numeros[i].text.trim();
      final textoNombre = nombres[i].text.trim();

      if (textoNumero.isEmpty &&
          textoNombre.isEmpty) {
        continue;
      }

      if (textoNumero.isEmpty ||
          textoNombre.isEmpty) {
        mostrarMensaje(
          'Completa el número y nombre '
              'del jugador ${i + 1}',
        );
        return null;
      }

      final numero = int.tryParse(textoNumero);

      if (numero == null ||
          numero < 1 ||
          numero > 99) {
        mostrarMensaje(
          'El número del jugador ${i + 1} '
              'debe estar entre 1 y 99',
        );
        return null;
      }

      if (numerosRegistrados.contains(numero)) {
        mostrarMensaje(
          'El número $numero está repetido',
        );
        return null;
      }

      numerosRegistrados.add(numero);

      jugadores.add({
        'numero': numero,
        'nombre': textoNombre,
      });
    }

    if (jugadores.isEmpty) {
      mostrarMensaje(
        'Registra al menos un jugador',
      );
      return null;
    }

    return jugadores;
  }

  // ==========================================
  // GUARDAR EQUIPO
  // ==========================================

  Future<void> guardarEquipo() async {
    if (guardando || cargandoCategorias) return;

    final nombre = nombreEquipo.text.trim();

    if (nombre.isEmpty) {
      mostrarMensaje(
        'Escribe el nombre del equipo',
      );
      return;
    }

    if (torneoSeleccionado == null) {
      mostrarMensaje(
        'Debes seleccionar un torneo',
      );
      return;
    }

    if (categoriaIdSeleccionada == null) {
      mostrarMensaje(
        'Debes seleccionar una categoría',
      );
      return;
    }

    final jugadores = obtenerJugadores();

    if (jugadores == null) return;

    setState(() {
      guardando = true;
    });

    try {
      final prefs = SharedPreferencesAsync();

      // Comprobar que la categoría siga
      // disponible en los datos guardados.
      final datosCategorias =
      await prefs.getString(
        claveCategorias,
      );

      final listaCategorias =
      (jsonDecode(datosCategorias ?? '[]') as List)
          .map(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

      Map<String, dynamic>? seleccion;

      for (final registro in listaCategorias) {
        final id =
            registro['id']?.toString() ?? '';

        final torneo =
            registro['torneo']?.toString() ?? '';

        if (id == categoriaIdSeleccionada &&
            normalizar(torneo) ==
                normalizar(torneoSeleccionado!)) {
          seleccion = registro;
          break;
        }
      }

      if (seleccion == null) {
        mostrarMensaje(
          'La categoría seleccionada '
              'ya no está disponible',
        );
        return;
      }

      final torneo =
          seleccion['torneo']?.toString().trim() ??
              '';

      final categoria =
          seleccion['categoria']
              ?.toString()
              .trim() ??
              '';

      if (torneo.isEmpty || categoria.isEmpty) {
        mostrarMensaje(
          'El torneo o la categoría no son válidos',
        );
        return;
      }

      // Cargar los equipos anteriores.
      final datosEquipos =
      await prefs.getString('equipos');

      final equipos =
      (jsonDecode(datosEquipos ?? '[]') as List)
          .map(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

      // Permitir nombres iguales en
      // torneos o categorías diferentes.
      final existe = equipos.any((equipo) {
        final nombreExistente =
            equipo['nombre']?.toString() ?? '';

        final torneoExistente =
            equipo['torneo']?.toString() ?? '';

        final categoriaExistente =
            equipo['categoria']?.toString() ?? '';

        return normalizar(nombreExistente) ==
            normalizar(nombre) &&
            normalizar(torneoExistente) ==
                normalizar(torneo) &&
            normalizar(categoriaExistente) ==
                normalizar(categoria);
      });

      if (existe) {
        mostrarMensaje(
          'Ya existe "$nombre" en $torneo, '
              'categoría $categoria',
        );
        return;
      }

      final ahora = DateTime.now();

      equipos.add({
        'id': ahora.microsecondsSinceEpoch.toString(),
        'nombre': nombre,
        'torneo': torneo,
        'categoria': categoria,
        'categoriaId':
        seleccion['id']?.toString(),
        'jugadores': jugadores,
      });

      await prefs.setString(
        'equipos',
        jsonEncode(equipos),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      mostrarMensaje(
        'No se pudo guardar el equipo: $e',
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
  // TARJETA DE CADA JUGADOR
  // ==========================================

  Widget crearCampoJugador(int indice) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE4C5A6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
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
  // ENCABEZADO DE LA PANTALLA
  // ==========================================

  Widget crearEncabezado() {
    return Column(
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 55,
          color: ArenaColores.dorado,
        ),

        const SizedBox(height: 12),

        const ArenaTextoMetalico(
          texto: 'REGISTRO DE EQUIPO',
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
            'Selecciona el torneo y la categoría. '
                'Registra hasta 20 jugadores. '
                'No es obligatorio llenar todos '
                'los espacios.',
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
  // FORMULARIO PRINCIPAL
  // ==========================================

  Widget crearFormulario() {
    return ArenaPanel(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          // SELECTORES EN LA CABECERA
          cabeceraDatosEquipo(),

          if (cargandoCategorias) ...[
            const SizedBox(height: 12),

            const Center(
              child: CircularProgressIndicator(
                color: ArenaColores.rojo,
              ),
            ),
          ],

          if (errorCategorias != null) ...[
            const SizedBox(height: 12),

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

          if (!cargandoCategorias &&
              categoriasRegistradas.isEmpty &&
              errorCategorias == null) ...[
            const SizedBox(height: 12),

            const Text(
              'No hay categorías registradas. '
                  'Primero registra un torneo y '
                  'su categoría en AGREGAR CATEGORÍA.',
              style: TextStyle(
                color: ArenaColores.rojo,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],

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

          const SizedBox(height: 26),

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
                  'PLANTILLA DE JUGADORES (1-20)',
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

          // PLANTILLA ORIGINAL DE 20 JUGADORES
          LayoutBuilder(
            builder: (context, espacio) {
              final ancho = espacio.maxWidth;

              if (ancho < 700) {
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
                  (ancho - separacion) / 2;

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

          // ==================================
          // GUARDAR EQUIPO
          // ==================================

          SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed:
              guardando || cargandoCategorias
                  ? null
                  : guardarEquipo,
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
                    : 'GUARDAR EQUIPO',
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
  // PANTALLA COMPLETA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'AGREGAR EQUIPO',
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
