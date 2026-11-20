
import 'package:material_ui/material_ui.dart';

// ==========================================
// COLORES OFICIALES ARENA MOUSTACHE
// ==========================================

class ArenaColores {
  static const Color negro = Color(0xFF1B0505);
  static const Color rojo = Color(0xFFD21A12);
  static const Color dorado = Color(0xFFFFD36B);
  static const Color plateado = Color(0xFFE5E7EB);
}

// ==========================================
// TEXTO CON EFECTO METÁLICO
// ==========================================

class ArenaTextoMetalico extends StatelessWidget {
  final String texto;
  final double tamano;
  final bool dorado;
  final TextAlign alineacion;

  const ArenaTextoMetalico({
    super.key,
    required this.texto,
    this.tamano = 20,
    this.dorado = false,
    this.alineacion = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
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
        textAlign: alineacion,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: tamano,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
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
}

// ==========================================
// FONDO DE LADRILLOS ROJOS
// ==========================================

class ArenaFondo extends StatelessWidget {
  final Widget child;

  const ArenaFondo({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/ui/fondo_inicio.png',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sombreado ligero para ayudar
          // a distinguir los elementos.
          const ColoredBox(
            color: Color(0x26000000),
          ),

          child,
        ],
      ),
    );
  }
}

// ==========================================
// BARRA SUPERIOR METÁLICA
// ==========================================

class ArenaBarraSuperior extends StatelessWidget
    implements PreferredSizeWidget {
  final String titulo;

  const ArenaBarraSuperior({
    super.key,
    this.titulo = 'CÉDULA FÚTBOL 7',
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final ancho =
        MediaQuery.sizeOf(context).width;

    final compacto = ancho < 600;

    return AppBar(
      automaticallyImplyLeading: true,
      toolbarHeight: 65,
      backgroundColor: ArenaColores.negro,
      foregroundColor: Colors.white,
      titleSpacing: 12,
      title: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ArenaTextoMetalico(
                texto: titulo,
                tamano: compacto ? 15 : 21,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: ArenaTextoMetalico(
                texto: 'ARENA MOUSTACHE',
                tamano: compacto ? 15 : 23,
                dorado: true,
              ),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          color: ArenaColores.rojo,
        ),
      ),
    );
  }
}

// ==========================================
// PANEL BLANCO PARA FORMULARIOS
// ==========================================

class ArenaPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ArenaPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x66FFD36B),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
