import 'package:material_ui/material_ui.dart';

import 'agregar_equipo.dart';
import 'editar_equipo.dart';
import 'cargar_equipo.dart';
import 'nueva_cedula.dart';
import 'historial_cedulas.dart';

// ==========================================
// APLICACIÓN PRINCIPAL
// ==========================================

void main() {
  runApp(const CedulaFutbolApp());
}

class CedulaFutbolApp extends StatelessWidget {
  const CedulaFutbolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cédula Fútbol 7',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL ARENA MOUSTACHE
// ==========================================

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  static const String fondoInicio = 'assets/ui/fondo_inicio.png';
  static const String logoEmpresa = 'assets/ui/logo_arena_moustache.png';

  // ==========================================
  // TEXTO CON EFECTO METÁLICO
  // ==========================================

  Widget textoMetalico(
      String texto, {
        double fontSize = 20,
        bool dorado = false,
        TextAlign textAlign = TextAlign.center,
        int maxLines = 2,
      }) {
    final colores = dorado
        ? const [
      Color(0xFFFFF4C7),
      Color(0xFFFFCC55),
      Color(0xFFFFF1A0),
      Color(0xFFB87513),
    ]
        : const [
      Color(0xFFFFFFFF),
      Color(0xFFC9D0D8),
      Color(0xFFF6F8FA),
      Color(0xFFA9B2BC),
    ];

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colores,
        ).createShader(bounds);
      },
      child: Text(
        texto,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          height: 1.15,
          shadows: const [
            Shadow(
              color: Colors.black54,
              blurRadius: 3,
              offset: Offset(1, 2),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // NAVEGACIÓN
  // ==========================================

  Future<void> abrirPantalla(
      BuildContext context,
      String opcion,
      ) async {
    if (opcion == 'AGREGAR EQUIPO') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const AgregarEquipo(),
        ),
      );
    } else if (opcion == 'EDITAR EQUIPO') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const EditarEquipo(),
        ),
      );
    } else if (opcion == 'CARGAR EQUIPO') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const CargarEquipo(),
        ),
      );
    } else if (opcion == 'CREAR NUEVA CÉDULA') {
      final guardado = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (context) => const NuevaCedula(),
        ),
      );

      if (guardado == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Borrador guardado correctamente'),
          ),
        );
      }
    } else if (opcion == 'HISTORIAL') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const HistorialCedulas(),
        ),
      );
    }
  }

  // ==========================================
  // BOTONES
  // ==========================================

  Widget crearBoton(
      BuildContext context,
      String texto,
      IconData icono,
      Color acento,
      double ancho, {
        bool dorado = false,
      }) {
    return SizedBox(
      width: ancho,
      height: 105,
      child: Material(
        color: Colors.transparent,
        elevation: 7,
        shadowColor: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: acento,
              width: 1.5,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.35, 0.75, 1.0],
              colors: [
                Color(0xFF50302E),
                Color(0xFF2D1B1D),
                Color(0xFF170F12),
                Color(0xFF0E090B),
              ],
            ),
          ),
          child: InkWell(
            onTap: () => abrirPantalla(context, texto),
            splashColor: acento.withValues(alpha: 0.20),
            highlightColor: acento.withValues(alpha: 0.10),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 18,
                  right: 18,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          acento.withValues(alpha: 0),
                          acento.withValues(alpha: 0.85),
                          acento.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icono,
                          size: 30,
                          color: acento,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        textoMetalico(
                          texto,
                          fontSize: 14,
                          dorado: dorado,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BARRA SUPERIOR
  // ==========================================

  Widget crearBarraSuperior(BuildContext context) {
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    final esCompacto = anchoPantalla < 600;

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: textoMetalico(
                'CÉDULA FÚTBOL 7',
                fontSize: esCompacto ? 16 : 21,
                maxLines: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: textoMetalico(
                'ARENA MOUSTACHE',
                fontSize: esCompacto ? 16 : 23,
                dorado: true,
                maxLines: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // LOGO PRINCIPAL
  // ==========================================

  Widget crearLogoEmpresa() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 430,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 180,
          child: Image.asset(
            logoEmpresa,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'Logotipo de Arena Moustache',
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'ARENA MOUSTACHE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD36B),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // UI PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        backgroundColor: const Color(0xFF1B0505),
        foregroundColor: Colors.white,
        titleSpacing: 18,
        title: crearBarraSuperior(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            color: const Color(0xFFD21A12),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(fondoInicio),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, pantalla) {
            final esTablet = pantalla.maxWidth >= 600;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: ListView(
                  padding: EdgeInsets.all(esTablet ? 28 : 18),
                  children: [
                    const SizedBox(height: 4),

                    crearLogoEmpresa(),

                    const SizedBox(height: 4),

                    textoMetalico(
                      'GESTIÓN DE EQUIPOS Y PARTIDOS',
                      fontSize: esTablet ? 21 : 18,
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Administra equipos, registra partidos y prepara tus cédulas digitales.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    LayoutBuilder(
                      builder: (context, espacio) {
                        final ancho = espacio.maxWidth;

                        int columnas;
                        if (ancho >= 940) {
                          columnas = 3;
                        } else if (ancho >= 560) {
                          columnas = 2;
                        } else {
                          columnas = 1;
                        }

                        const separacion = 14.0;

                        final anchoBoton =
                            (ancho - (columnas - 1) * separacion) / columnas;

                        return Wrap(
                          spacing: separacion,
                          runSpacing: separacion,
                          children: [
                            crearBoton(
                              context,
                              'AGREGAR EQUIPO',
                              Icons.add_circle,
                              const Color(0xFFF2CD75),
                              anchoBoton,
                              dorado: true,
                            ),
                            crearBoton(
                              context,
                              'EDITAR EQUIPO',
                              Icons.edit,
                              const Color(0xFFDCE1E8),
                              anchoBoton,
                            ),
                            crearBoton(
                              context,
                              'CARGAR EQUIPO',
                              Icons.folder_open,
                              const Color(0xFFE7B55A),
                              anchoBoton,
                              dorado: true,
                            ),
                            crearBoton(
                              context,
                              'CREAR NUEVA CÉDULA',
                              Icons.note_add,
                              const Color(0xFFF47E70),
                              anchoBoton,
                            ),
                            crearBoton(
                              context,
                              'HISTORIAL',
                              Icons.history,
                              const Color(0xFFD9C8AF),
                              anchoBoton,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Cédula Fútbol 7 · Versión de desarrollo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}