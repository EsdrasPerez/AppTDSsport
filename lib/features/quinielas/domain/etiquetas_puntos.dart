/// Etiquetas para MOSTRAR puntos y pronósticos. Aquí no se calcula ningún punto:
/// los puntos los calcula la función calcular_puntos_partido() en la base de datos.
library;

/// 1 = gana local, X = empate, 2 = gana visitante.
String signo(int local, int visitante) => local > visitante ? '1' : (local == visitante ? 'X' : '2');

String nombreSigno(String signo) => switch (signo) {
      '1' => 'Local',
      'X' => 'Empate',
      _ => 'Visitante',
    };

/// Texto de los puntos que ya vienen de pronosticos.puntos_obtenidos (regla RN01).
String detallePuntos(int puntos) => switch (puntos) {
      5 => 'Resultado exacto',
      4 => 'Ganador + diferencia',
      3 => 'Ganador / empate',
      _ => 'Sin acierto',
    };
