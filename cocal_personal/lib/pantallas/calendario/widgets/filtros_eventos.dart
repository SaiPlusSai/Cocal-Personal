// lib/pantallas/calendario/widgets/filtros_eventos.dart
import 'package:flutter/material.dart';
import '../../../utils/string_extensions.dart';

class FiltrosEventosCalendario extends StatelessWidget {
  final List<String> temasDisponibles;
  final List<String> estadosDisponibles;
  final String? temaSeleccionado;
  final String? estadoSeleccionado;
  final String busqueda;
  final ValueChanged<String> onBusquedaChanged;
  final ValueChanged<String?> onTemaChanged;
  final ValueChanged<String?> onEstadoChanged;
  final Color Function(String? tema) colorPorTema;

  const FiltrosEventosCalendario({
    super.key,
    required this.temasDisponibles,
    required this.estadosDisponibles,
    required this.temaSeleccionado,
    required this.estadoSeleccionado,
    required this.busqueda,
    required this.onBusquedaChanged,
    required this.onTemaChanged,
    required this.onEstadoChanged,
    required this.colorPorTema,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          TextField(
            onChanged: onBusquedaChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar evento...',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...temasDisponibles.map(
                    (t) => FilterChip(
                  label: Text(t.capitalize()),
                  selected: temaSeleccionado == t,
                  backgroundColor: colorPorTema(t).withOpacity(0.1),
                  selectedColor: colorPorTema(t).withOpacity(0.4),
                  onSelected: (v) => onTemaChanged(v ? t : null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: estadosDisponibles
                .map(
                  (e) => ChoiceChip(
                label: Text(e.capitalize()),
                selected: estadoSeleccionado == e,
                selectedColor: Colors.indigoAccent,
                onSelected: (v) => onEstadoChanged(v ? e : null),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}
