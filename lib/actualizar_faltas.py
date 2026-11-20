
from pathlib import Path
import re
import sys

CARPETA = Path("lib")

RUTAS = {
    "hoja": CARPETA / "cedula_tactil.dart",
    "nueva": CARPETA / "nueva_cedula.dart",
    "historial": CARPETA / "historial_cedulas.dart",
}


def cambiar(texto, original, nuevo, nombre):
    cantidad = texto.count(original)
    if cantidad != 1:
        raise ValueError(
            f"{nombre}: esperaba 1 coincidencia, encontré {cantidad}"
        )
    return texto.replace(original, nuevo, 1)


def cambiar_patron(texto, patron, nuevo, nombre):
    resultado, cantidad = re.subn(
        patron, nuevo, texto, count=1, flags=re.S
    )
    if cantidad != 1:
        raise ValueError(
            f"{nombre}: no encontré el fragmento esperado"
        )
    return resultado


def actualizar_hoja(texto):
    texto = cambiar(
        texto,
        "  final List<Map<String, dynamic>> shootouts;\n",
        """  final List<Map<String, dynamic>> shootouts;
  final List<Map<String, dynamic>> faltasBloques;
  final List<Map<String, dynamic>> marcasVisuales;
""",
        "Hoja: datos",
    )

    texto = cambiar(
        texto,
        "  final Future<void> Function() onEditarShootouts;\n",
        """  final Future<void> Function() onEditarShootouts;
  final ValueChanged<List<Map<String, dynamic>>>
      onFaltasBloquesActualizadas;
  final ValueChanged<List<Map<String, dynamic>>>
      onMarcasVisualesActualizadas;
""",
        "Hoja: callbacks",
    )

    texto = cambiar(
        texto,
        "    required this.shootouts,\n",
        """    required this.shootouts,
    required this.faltasBloques,
    required this.marcasVisuales,
""",
        "Hoja: constructor de datos",
    )

    texto = cambiar(
        texto,
        "    required this.onEditarShootouts,\n",
        """    required this.onEditarShootouts,
    required this.onFaltasBloquesActualizadas,
    required this.onMarcasVisualesActualizadas,
""",
        "Hoja: constructor de callbacks",
    )

    texto = cambiar_patron(
        texto,
        r"  // Datos temporales de las nuevas casillas\..*?"
        r"(?=  static const List<String> clavesFirmas = \[)",
        "",
        "Hoja: quitar estado temporal",
    )

    texto = cambiar(
        texto,
        "final nuevasFaltas = faltasBloques.where(",
        "final nuevasFaltas = widget.faltasBloques.where(",
        "Hoja: contador",
    )

    texto = cambiar(
        texto,
        "faltas: faltasBloques,",
        "faltas: widget.faltasBloques,",
        "Hoja: mostrar faltas",
    )

    texto = cambiar(
        texto,
        "marcasVisuales: marcasVisuales,",
        "marcasVisuales: widget.marcasVisuales,",
        "Hoja: mostrar X",
    )

    texto = cambiar_patron(
        texto,
        r"onFaltasActualizadas:\s*actualizarFaltasBloques,",
        "onFaltasActualizadas: "
        "widget.onFaltasBloquesActualizadas,",
        "Hoja: actualizar faltas",
    )

    texto = cambiar_patron(
        texto,
        r"onMarcasActualizadas:\s*actualizarMarcasVisuales,",
        "onMarcasActualizadas: "
        "widget.onMarcasVisualesActualizadas,",
        "Hoja: actualizar X",
    )

    return texto


