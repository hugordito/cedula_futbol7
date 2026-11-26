
// ==========================================
// MOTOR DE ESTADÍSTICAS
// ARENA MOUSTACHE
// ==========================================

class MotorTablas {
  static String normalizar(String texto) {
    return texto
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  static String texto(dynamic valor) {
    return valor?.toString().trim() ?? '';
  }

  // ==========================================
  // VALIDACIÓN DE RESULTADOS
  // ==========================================

  static int leerMarcador(
      dynamic valor,
      String campo,
      ) {
    final numero = int.tryParse(texto(valor));

    if (numero == null || numero < 0) {
      throw FormatException(
        'Marcador inválido: $campo',
      );
    }

    return numero;
  }

  static bool mismaClasificacion({
    required String torneoA,
    required String categoriaA,
    required String torneoB,
    required String categoriaB,
  }) {
    return normalizar(torneoA) ==
        normalizar(torneoB) &&
        normalizar(categoriaA) ==
            normalizar(categoriaB);
  }

  // ==========================================
  // CALCULAR TABLA DE POSICIONES
  // ==========================================

  static List<FilaTabla> calcular({
    required String torneo,
    required String categoria,
    required List<Map<String, dynamic>> equipos,
    required List<PartidoTabla> partidos,
  }) {
    final filas = <String, FilaTabla>{};

    // Registrar todos los equipos actuales,
    // incluso aquellos que no han jugado.

    for (final equipo in equipos) {
      final pertenece = mismaClasificacion(
        torneoA: texto(equipo['torneo']),
        categoriaA: texto(equipo['categoria']),
        torneoB: torneo,
        categoriaB: categoria,
      );

      if (!pertenece) continue;

      final id = texto(equipo['id']);
      final nombre = texto(equipo['nombre']);

      if (id.isEmpty || nombre.isEmpty) {
        continue;
      }

      filas[id] = FilaTabla(
        equipoId: id,
        nombre: nombre,
      );
    }

    // Evitar contabilizar una misma cédula
    // más de una vez.

    final partidosProcesados = <String>{};

    for (final partido in partidos) {
      final pertenece = mismaClasificacion(
        torneoA: partido.torneo,
        categoriaA: partido.categoria,
        torneoB: torneo,
        categoriaB: categoria,
      );

      if (!pertenece) continue;

      if (!partidosProcesados.add(partido.id)) {
        continue;
      }

      final local = filas[partido.localId];

      final visitante =
      filas[partido.visitanteId];

      // Registrar estadísticas del LOCAL.

      if (partido.contabilizarLocal) {
        local?._registrar(
          golesFavor: partido.golesLocal,
          golesContra: partido.golesVisitante,
          puntos: partido.puntosLocal,
        );
      }

      // Registrar estadísticas del VISITANTE.

      if (partido.contabilizarVisitante) {
        visitante?._registrar(
          golesFavor: partido.golesVisitante,
          golesContra: partido.golesLocal,
          puntos: partido.puntosVisitante,
        );
      }
    }

    final resultado = filas.values.toList();

    // ========================================
    // CRITERIOS OFICIALES DE DESEMPATE
    // ========================================

    resultado.sort((a, b) {
      // 1. Mayor cantidad de puntos.

      int comparacion =
      b.puntos.compareTo(a.puntos);

      if (comparacion != 0) return comparacion;

      // 2. Mayor diferencia de goles.

      comparacion = b.diferenciaGoles.compareTo(
        a.diferenciaGoles,
      );

      if (comparacion != 0) return comparacion;

      // 3. Mayor cantidad de goles a favor.

      comparacion =
          b.golesFavor.compareTo(a.golesFavor);

      if (comparacion != 0) return comparacion;

      // 4. Mayor cantidad de partidos ganados
      // en tiempo regular.

      comparacion =
          b.ganados.compareTo(a.ganados);

      if (comparacion != 0) return comparacion;

      // 5. Orden alfabético.

      comparacion = normalizar(b.nombre)
          .compareTo(normalizar(a.nombre));

      // Orden ascendente por nombre.

      if (comparacion != 0) {
        return -comparacion;
      }

      return a.equipoId.compareTo(b.equipoId);
    });

    // Asignar posición definitiva.

    for (int i = 0; i < resultado.length; i++) {
      resultado[i].posicion = i + 1;
    }

    return resultado;
  }
}

// ==========================================
// RESULTADO ESTADÍSTICO DE UN PARTIDO
// ==========================================

class PartidoTabla {
  final String id;

  final String torneo;
  final String categoria;

  final String localId;
  final String visitanteId;

  final String fecha;
  final String jornada;

  final int golesLocal;
  final int golesVisitante;

  final int shootoutsLocal;
  final int shootoutsVisitante;

  final bool contabilizarLocal;
  final bool contabilizarVisitante;

