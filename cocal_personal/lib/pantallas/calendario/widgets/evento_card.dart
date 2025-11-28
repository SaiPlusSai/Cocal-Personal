// lib/pantallas/calendario/widgets/evento_card.dart
import 'package:flutter/material.dart';

class EventoCard extends StatelessWidget {
  final Map<String, dynamic> evento;
  final Color Function(String? tema) colorPorTema;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const EventoCard({
    super.key,
    required this.evento,
    required this.colorPorTema,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tema = evento['tema'] as String?;
    final color = colorPorTema(tema);

    return Card(
      color: color.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(
          evento['titulo'] ?? 'Sin título',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${evento['descripcion'] ?? ''}\nEstado: ${evento['estado']}',
        ),
        isThreeLine: true,
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (evento['recordatorio_minutos'] != null)
              const Tooltip(
                message: 'Recordatorio activo',
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.amber,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
