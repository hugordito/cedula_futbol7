
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_estilo.dart';

// ==========================================
// SELECTOR DE TORNEO Y CATEGORÍA
// ARENA MOUSTACHE
// ==========================================

class SelectorTorneoCategoria {

  // ==========================================
  // NORMALIZAR TEXTOS
  // ==========================================

  static String normalizar(String texto) {
    return texto
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  // ==========================================
  // MOSTRAR MENSAJES
  // ==========================================

  static void aviso(
      BuildContext context,
      String mensaje,
      ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  // ==========================================
  // SELECCIONAR TORNEO Y CATEGORÍA
  // ==========================================

  static Future<void> seleccionar({
    required BuildContext context,
    required Map<String, TextEditingController> campos,
    required VoidCallback onCamposActualizados,
    required bool desdeCategoria,
  }) async {

    List<Map<String, dynamic>> registros;

    // ========================================
    // CARGAR DATOS REGISTRADOS
    // ========================================

    try {
      final prefs = SharedPreferencesAsync();

      final texto = await prefs.getString(
        'torneos_categorias',
      );

      registros = (jsonDecode(texto ?? '[]') as List)
          .map(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

    } catch (e) {
      if (!context.mounted) return;

      aviso(
        context,
        'No se pudieron cargar los torneos: $e',
      );

      return;
    }

    if (!context.mounted) return;

    if (registros.isEmpty) {
      aviso(
        context,
        'Primero registra un torneo y una categoría.',
      );
      return;
    }

    // ========================================
    // OBTENER TORNEOS SIN DUPLICADOS
    // ========================================

    final mapaTorneos = <String, String>{};

    for (final registro in registros) {
      final torneo =
          registro['torneo']?.toString().trim() ?? '';

      if (torneo.isNotEmpty) {
        mapaTorneos.putIfAbsent(
          normalizar(torneo),
              () => torneo,
        );
      }
    }

    final torneos = mapaTorneos.values.toList()
      ..sort(
            (a, b) => normalizar(a).compareTo(
          normalizar(b),
        ),
      );

    // ========================================
    // TORNEO ACTUAL
    // ========================================

    final anterior =
        campos['torneo']?.text.trim() ?? '';

    String? torneoElegido;

    // Si se toca directamente CATEGORÍA
    // y ya existe un torneo válido,
    // se utiliza ese torneo.
    //
    // De lo contrario se muestra primero
    // la lista de torneos.

    if (desdeCategoria &&
        anterior.isNotEmpty &&
        mapaTorneos.containsKey(
          normalizar(anterior),
        )) {

      torneoElegido = mapaTorneos[
      normalizar(anterior)
      ];

    } else {

      torneoElegido = await _elegirEnLista(
        context,
        titulo: 'SELECCIONAR TORNEO',
        subtitulo:
        'Torneos registrados en Arena Moustache',
        icono: Icons.emoji_events,
        opciones: torneos,
      );
    }

    if (!context.mounted ||
        torneoElegido == null) {
      return;
    }

    // ========================================
    // OBTENER CATEGORÍAS DEL TORNEO
    // ========================================

    final mapaCategorias = <String, String>{};

    for (final registro in registros) {

      final torneoRegistro =
          registro['torneo']?.toString() ?? '';

      if (normalizar(torneoRegistro) ==
          normalizar(torneoElegido)) {

        final categoria =
            registro['categoria']
                ?.toString()
                .trim() ??
                '';

        if (categoria.isNotEmpty) {
          mapaCategorias.putIfAbsent(
            normalizar(categoria),
                () => categoria,
          );
        }
      }
    }

    final categorias = mapaCategorias.values.toList()
      ..sort(
            (a, b) => normalizar(a).compareTo(
          normalizar(b),
        ),
      );

    // ========================================
    // ACTUALIZAR TORNEO
    // ========================================

    if (normalizar(anterior) !=
        normalizar(torneoElegido)) {

      campos['torneo']?.text = torneoElegido;

      // Eliminar la categoría anterior
      // cuando cambia el torneo.
      campos['categoria']?.clear();

      onCamposActualizados();
    }

    if (categorias.isEmpty) {
      aviso(
        context,
        'No hay categorías registradas en ese torneo.',
      );
      return;
    }

    // ========================================
    // ABRIR AUTOMÁTICAMENTE CATEGORÍAS
    // ========================================

    final categoriaElegida =
    await _elegirEnLista(
      context,
      titulo: 'SELECCIONAR CATEGORÍA',
      subtitulo: 'Torneo: $torneoElegido',
      icono: Icons.groups_rounded,
      opciones: categorias,
    );

    if (!context.mounted ||
        categoriaElegida == null) {
      return;
    }

    // ========================================
    // ACTUALIZAR DATOS DE LA CÉDULA
    // ========================================

    campos['torneo']?.text = torneoElegido;

    campos['categoria']?.text =
        categoriaElegida;

    onCamposActualizados();
  }

  // ==========================================
  // LISTA VISUAL DE SELECCIÓN
  // ==========================================

  static Future<String?> _elegirEnLista(
      BuildContext context, {
        required String titulo,
        required String subtitulo,
        required IconData icono,
        required List<String> opciones,
      }) {

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (modal) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
            MediaQuery.sizeOf(modal).height * 0.72,
          ),

          margin: const EdgeInsets.all(12),

          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            12,
          ),

          decoration: BoxDecoration(
            color: ArenaColores.negro,
            borderRadius:
            BorderRadius.circular(18),

            border: Border.all(
              color: ArenaColores.dorado,
              width: 1.5,
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ICONO PRINCIPAL

              Icon(
                icono,
                color: ArenaColores.dorado,
                size: 32,
              ),

              const SizedBox(height: 8),

              // TÍTULO

              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ArenaColores.dorado,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 6),

              // SUBTÍTULO

              Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 14),

              // LISTA DE OPCIONES

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: opciones.length,

                  separatorBuilder: (
                      context,
                      index,
                      ) {
                    return const SizedBox(
                      height: 7,
                    );
                  },

                  itemBuilder: (
                      context,
                      indice,
                      ) {

                    final opcion =
                    opciones[indice];

                    return Material(
                      color: const Color(0xFF302022),

                      borderRadius:
                      BorderRadius.circular(10),

                      child: ListTile(
                        leading: Icon(
                          icono,
                          color: ArenaColores.dorado,
                        ),

                        title: Text(
                          opcion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),

                        trailing: const Icon(
                          Icons.chevron_right,
                          color: ArenaColores.dorado,
                        ),

                        onTap: () {
                          Navigator.pop(
                            modal,
                            opcion,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // CANCELAR

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(modal);
                },

                icon: const Icon(
                  Icons.close,
                ),

                label: const Text(
                  'CANCELAR',
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,

                  side: const BorderSide(
                    color: ArenaColores.rojo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
