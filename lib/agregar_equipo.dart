
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';

// ==========================================
// PANTALLA AGREGAR EQUIPO
// ESTILO ARENA MOUSTACHE
// ==========================================

class AgregarEquipo extends StatefulWidget {
  const AgregarEquipo({super.key});

  @override
  State<AgregarEquipo> createState() =>
      _AgregarEquipoState();
}

class _AgregarEquipoState extends State<AgregarEquipo> {
  static const int maxJugadores = 20;

  final nombreEquipo = TextEditingController();

  final numeros = List.generate(
    maxJugadores,
        (_) => TextEditingController(),
  );

  final nombres = List.generate(
    maxJugadores,
        (_) => TextEditingController(),
  );

  bool guardando = false;

  // ==========================================
  // MOSTRAR MENSAJES
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
  // OBTENER Y VALIDAR JUGADORES
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
    if (guardando) return;

    final nombre = nombreEquipo.text.trim();

    if (nombre.isEmpty) {
      mostrarMensaje(
        'Escribe el nombre del equipo',
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

      final datos = await prefs.getString('equipos');

      final equipos = (jsonDecode(datos ?? '[]') as List)
          .map(
            (e) => Map<String, dynamic>.from(e as Map),
      )
          .toList();

      final existe = equipos.any(
            (equipo) =>
        equipo['nombre']
            .toString()
            .trim()
            .toLowerCase() ==
            nombre.toLowerCase(),
      );

      if (existe) {
        mostrarMensaje(
          'Ya existe un equipo con ese nombre',
        );
        return;
      }

      equipos.add({
        'id': DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        'nombre': nombre,
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
  // DISEÑO DE CADA JUGADOR
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
          width: 1,
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
  // ENCABEZADO DE REGISTRO
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
  // FORMULARIO DEL EQUIPO
  // ==========================================

  Widget crearFormulario() {
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

          // Distribución adaptable:
          // una columna en celular,
          // dos columnas en pantallas grandes.
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

          // =================================
          // BOTÓN GUARDAR
          // =================================

          SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed:
              guardando ? null : guardarEquipo,
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
      // Barra negra con tipografía metálica.
      appBar: const ArenaBarraSuperior(
        titulo: 'AGREGAR EQUIPO',
      ),

      // Fondo de ladrillos de Arena Moustache.
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