  const PartidoTabla._({
    required this.id,
    required this.torneo,
    required this.categoria,
    required this.localId,
    required this.visitanteId,
    required this.fecha,
    required this.jornada,
    required this.golesLocal,
    required this.golesVisitante,
    required this.shootoutsLocal,
    required this.shootoutsVisitante,
    this.contabilizarLocal = true,
    this.contabilizarVisitante = true,
  });

  // ==========================================
  // IDENTIFICAR TIPO DE RESULTADO
  // ==========================================

  bool get empateRegular =>
      golesLocal == golesVisitante;

  bool get victoriaLocalRegular =>
      golesLocal > golesVisitante;

  bool get victoriaVisitanteRegular =>
      golesVisitante > golesLocal;

  // ==========================================
  // PUNTOS DEL EQUIPO LOCAL
  // ==========================================

  int get puntosLocal {
    if (victoriaLocalRegular) {
      return 3;
    }

    if (victoriaVisitanteRegular) {
      return 0;
    }

    return shootoutsLocal > shootoutsVisitante
        ? 2
        : 1;
  }

  // ==========================================
  // PUNTOS DEL EQUIPO VISITANTE
  // ==========================================

  int get puntosVisitante {
    if (victoriaVisitanteRegular) {
      return 3;
    }

    if (victoriaLocalRegular) {
      return 0;
    }

    return shootoutsVisitante > shootoutsLocal
        ? 2
        : 1;
  }

  // ==========================================
  // CONVERTIR UNA CÉDULA EN RESULTADO OFICIAL
  // ==========================================

  factory PartidoTabla.desdeCedula(
      Map<String, dynamic> cedula, {
        bool historica = false,
      }) {
    final estado = MotorTablas.normalizar(
      MotorTablas.texto(cedula['estado']),
    );

    // Los borradores nuevos no cuentan.
    //
    // La opción historica solamente se utilizará
    // durante la migración de las antiguas
    // cédulas guardadas en el historial.

    if (estado != 'definitiva' &&
        !(historica && estado == 'borrador')) {
      throw const FormatException(
        'La cédula no es definitiva.',
      );
    }

    final id = MotorTablas.texto(cedula['id']);

    final torneo =
    MotorTablas.texto(cedula['torneo']);

    final categoria =
    MotorTablas.texto(cedula['categoria']);

    final fecha =
    MotorTablas.texto(cedula['fecha']);

    final jornada =
    MotorTablas.texto(cedula['jornada']);

    if (id.isEmpty ||
        torneo.isEmpty ||
        categoria.isEmpty ||
        fecha.isEmpty) {
      throw const FormatException(
        'Faltan datos generales del partido.',
      );
    }

    final local = cedula['equipoLocal'];

    final visitante = cedula['equipoVisitante'];

    if (local is! Map || visitante is! Map) {
      throw const FormatException(
        'Selecciona los dos equipos.',
      );
    }

    final localId = MotorTablas.texto(
      local['id'],
    );

    final visitanteId = MotorTablas.texto(
      visitante['id'],
    );

    if (localId.isEmpty ||
        visitanteId.isEmpty ||
        localId == visitanteId) {
      throw const FormatException(
        'Los equipos del partido no son válidos.',
      );
    }

    final golesLocal = MotorTablas.leerMarcador(
      cedula['golesLocal'],
      'Goles local',
    );

    final golesVisitante =
    MotorTablas.leerMarcador(
      cedula['golesVisitante'],
      'Goles visitante',
    );

    final shootoutsLocal =
    MotorTablas.leerMarcador(
      cedula['shootoutsGolLocal'] ??
          (golesLocal != golesVisitante ? 0 : null),
      'Shootouts local',
    );

    final shootoutsVisitante =
    MotorTablas.leerMarcador(
      cedula['shootoutsGolVisitante'] ??
          (golesLocal != golesVisitante ? 0 : null),
      'Shootouts visitante',
    );

    // ========================================
    // NO PERMITIR EMPATE SIN DEFINICIÓN
    // ========================================

    if (golesLocal == golesVisitante &&
        shootoutsLocal == shootoutsVisitante) {
      throw const FormatException(
        'El partido está empatado. '
            'Debes definir un ganador por shootouts.',
      );
    }

    return PartidoTabla._(
      id: id,
      torneo: torneo,
      categoria: categoria,
      localId: localId,
      visitanteId: visitanteId,
      fecha: fecha,
      jornada: jornada,
      golesLocal: golesLocal,
      golesVisitante: golesVisitante,
      shootoutsLocal: shootoutsLocal,
      shootoutsVisitante: shootoutsVisitante,
    );
  }

  // ==========================================
  // RETIRAR ESTADÍSTICAS DE UN EQUIPO
  // ==========================================

