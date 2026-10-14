import 'package:flutter_test/flutter_test.dart';
import 'package:tdsport_app/features/quinielas/models/torneo_model.dart';
import 'package:tdsport_app/features/quinielas/models/quiniela_model.dart';

void main() {
  group('Modelos del Módulo de Quinielas', () {
    test('TorneoModel parsea JSON correctamente', () {
      final json = {
        'id': 'torneo-123',
        'nombre': 'Liga Nacional 2026',
        'estado_id': 2,
        'fecha_inicio': '2026-08-01',
        'fecha_fin': '2026-12-15',
      };

      final torneo = TorneoModel.fromJson(json);

      expect(torneo.id, 'torneo-123');
      expect(torneo.nombre, 'Liga Nacional 2026');
      expect(torneo.estadoId, 2);
      expect(torneo.estadoTexto, 'En curso');
    });

    test('QuinielaModel parsea JSON correctamente', () {
      final json = {
        'id': 'quiniela-456',
        'nombre': 'Quiniela Amigos',
        'torneo_id': 'torneo-123',
        'codigo_acceso': 'AMIGOS26',
        'limite_usuarios': 15,
        'creador_id': 'user-789',
        'puntos_totales': 10,
        'torneos': {
          'nombre': 'Liga Nacional 2026',
        },
      };

      final quiniela = QuinielaModel.fromJson(json);

      expect(quiniela.id, 'quiniela-456');
      expect(quiniela.nombre, 'Quiniela Amigos');
      expect(quiniela.codigoAcceso, 'AMIGOS26');
      expect(quiniela.limiteUsuarios, 15);
      expect(quiniela.torneoNombre, 'Liga Nacional 2026');
      expect(quiniela.puntosUsuario, 10);
    });
  });
}
