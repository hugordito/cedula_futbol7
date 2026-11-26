
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'motor_tablas.dart';

// ==============================================
// ALMACENAMIENTO DE ESTADÍSTICAS
// ARENA MOUSTACHE
// ==============================================

class AlmacenTablas {
  static const String claveRegistro =
      'arena_registro_v1';

  static const String claveHistorialAnterior =
      'cedulas_borrador';

  static const String claveEquipos = 'equipos';

  static final SharedPreferencesAsync _prefs =
  SharedPreferencesAsync();

  // Evita que dos operaciones locales de escritura
  // se ejecuten simultáneamente.

  static Future<void> _cola =
  Future<void>.value();

  static Future<T> _ejecutar<T>(
      Future<T> Function() operacion,
      ) {
    final tarea = _cola.then<T>(
          (_) => operacion(),
    );

    _cola = tarea.then<void>(
          (_) {},
      onError: (Object error, StackTrace stack) {},
    );

    return tarea;
  }

  // ==============================================
  // CONVERTIR LISTAS JSON
  // ==============================================

  static List<Map<String, dynamic>> _convertirLista(
      dynamic valor,
      ) {
    if (valor is! List) {
      throw const FormatException(
        'El almacenamiento no contiene una lista válida.',
      );
    }

    return valor
        .map(
          (item) => Map<String, dynamic>.from(
        item as Map,
      ),
    )
        .toList();
  }

  // ==============================================
  // GUARDAR REGISTRO LOCAL
  // ==============================================

  static Future<void> _guardar(
      _RegistroArena registro,
      ) async {
    await _prefs.setString(
      claveRegistro,
      jsonEncode(registro.toJson()),
    );
  }

  // ==============================================
  // RECUPERAR REGISTRO LOCAL
  // ==============================================

  static Future<_RegistroArena> _cargar() async {
    final texto = await _prefs.getString(
      claveRegistro,
    );

    // Si el nuevo almacenamiento ya existe,
    // no volver a importar el historial anterior.

    if (texto != null) {
      return _RegistroArena.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(texto) as Map,
        ),
      );
    }

    // Primera utilización del nuevo sistema.

    return _migrarHistorialAnterior();
  }

  // ==============================================
  // MIGRACIÓN DE CÉDULAS ANTERIORES
  // ==============================================

  static Future<_RegistroArena>
  _migrarHistorialAnterior() async {
    final textoAnterior = await _prefs.getString(
      claveHistorialAnterior,
    );

    final historialAnterior = _convertirLista(
      jsonDecode(textoAnterior ?? '[]'),
    );

    final registro = _RegistroArena(
      historial: historialAnterior,
      partidos: [],
      idsProcesados: {},
      incidenciasMigracion: [],
    );

    // Recuperar todos los resultados válidos
    // que se encuentren en el historial original.

    for (final cedula in historialAnterior) {
      final id = MotorTablas.texto(
        cedula['id'],
      );

      if (id.isEmpty) {
        registro.incidenciasMigracion.add(
          'Cédula antigua sin identificador.',
        );

        continue;
      }

      // Evitar importar dos veces la misma cédula.

      if (!registro.idsProcesados.add(id)) {
        registro.incidenciasMigracion.add(
          'Cédula duplicada: $id',
        );

        continue;
      }

      try {
        final partido = PartidoTabla.desdeCedula(
          cedula,
          historica: true,
        );

        registro.partidos.add(partido);
      } catch (e) {
        // Si una cédula antigua no tiene un
        // resultado válido, permanecerá en
        // el historial pero no sumará puntos.

        registro.incidenciasMigracion.add(
          'Cédula $id: $e',
        );
      }
    }

    // Guardar el nuevo registro.
    // El historial anterior no se elimina.

    await _guardar(registro);

    return registro;
  }

  // ==============================================
  // CONSULTAR INCIDENCIAS DE MIGRACIÓN
  // ==============================================

  static Future<List<String>>
  cargarIncidenciasMigracion() {
    return _ejecutar(() async {
      final registro = await _cargar();

      return List<String>.from(
        registro.incidenciasMigracion,
      );
    });
  }

  // ==============================================
  // REGISTRAR CÉDULA DEFINITIVA
  // ==============================================

  static Future<bool> registrarDefinitiva(
      Map<String, dynamic> cedula,
      ) {
    return _ejecutar(() async {
      // Crear una copia independiente de los datos.

      final copia = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(cedula)) as Map,
      );

      // No se aceptan borradores ni resultados
      // empatados sin definición por shootouts.

      final partido =
      PartidoTabla.desdeCedula(copia);

      final registro = await _cargar();

      // Una cédula solamente puede registrarse
      // una vez, aunque se intente guardar
      // nuevamente.

      if (registro.idsProcesados.contains(
        partido.id,
      )) {
        return false;
      }

      // Guardar el documento completo.

      registro.historial.add(copia);

      // Guardar únicamente los datos estadísticos.

      registro.partidos.add(partido);

      // Registrar identificador procesado.

      registro.idsProcesados.add(partido.id);

      // Guardar ambas colecciones juntas.

      await _guardar(registro);

      return true;
    });
  }

  // ==============================================
  // CONSULTAR CÉDULAS DEL HISTORIAL
  // ==============================================

  static Future<List<Map<String, dynamic>>>
  cargarHistorial() {
    return _ejecutar(() async {
      final registro = await _cargar();

      final historial = registro.historial
          .map(
            (item) => Map<String, dynamic>.from(
          item,
        ),
      )
          .toList();

      historial.sort(
            (a, b) => MotorTablas.texto(
          b['creadaEn'],
        ).compareTo(
          MotorTablas.texto(a['creadaEn']),
        ),
      );

      return historial;
    });
  }

  // ==============================================
  // ELIMINAR DOCUMENTO DEL HISTORIAL
  // SIN ALTERAR LAS ESTADÍSTICAS
  // ==============================================

  static Future<void> eliminarCedula(
      String cedulaId,
      ) {
    return _ejecutar(() async {
      final registro = await _cargar();

      registro.historial.removeWhere(
            (cedula) =>
        MotorTablas.texto(cedula['id']) ==
            cedulaId,
      );

      // IMPORTANTE:
      //
      // No se elimina el resultado de partidos.
      //
      // No se elimina el identificador de
      // idsProcesados.
      //
      // Por lo tanto, los puntos permanecen
      // y la cédula no podrá volver a contabilizarse.

      await _guardar(registro);
    });
  }

  // ==============================================
  // CONSULTAR RESULTADOS ESTADÍSTICOS
  // ==============================================

  static Future<List<PartidoTabla>>
  cargarPartidos() {
    return _ejecutar(() async {
      final registro = await _cargar();

      return List<PartidoTabla>.from(
        registro.partidos,
      );
    });
  }

  // ==============================================
  // CONSULTAR EQUIPOS REGISTRADOS
  // ==============================================

  static Future<List<Map<String, dynamic>>>
  cargarEquipos() {
    return _ejecutar(() async {
      final texto = await _prefs.getString(
        claveEquipos,
      );

      return _convertirLista(
        jsonDecode(texto ?? '[]'),
      );
    });
  }

  // ==============================================
  // GENERAR TABLA DE POSICIONES
  // ==============================================

  static Future<List<FilaTabla>> cargarTabla({
    required String torneo,
    required String categoria,
  }) {
    return _ejecutar(() async {
      final registro = await _cargar();

      final textoEquipos = await _prefs.getString(
        claveEquipos,
      );

      final equipos = _convertirLista(
        jsonDecode(textoEquipos ?? '[]'),
      );

      return MotorTablas.calcular(
        torneo: torneo,
        categoria: categoria,
        equipos: equipos,
        partidos: registro.partidos,
      );
    });
  }

  // ==============================================
  // RETIRAR ESTADÍSTICAS DE UN EQUIPO
  // ==============================================

  // Se utilizará cuando un equipo cambie
  // de torneo, categoría o sea eliminado.
  //
  // Los puntos de sus antiguos rivales
  // permanecerán intactos.

  static Future<void> retirarEquipo(
      String equipoId,
      ) {
    return _ejecutar(() async {
      if (equipoId.trim().isEmpty) {
        throw const FormatException(
          'Identificador de equipo inválido.',
        );
      }

      final registro = await _cargar();

      for (
      int i = 0;
      i < registro.partidos.length;
      i++
      ) {
        registro.partidos[i] =
            registro.partidos[i].retirarEquipo(
              equipoId,
            );
      }

      await _guardar(registro);
    });
  }
}

