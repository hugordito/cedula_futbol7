
import 'package:material_ui/material_ui.dart';

import 'agregar_equipo.dart';
import 'editar_equipo.dart';
import 'cargar_equipo.dart';
import 'nueva_cedula.dart';
import 'historial_cedulas.dart';

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

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  Future<void> abrirPantalla(
      BuildContext context,
      String opcion,
      ) async {
    if (opcion == 'AGREGAR EQUIPO') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) =>
          const AgregarEquipo(),
        ),
      );
    } else if (opcion == 'EDITAR EQUIPO') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) =>
          const EditarEquipo(),
        ),
      );
    } else if (opcion == 'CARGAR EQUIPO') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) =>
          const CargarEquipo(),
        ),
      );
    } else if (opcion == 'CREAR NUEVA CÉDULA') {
      final guardado =
      await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (context) =>
          const NuevaCedula(),
        ),
      );

      if (guardado == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Borrador guardado correctamente',
            ),
          ),
        );
      }
    } else if (opcion == 'HISTORIAL') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) =>
          const HistorialCedulas(),
        ),
      );
    }
  }

  Widget crearBoton(
      BuildContext context,
      String texto,
      IconData icono,
      Color color,
      double ancho,
      ) {
    return SizedBox(
      width: ancho,
      height: 105,
      child: ElevatedButton(
        onPressed: () => abrirPantalla(
          context,
          texto,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(icono, size: 30),

            const SizedBox(height: 10),

            Text(
              texto,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CÉDULA FÚTBOL 7'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: LayoutBuilder(
        builder: (context, pantalla) {
          final esTablet =
              pantalla.maxWidth >= 600;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: ListView(
                padding: EdgeInsets.all(
                  esTablet ? 28 : 18,
                ),
                children: [
                  const SizedBox(height: 20),

                  const Icon(
                    Icons.sports_soccer,
                    size: 85,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'GESTIÓN DE EQUIPOS Y PARTIDOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Administra equipos, registra partidos '
                        'y prepara tus cédulas digitales.',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 35),

                  LayoutBuilder(
                    builder: (context, espacio) {
                      final ancho =
                          espacio.maxWidth;

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
                          (ancho -
                              (columnas - 1) *
                                  separacion) /
                              columnas;

                      return Wrap(
                        spacing: separacion,
                        runSpacing: separacion,
                        children: [
                          crearBoton(
                            context,
                            'AGREGAR EQUIPO',
                            Icons.add_circle,
                            Colors.green,
                            anchoBoton,
                          ),

                          crearBoton(
                            context,
                            'EDITAR EQUIPO',
                            Icons.edit,
                            Colors.blue,
                            anchoBoton,
                          ),

                          crearBoton(
                            context,
                            'CARGAR EQUIPO',
                            Icons.folder_open,
                            Colors.deepPurple,
                            anchoBoton,
                          ),

                          crearBoton(
                            context,
                            'CREAR NUEVA CÉDULA',
                            Icons.note_add,
                            Colors.deepOrange,
                            anchoBoton,
                          ),

                          crearBoton(
                            context,
                            'HISTORIAL',
                            Icons.history,
                            Colors.blueGrey,
                            anchoBoton,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 35),

                  const Center(
                    child: Text(
                      'Cédula Fútbol 7 · '
                          'Versión de desarrollo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
