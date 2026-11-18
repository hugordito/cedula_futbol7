
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:signature/signature.dart';

class FirmaDialog extends StatefulWidget {
  final String titulo;
  final Uint8List? firmaAnterior;

  const FirmaDialog({
    super.key,
    required this.titulo,
    this.firmaAnterior,
  });

  static Future<Uint8List?> abrir(
      BuildContext context, {
        required String titulo,
        Uint8List? firmaAnterior,
      }) {
    return showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FirmaDialog(
        titulo: titulo,
        firmaAnterior: firmaAnterior,
      ),
    );
  }

  @override
  State<FirmaDialog> createState() =>
      _FirmaDialogState();
}

class _FirmaDialogState extends State<FirmaDialog> {
  late final SignatureController controlador;

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    controlador = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  Future<void> guardarFirma() async {
    if (controlador.isEmpty || guardando) {
      if (controlador.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Primero dibuja tu firma',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final imagen = await controlador.toPngBytes(
        width: 800,
        height: 250,
      );

      if (!mounted) return;

      if (imagen == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo generar la firma',
            ),
          ),
        );
        return;
      }

      Navigator.pop(context, imagen);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar firma: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Dibuja tu firma dentro del recuadro '
                  'utilizando el dedo o lápiz táctil.',
              textAlign: TextAlign.center,
            ),

            if (widget.firmaAnterior != null) ...[
              const SizedBox(height: 12),

              const Text(
                'Firma guardada anteriormente:',
              ),

              SizedBox(
                height: 65,
                child: Image.memory(
                  widget.firmaAnterior!,
                  fit: BoxFit.contain,
                ),
              ),

              const Text(
                'Si guardas una firma nueva, '
                    'reemplazará la anterior.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],

            const SizedBox(height: 18),

            LayoutBuilder(
              builder: (context, espacio) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 2,
                    ),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Signature(
                    controller: controlador,
                    width: espacio.maxWidth,
                    height: 220,
                    backgroundColor: Colors.white,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        controlador.clear();
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('BORRAR'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                    guardando ? null : guardarFirma,
                    icon: const Icon(Icons.save),
                    label: const Text('GUARDAR'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCELAR'),
            ),
          ],
        ),
      ),
    );
  }
}
