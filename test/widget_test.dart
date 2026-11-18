import 'package:flutter_test/flutter_test.dart';
import 'package:cedula_futbol7/main.dart';

void main() {
  testWidgets('La pantalla muestra los cinco botones', (tester) async {
    await tester.pumpWidget(const CedulaFutbolApp());

    expect(find.text('AGREGAR EQUIPO'), findsOneWidget);
    expect(find.text('EDITAR EQUIPO'), findsOneWidget);
    expect(find.text('CARGAR EQUIPO'), findsOneWidget);
    expect(find.text('CREAR NUEVA CÉDULA'), findsOneWidget);
    expect(find.text('HISTORIAL'), findsOneWidget);
  });
}
