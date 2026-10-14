import 'package:equatable/equatable.dart';

enum TipoEvento { pronostico, resultado, quiniela, quinielaFinalizada, suscripcion }

/// Fila de "Actividad reciente". [positivo] pinta el estado en lima (p. ej. "+5 pts", "Ganaste").
class EventoActividad extends Equatable {
  const EventoActividad({
    required this.titulo,
    required this.tipo,
    required this.estado,
    required this.fecha,
    this.positivo = false,
    this.quinielaId,
  });

  final String titulo;
  final TipoEvento tipo;
  final String estado;
  final DateTime fecha;
  final bool positivo;
  final String? quinielaId;

  String get tipoTexto => switch (tipo) {
        TipoEvento.pronostico => 'Pronóstico',
        TipoEvento.resultado => 'Resultado',
        TipoEvento.quiniela => 'Quiniela',
        TipoEvento.quinielaFinalizada => 'Quiniela',
        TipoEvento.suscripcion => 'Suscripción',
      };

  @override
  List<Object?> get props => [titulo, tipo, estado, fecha, positivo, quinielaId];
}