def actualizar_nueva(texto):
    texto = cambiar(
        texto,
        "  List<Map<String, dynamic>> shootouts = [];\n",
        """  List<Map<String, dynamic>> shootouts = [];
  List<Map<String, dynamic>> faltasBloques = [];
  List<Map<String, dynamic>> marcasVisuales = [];
""",
        "Nueva: listas",
    )

    texto = cambiar_patron(
        texto,
        r"  int contar\(String lado, String tipo\) \{.*?\n  \}",
        """  int contar(String lado, String tipo) {
    final eventosContados = eventos.where(
      (item) => item['lado'] == lado && item['tipo'] == tipo,
    ).length;

    if (tipo != 'falta') return eventosContados;

    return eventosContados +
        faltasBloques.where(
          (item) => item['lado'] == lado,
        ).length;
  }""",
        "Nueva: contador",
    )

    texto = cambiar(
        texto,
        "          shootouts = [];\n",
        """          shootouts = [];
          faltasBloques = [];
          marcasVisuales = [];
""",
        "Nueva: cambiar equipos",
    )

    texto = cambiar(
        texto,
        "        'shootouts': shootouts,\n",
        """        'shootouts': shootouts,
        'faltasBloques': faltasBloques,
        'marcasVisuales': marcasVisuales,
""",
        "Nueva: guardar datos",
    )

    texto = cambiar_patron(
        texto,
        r"(\s+shootouts: shootouts,)(\s+firmas: firmas,)",
        r"\1\n"
        r"               faltasBloques: faltasBloques,\n"
        r"               marcasVisuales: marcasVisuales,\2",
        "Nueva: pasar datos a hoja",
    )

    texto = cambiar(
        texto,
        "onCamposActualizados: () {",
        """onFaltasBloquesActualizadas: (nuevas) {
                 setState(() {
                   faltasBloques = nuevas;
                 });
               },
               onMarcasVisualesActualizadas: (nuevas) {
                 setState(() {
                   marcasVisuales = nuevas;
                 });
               },
               onCamposActualizados: () {""",
        "Nueva: recibir cambios",
    )

    return texto


def actualizar_historial(texto):
    texto = cambiar(
        texto,
        "  late final List<Map<String, dynamic>> shootouts;\n",
        """  late final List<Map<String, dynamic>> shootouts;
  late final List<Map<String, dynamic>> faltasBloques;
  late final List<Map<String, dynamic>> marcasVisuales;
""",
        "Historial: listas",
    )

    texto = cambiar_patron(
        texto,
        r"(    shootouts = convertirLista\(\s*"
        r"guardada\['shootouts'\],\s*\);)",
        r"\1\n"
        r"    faltasBloques = convertirLista("
        r"guardada['faltasBloques']);\n"
        r"    marcasVisuales = convertirLista("
        r"guardada['marcasVisuales']);",
        "Historial: recuperar datos",
    )

    texto = cambiar(
        texto,
        "            shootouts: shootouts,\n",
        """            shootouts: shootouts,
            faltasBloques: faltasBloques,
            marcasVisuales: marcasVisuales,
""",
        "Historial: mostrar bloques",
    )

    texto = cambiar(
        texto,
        "onEventosActualizados: (_) {},",
        """onEventosActualizados: (_) {},
             onFaltasBloquesActualizadas: (_) {},
             onMarcasVisualesActualizadas: (_) {},""",
        "Historial: solo lectura",
    )

    return texto


def main():
    try:
        anteriores = {}

        for nombre, ruta in RUTAS.items():
            if not ruta.is_file():
                raise FileNotFoundError(f"Falta {ruta}")

            anteriores[nombre] = ruta.read_text(
                encoding="utf-8"
            )

        # Preparar los tres archivos antes de
        # modificar cualquiera de ellos.
        nuevos = {
            "hoja": actualizar_hoja(anteriores["hoja"]),
            "nueva": actualizar_nueva(anteriores["nueva"]),
            "historial": actualizar_historial(
                anteriores["historial"]
            ),
        }

        for nombre, ruta in RUTAS.items():
            copia = ruta.with_suffix(".dart.bak_faltas")
            if copia.exists():
                raise FileExistsError(
                    f"Ya existe el respaldo {copia}"
                )

        for nombre, ruta in RUTAS.items():
            copia = ruta.with_suffix(".dart.bak_faltas")
            copia.write_text(
                anteriores[nombre],
                encoding="utf-8",
            )

        for nombre, ruta in RUTAS.items():
            ruta.write_text(
                nuevos[nombre],
                encoding="utf-8",
            )
            print(f"Actualizado: {ruta}")

        print("Listo. Ejecuta flutter analyze.")

    except Exception as error:
        print(
            f"No se pudo completar: {error}",
            file=sys.stderr,
        )
        print(
            "No sigas modificando archivos; "
            "comparte este mensaje."
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
