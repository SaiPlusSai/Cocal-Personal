import 'package:flutter/material.dart';

class EventoCard extends StatelessWidget {
  final Map<String, dynamic> evento;
  final Color Function(String? tema) colorPorTema;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EventoCard({
    super.key,
    required this.evento,
    required this.colorPorTema,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final titulo = (evento['titulo'] ?? 'Sin título').toString();
    final desc = (evento['descripcion'] ?? '').toString();
    final tema = evento['tema']?.toString();
    final estado = evento['estado']?.toString() ?? 'ACTIVO';
    final creador = evento['creador']?.toString() ?? 'Desconocido';

    DateTime? fecha;
    String horaTexto = '';
    try {
      fecha = DateTime.parse(evento['horario'].toString()).toLocal();
      horaTexto = TimeOfDay.fromDateTime(fecha).format(context);
    } catch (_) {}

    final colorTema = colorPorTema(tema);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: colorTema,
                width: 6,
              ),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono grande con el color del tema
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorTema.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event,
                  color: colorTema,
                ),
              ),
              const SizedBox(width: 12),
              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: -6,
                      children: [
                        if (tema != null)
                          Chip(
                            label: Text(tema),
                            backgroundColor: colorTema.withOpacity(0.12),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                          ),
                        Chip(
                          label: Text('Estado: $estado'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                        if (horaTexto.isNotEmpty)
                          Chip(
                            label: Text('Hora: $horaTexto'),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Creado por: $creador',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.redAccent,
                  tooltip: 'Eliminar evento',
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
