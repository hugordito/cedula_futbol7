
import 'package:material_ui/material_ui.dart';

class RegistroEventos extends StatefulWidget {
  final Map<String, dynamic> equipoLocal;
  final Map<String, dynamic> equipoVisitante;
  final List<Map<String, dynamic>> eventosIniciales;

  const RegistroEventos({
    super.key,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.eventosIniciales,
  });

  @override
  State<RegistroEventos> createState() =>
      _RegistroEventosState();
}

class _RegistroEventosState extends State<RegistroEventos> {
  late final List<Map<String, dynamic>> eventos;

  final minuto = TextEditingController();
  final causa = TextEditingController();

  String tipo = 'gol';
  String lado = 'local';
  String periodo = 'Primer medio';
  int? numeroJugador;

  @override
  void initState() {
    super.initState();

    eventos = widget.eventosIniciales
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> get equipoActual =>
      lado == 'local'
          ? widget.equipoLocal
          : widget.equipoVisitante;

  List<Map<String, dynamic>> get jugadoresActuales =>
      ((equipoActual['jugadores'] as List?) ?? [])
          .map(
            (e) => Map<String, dynamic>.from(e as Map),
      )
          .toList();

  String nombreTipo(String valor) {
    switch (valor) {
      case 'gol':
        return 'Gol';
      case 'amarilla':
        return 'Tarjeta amarilla';
      case 'roja':
        return 'Tarjeta roja';
      default:
        return 'Falta';
    }
  }

  void mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  void agregarEvento() {
    final valorMinuto =
    int.tryParse(minuto.text.trim());

    if (numeroJugador == null) {
      mensaje('Selecciona un jugador');
      return;
    }

    if (valorMinuto == null || valorMinuto < 0) {
      mensaje('Escribe un minuto válido');
      return;
    }

    if ((tipo == 'amarilla' || tipo == 'roja') &&
        causa.text.trim().isEmpty) {
      mensaje('Escribe la causa de la tarjeta');
      return;
    }

    final jugadores = jugadoresActuales.where(
          (j) =>
      int.tryParse(j['numero'].toString()) ==
          numeroJugador,
    );

    if (jugadores.isEmpty) {
      mensaje('Ese jugador ya no está en la plantilla');
      return;
    }

    final jugador = jugadores.first;

    setState(() {
      eventos.add({
        'tipo': tipo,
        'lado': lado,
        'equipoId': equipoActual['id'].toString(),
        'numero': numeroJugador,
        'jugador': jugador['nombre'].toString(),
        'periodo': periodo,
        'minuto': valorMinuto,
        'causa': causa.text.trim(),
      });

      numeroJugador = null;
    });

    minuto.clear();
    causa.clear();

    mensaje('Registro agregado');
  }

  String detalleEvento(
      Map<String, dynamic> evento,
      ) {
    final causaEvento =
    (evento['causa'] ?? '').toString();

    final extra = causaEvento.isEmpty
        ? ''
        : ' · $causaEvento';

    return '#${evento['numero']} '
        '${evento['jugador']} · '
        '${evento['periodo']} · '
        'Min. ${evento['minuto']}$extra';
  }

  void guardarRegistros() {
    Navigator.pop(context, eventos);
  }

  @override
  void dispose() {
    minuto.dispose();
    causa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jugadores = jugadoresActuales;

    return Scaffold(
      appBar: AppBar(
        title: const Text('REGISTRO DEL PARTIDO'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Agregar acontecimiento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          const Text('Tipo de registro'),

          DropdownButton<String>(
            value: tipo,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: 'gol',
                child: Text('Gol'),
              ),
              DropdownMenuItem(
                value: 'falta',
                child: Text('Falta'),
              ),
              DropdownMenuItem(
                value: 'amarilla',
                child: Text('Tarjeta amarilla'),
              ),
              DropdownMenuItem(
                value: 'roja',
                child: Text('Tarjeta roja'),
              ),
            ],
            onChanged: (valor) {
              if (valor != null) {
                setState(() {
                  tipo = valor;
                });
              }
            },
          ),

          const SizedBox(height: 12),

          const Text('Equipo'),

          DropdownButton<String>(
            value: lado,
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: 'local',
                child: Text(
                  'LOCAL: ${widget.equipoLocal['nombre']}',
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
              if (valor != null) {
                setState(() {
                  lado = valor;
                  numeroJugador = null;
                });
              }
            },
          ),

          const SizedBox(height: 12),

          const Text('Jugador'),

          DropdownButton<int>(
            value: numeroJugador,
            isExpanded: true,
            hint: const Text('Selecciona un jugador'),
            items: jugadores.map((jugador) {
              final numero =
              int.parse(jugador['numero'].toString());

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

          const SizedBox(height: 12),

          const Text('Periodo'),

          DropdownButton<String>(
            value: periodo,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: 'Primer medio',
                child: Text('Primer medio'),
              ),
              DropdownMenuItem(
                value: 'Segundo medio',
                child: Text('Segundo medio'),
              ),
            ],
            onChanged: (valor) {
              if (valor != null) {
                setState(() {
                  periodo = valor;
                });
              }
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: minuto,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minuto del partido',
              border: OutlineInputBorder(),
            ),
          ),

          if (tipo == 'amarilla' || tipo == 'roja') ...[
            const SizedBox(height: 12),

            TextField(
              controller: causa,
              decoration: const InputDecoration(
                labelText: 'Causa de la tarjeta',
                border: OutlineInputBorder(),
              ),
            ),
          ],

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: agregarEvento,
            icon: const Icon(Icons.add),
            label: const Text('AGREGAR REGISTRO'),
          ),

          const SizedBox(height: 22),

          Text(
            'Registros capturados (${eventos.length})',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          if (eventos.isEmpty)
            const Text(
              'Aún no hay goles, tarjetas '
                  'ni faltas registrados.',
            ),

          for (int i = 0; i < eventos.length; i++)
            Card(
              child: ListTile(
                title: Text(
                  '${nombreTipo(eventos[i]['tipo'].toString())}'
                      ' · '
                      '${eventos[i]['lado'] == 'local'
                      ? 'Local'
                      : 'Visitante'}',
                ),
                subtitle: Text(
                  detalleEvento(eventos[i]),
                ),
                trailing: IconButton(
                  tooltip: 'Eliminar registro',
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  onPressed: () {
                    setState(() {
                      eventos.removeAt(i);
                    });
                  },
                ),
              ),
            ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: guardarRegistros,
            icon: const Icon(Icons.check),
            label: const Text(
              'GUARDAR REGISTROS EN CÉDULA',
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