// ==============================================
// ESTRUCTURA INTERNA DEL ALMACENAMIENTO
// ==============================================

class _RegistroArena {
  final List<Map<String, dynamic>> historial;

  final List<PartidoTabla> partidos;

  final Set<String> idsProcesados;

  final List<String> incidenciasMigracion;

  _RegistroArena({
    required this.historial,
    required this.partidos,
    required this.idsProcesados,
    required this.incidenciasMigracion,
  });

  // ==============================================
  // CONVERTIR REGISTRO A JSON
  // ==============================================

  Map<String, dynamic> toJson() {
    return {
      'version': 1,

      'historial': historial,

      'partidos': partidos
          .map((partido) => partido.toJson())
          .toList(),

      'idsProcesados':
      idsProcesados.toList(),

      'incidenciasMigracion':
      incidenciasMigracion,
    };
  }

  // ==============================================
  // RECUPERAR REGISTRO DESDE JSON
  // ==============================================

  factory _RegistroArena.fromJson(
      Map<String, dynamic> json,
      ) {
    if (json['version'] != 1) {
      throw const FormatException(
        'Versión de almacenamiento no compatible.',
      );
    }

    final historial =
    AlmacenTablas._convertirLista(
      json['historial'],
    );

    final partidos =
    AlmacenTablas._convertirLista(
      json['partidos'],
    ).map(
          (item) => PartidoTabla.fromJson(item),
    ).toList();

    final idsProcesados =
    List<String>.from(
      json['idsProcesados'] as List,
    ).toSet();

    final incidencias =
    List<String>.from(
      json['incidenciasMigracion'] as List,
    );

    return _RegistroArena(
      historial: historial,
      partidos: partidos,
      idsProcesados: idsProcesados,
      incidenciasMigracion: incidencias,
    );
  }
}