  // Permite conservar las estadísticas del rival
  // cuando un equipo cambia de clasificación
  // o se elimina definitivamente.

  PartidoTabla retirarEquipo(String equipoId) {
    return PartidoTabla._(
      id: id,
      torneo: torneo,
      categoria: categoria,
      localId: localId,
      visitanteId: visitanteId,
      fecha: fecha,
      jornada: jornada,
      golesLocal: golesLocal,
      golesVisitante: golesVisitante,
      shootoutsLocal: shootoutsLocal,
      shootoutsVisitante: shootoutsVisitante,
      contabilizarLocal:
      contabilizarLocal && localId != equipoId,
      contabilizarVisitante:
      contabilizarVisitante &&
          visitanteId != equipoId,
    );
  }

  // ==========================================
  // PREPARAR RESULTADO PARA ALMACENAMIENTO
  // ==========================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'torneo': torneo,
      'categoria': categoria,
      'localId': localId,
      'visitanteId': visitanteId,
      'fecha': fecha,
      'jornada': jornada,
      'golesLocal': golesLocal,
      'golesVisitante': golesVisitante,
      'shootoutsLocal': shootoutsLocal,
      'shootoutsVisitante': shootoutsVisitante,
      'contabilizarLocal': contabilizarLocal,
      'contabilizarVisitante':
      contabilizarVisitante,
    };
  }

  // ==========================================
  // RECUPERAR RESULTADO ALMACENADO
  // ==========================================

  factory PartidoTabla.fromJson(
      Map<String, dynamic> json,
      ) {
    final validado = PartidoTabla.desdeCedula({
      'id': json['id'],
      'estado': 'definitiva',
      'torneo': json['torneo'],
      'categoria': json['categoria'],
      'fecha': json['fecha'],
      'jornada': json['jornada'],
      'equipoLocal': {
        'id': json['localId'],
      },
      'equipoVisitante': {
        'id': json['visitanteId'],
      },
      'golesLocal': json['golesLocal'],
      'golesVisitante': json['golesVisitante'],
      'shootoutsGolLocal': json['shootoutsLocal'],
      'shootoutsGolVisitante':
      json['shootoutsVisitante'],
    });

    return PartidoTabla._(
      id: validado.id,
      torneo: validado.torneo,
      categoria: validado.categoria,
      localId: validado.localId,
      visitanteId: validado.visitanteId,
      fecha: validado.fecha,
      jornada: validado.jornada,
      golesLocal: validado.golesLocal,
      golesVisitante: validado.golesVisitante,
      shootoutsLocal: validado.shootoutsLocal,
      shootoutsVisitante:
      validado.shootoutsVisitante,
      contabilizarLocal:
      json['contabilizarLocal'] != false,
      contabilizarVisitante:
      json['contabilizarVisitante'] != false,
    );
  }
}

// ==========================================
// ESTADÍSTICAS DE CADA EQUIPO
// ==========================================

class FilaTabla {
  final String equipoId;
  final String nombre;

  int posicion = 0;

  int jugados = 0;
  int ganados = 0;
  int empatados = 0;
  int perdidos = 0;

  int golesFavor = 0;
  int golesContra = 0;

  int puntos = 0;

  // Estadísticas adicionales de shootouts.

  int shootoutsGanados = 0;
  int shootoutsPerdidos = 0;

  FilaTabla({
    required this.equipoId,
    required this.nombre,
  });

  int get diferenciaGoles =>
      golesFavor - golesContra;

  bool get clasificado =>
      posicion >= 1 && posicion <= 4;

  // ==========================================
  // ACTUALIZAR ESTADÍSTICAS
  // ==========================================

  void _registrar({
    required int golesFavor,
    required int golesContra,
    required int puntos,
  }) {
    jugados++;

    this.golesFavor += golesFavor;
    this.golesContra += golesContra;
    this.puntos += puntos;

    if (golesFavor > golesContra) {
      ganados++;
    } else if (golesFavor < golesContra) {
      perdidos++;
    } else {
      empatados++;

      if (puntos == 2) {
        shootoutsGanados++;
      } else if (puntos == 1) {
        shootoutsPerdidos++;
      }
    }
  }

  // ==========================================
  // CONVERTIR ESTADÍSTICAS
  // ==========================================

  Map<String, dynamic> toJson() {
    return {
      'equipoId': equipoId,
      'nombre': nombre,
      'posicion': posicion,
      'pj': jugados,
      'pg': ganados,
      'pe': empatados,
      'pp': perdidos,
      'gf': golesFavor,
      'gc': golesContra,
      'dg': diferenciaGoles,
      'pts': puntos,
      'shootoutsGanados': shootoutsGanados,
      'shootoutsPerdidos': shootoutsPerdidos,
      'clasificado': clasificado,
    };
  }
}
