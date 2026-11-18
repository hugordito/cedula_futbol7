
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
  State<RegistroShootouts> createState() =>
      _RegistroShootoutsState();
}

class _RegistroShootoutsState extends State<RegistroShootouts> {
  static const int maxIntentos = 8;

  late final List<Map<String, dynamic>> intentos;

  String lado = 'local';
  String resultado = 'gol';
  int? numeroJugador;

  @override
  void initState() {
    super.initState();

    intentos = widget.intentosIniciales
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> get equipoActual =>
      lado == 'local'
          ? widget.equipoLocal
          : widget.equipoVisitante;

  List<Map<String, dynamic>> get jugadoresActuales =>
      ((equipoActual['jugadores'] as List?) ?? [])
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
      )
          .toList();

  int cantidad(String equipo) {
    return intentos
        .where((item) => item['lado'] == equipo)
        .length;
  }

  int aciertos(String equipo) {
    return intentos
        .where(
          (item) =>
      item['lado'] == equipo &&
          item['resultado'] == 'gol',
    )
        .length;
  }

  void aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  void registrar() {
    if (cantidad(lado) >= maxIntentos) {
      aviso('Solo se permiten 8 intentos por equipo');
      return;
    }

    if (numeroJugador == null) {
      aviso('Selecciona el jugador');
      return;
    }

    final coincidencias = jugadoresActuales.where(
          (jugador) =>
      int.tryParse(jugador['numero'].toString()) ==
          numeroJugador,
    );

    if (coincidencias.isEmpty) {
      aviso('Selecciona un jugador válido');
      return;
    }

    final jugador = coincidencias.first;

    setState(() {
      intentos.add({
        'lado': lado,
        'equipoId': equipoActual['id'].toString(),
        'numero': numeroJugador,
        'jugador': jugador['nombre'].toString(),
        'resultado': resultado,
      });

      numeroJugador = null;
    });

    aviso('Shoot out registrado');
  }

  Widget panelEquipo(String equipo) {
    final datos = intentos
        .where((item) => item['lado'] == equipo)
        .toList();

    final nombre = equipo == 'local'
        ? widget.equipoLocal['nombre']
        : widget.equipoVisitante['nombre'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${equipo == 'local' ? 'LOCAL' : 'VISITANTE'}: $nombre',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Aciertos: ${aciertos(equipo)} '
                  'de ${datos.length}',
            ),

            const Divider(),

            if (datos.isEmpty)
              const Text('Sin intentos registrados'),

            for (int i = 0; i < datos.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  '${i + 1}. #${datos[i]['numero']} '
                      '${datos[i]['jugador']}',
                ),
                subtitle: Text(
                  datos[i]['resultado'] == 'gol'
                      ? 'GOL'
                      : 'FALLÓ',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar intento',
                  onPressed: () {
                    setState(() {
                      intentos.remove(datos[i]);
                    });
                  },
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
        title: const Text('SHOOT OUTS'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'DEFINICIÓN EN SHOOT OUT',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Registra hasta 8 intentos por equipo. '
                    'Estos goles se cuentan por separado '
                    'del marcador del partido.',
              ),

              const SizedBox(height: 18),

              const Text('Equipo'),

              DropdownButton<String>(
                value: lado,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'local',
                    child: Text(
                      'LOCAL: '
                          '${widget.equipoLocal['nombre']}',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'visitante',
                    child: Text(
                      'VISITANTE: '
                          '${widget.equipoVisitante['nombre']}',
                    ),
                  ),
                ],
                onChanged: (valor) {
                  if (valor == null) return;

                  setState(() {
                    lado = valor;
                    numeroJugador = null;
                  });
                },
              ),

              const SizedBox(height: 8),

              const Text('Jugador'),

              DropdownButton<int>(
                value: numeroJugador,
                isExpanded: true,
                hint: const Text(
                  'Selecciona un jugador',
                ),
                items: jugadoresActuales.map((jugador) {
                  final numero = int.parse(
                    jugador['numero'].toString(),
                  );

                  return DropdownMenuItem<int>(
                    value: numero,
                    child: Text(
                      '#$numero - ${jugador['nombre']}',
                    ),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    numeroJugador = valor;
                  });
                },
              ),

              const SizedBox(height: 8),

              const Text('Resultado'),

              DropdownButton<String>(
                value: resultado,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'gol',
                    child: Text('Gol'),
                  ),
                  DropdownMenuItem(
                    value: 'fallo',
                    child: Text('Falló'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() {
                      resultado = valor;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed:
                cantidad(lado) >= maxIntentos
                    ? null
                    : registrar,
                icon: const Icon(Icons.add),
                label: const Text(
                  'AGREGAR INTENTO',
                ),
              ),

              const SizedBox(height: 18),

              LayoutBuilder(
                builder: (context, espacio) {
                  if (espacio.maxWidth < 650) {
                    return Column(
                      children: [
                        panelEquipo('local'),
                        panelEquipo('visitante'),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: panelEquipo('local'),
                      ),
                      Expanded(
                        child: panelEquipo('visitante'),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 14),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, intentos);
                },
                icon: const Icon(Icons.save),
                label: const Text(
                  'GUARDAR SHOOT OUTS EN LA CÉDULA',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
