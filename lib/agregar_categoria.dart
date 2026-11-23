
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';

// ==========================================
// AGREGAR CATEGORÍA - ARENA MOUSTACHE
// ==========================================

class AgregarCategoria extends StatefulWidget {
  const AgregarCategoria({super.key});

  @override
  State<AgregarCategoria> createState() =>
      _AgregarCategoriaState();
}

class _AgregarCategoriaState
    extends State<AgregarCategoria> {
  static const String claveCategorias =
      'torneos_categorias';

  final TextEditingController torneoController =
  TextEditingController();

  final TextEditingController categoriaController =
  TextEditingController();

  List<Map<String, dynamic>> categorias = [];

  bool cargando = true;
  bool guardando = false;

  String? error;

  @override
  void initState() {
    super.initState();
    cargarCategorias();
  }

  @override
  void dispose() {
    torneoController.dispose();
    categoriaController.dispose();
    super.dispose();
  }

  // ==========================================
  // UTILIDADES
  // ==========================================

  String limpiar(String texto) {
    return texto.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }

  String normalizar(String texto) {
    return limpiar(texto).toLowerCase();
  }

  void mostrarMensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
      ),
    );
  }

  bool existeCategoria(
      List<Map<String, dynamic>> lista,
      String torneo,
      String categoria,
      ) {
    return lista.any((registro) {
      final torneoGuardado =
          registro['torneo']?.toString() ?? '';

      final categoriaGuardada =
          registro['categoria']?.toString() ?? '';

      return normalizar(torneoGuardado) ==
          normalizar(torneo) &&
          normalizar(categoriaGuardada) ==
              normalizar(categoria);
    });
  }

  // ==========================================
  // CARGAR CATEGORÍAS
  // ==========================================

  Future<void> cargarCategorias() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final texto = await prefs.getString(
        claveCategorias,
      );

      final lista =
      (jsonDecode(texto ?? '[]') as List)
          .map(
            (elemento) =>
        Map<String, dynamic>.from(
          elemento as Map,
        ),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        categorias = lista;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = 'Error al cargar categorías: $e';
      });
    }
  }

  // ==========================================
  // GUARDAR CATEGORÍA
  // ==========================================

  Future<void> guardarCategoria() async {
    if (guardando || cargando) return;

    final torneo = limpiar(
      torneoController.text,
    );

    final categoria = limpiar(
      categoriaController.text,
    );

    if (torneo.isEmpty) {
      mostrarMensaje(
        'Escribe el nombre del torneo.',
      );
      return;
    }

    if (categoria.isEmpty) {
      mostrarMensaje(
        'Escribe la categoría.',
      );
      return;
    }

    if (existeCategoria(
      categorias,
      torneo,
      categoria,
    )) {
      mostrarMensaje(
        'Esta categoría ya está registrada '
            'en ese torneo.',
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final prefs = SharedPreferencesAsync();

      final textoActual = await prefs.getString(
        claveCategorias,
      );

      final listaActual =
      (jsonDecode(textoActual ?? '[]') as List)
          .map(
            (elemento) =>
        Map<String, dynamic>.from(
          elemento as Map,
        ),
      )
          .toList();

      if (existeCategoria(
        listaActual,
        torneo,
        categoria,
      )) {
        if (!mounted) return;

        setState(() {
          categorias = listaActual;
        });

        mostrarMensaje(
          'Esta categoría ya está registrada '
              'en ese torneo.',
        );
        return;
      }

      final ahora = DateTime.now();

      final nuevaCategoria = <String, dynamic>{
        'id': ahora.microsecondsSinceEpoch.toString(),
        'torneo': torneo,
        'categoria': categoria,
        'creadaEn': ahora.toIso8601String(),
      };

      listaActual.add(nuevaCategoria);

      await prefs.setString(
        claveCategorias,
        jsonEncode(listaActual),
      );

      if (!mounted) return;

      setState(() {
        categorias = listaActual;

        // Conservamos el torneo para registrar
        // varias categorías del mismo torneo.
        categoriaController.clear();
      });

      mostrarMensaje(
        'Categoría "$categoria" guardada '
            'en "$torneo".',
      );
    } catch (e) {
      mostrarMensaje(
        'No se pudo guardar la categoría: $e',
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
  // PANEL METÁLICO
  // ==========================================

  Widget panelMetalico({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xCCFFD36B),
          width: 1.2,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF0382021),
            Color(0xF0181012),
            Color(0xF00B0809),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ==========================================
  // CAMPO DEL FORMULARIO
  // ==========================================

  Widget campoFormulario({
    required String titulo,
    required String ayuda,
    required IconData icono,
    required TextEditingController controller,
    TextInputAction accion = TextInputAction.next,
    VoidCallback? alEnviar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(width: 5),

            const Text(
              '*',
              style: TextStyle(
                color: ArenaColores.rojo,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          enabled: !guardando,
          textCapitalization: TextCapitalization.words,
          textInputAction: accion,
          onSubmitted: (_) {
            alEnviar?.call();
          },
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          cursorColor: ArenaColores.dorado,
          decoration: InputDecoration(
            hintText: ayuda,
            hintStyle: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icono,
              color: ArenaColores.dorado,
            ),
            filled: true,
            fillColor: const Color(0xFF24191B),
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFAA8542),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ArenaColores.dorado,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTONES
  // ==========================================

  Widget botonesAccion() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          height: 46,
          width: 150,
          child: OutlinedButton.icon(
            onPressed: guardando
                ? null
                : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('CANCELAR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: ArenaColores.rojo,
                width: 1.5,
              ),
              backgroundColor:
              const Color(0xFF250F11),
            ),
          ),
        ),

        SizedBox(
          height: 46,
          width: 232,
          child: ElevatedButton.icon(
            onPressed: guardando
                ? null
                : guardarCategoria,
            icon: Icon(
              guardando
                  ? Icons.hourglass_top
                  : Icons.save,
            ),
            label: Text(
              guardando
                  ? 'GUARDANDO...'
                  : 'GUARDAR CATEGORÍA',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF38220F),
              foregroundColor: ArenaColores.dorado,
              disabledForegroundColor:
              Colors.white54,
              side: const BorderSide(
                color: ArenaColores.dorado,
                width: 1.5,
              ),
              elevation: 5,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // LISTA DE CATEGORÍAS GUARDADAS
  // ==========================================

  Widget listaCategorias() {
    return panelMetalico(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.list_alt,
                color: ArenaColores.dorado,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'CATEGORÍAS REGISTRADAS',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: ArenaColores.dorado,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (categorias.isEmpty)
            const Text(
              'Todavía no hay categorías guardadas.',
              style: TextStyle(
                color: Colors.white70,
              ),
            )
          else
            ...categorias.reversed.map((registro) {
              final torneo =
                  registro['torneo']?.toString() ?? '';

              final categoria =
                  registro['categoria']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF271B1E),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF67512F),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: ArenaColores.dorado,
                        size: 22,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              torneo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Categoría: $categoria',
                              style: const TextStyle(
                                color: ArenaColores.dorado,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF90CF97),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ArenaBarraSuperior(
        titulo: 'AGREGAR CATEGORÍA',
      ),

      body: ArenaFondo(
        child: cargando
            ? const Center(
          child: CircularProgressIndicator(
            color: ArenaColores.dorado,
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 760,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),

                  panelMetalico(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: ArenaColores.dorado,
                          size: 44,
                        ),

                        const SizedBox(height: 10),

                        const ArenaTextoMetalico(
                          texto: 'NUEVA CATEGORÍA',
                          tamano: 24,
                          dorado: true,
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Registra una categoría '
                              'y el torneo al que pertenece.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 25),

                        campoFormulario(
                          titulo: 'TORNEO',
                          ayuda: 'Ej. Apertura 2026',
                          icono: Icons.emoji_events,
                          controller:
                          torneoController,
                        ),

                        const SizedBox(height: 20),

                        campoFormulario(
                          titulo: 'CATEGORÍA',
                          ayuda:
                          'Ej. A, B, 2015, Sub-17',
                          icono: Icons.groups_rounded,
                          controller:
                          categoriaController,
                          accion: TextInputAction.done,
                          alEnviar: guardarCategoria,
                        ),

                        const SizedBox(height: 13),

                        const Text(
                          'Puedes registrar varias '
                              'categorías para un mismo torneo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 28),

                        botonesAccion(),
                      ],
                    ),
                  ),

                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  listaCategorias(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
