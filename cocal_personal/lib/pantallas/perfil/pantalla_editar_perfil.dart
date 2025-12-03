//lib/pantallas/perfil/pantalla_editar_perfil.dart

import 'package:flutter/material.dart';
import '../../servicios/autenticacion/perfil_service.dart';
import '../../servicios/temas_interes_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PantallaEditarPerfil extends StatefulWidget {
  const PantallaEditarPerfil({super.key});

  @override
  State<PantallaEditarPerfil> createState() => _PantallaEditarPerfilState();
}

class _PantallaEditarPerfilState extends State<PantallaEditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;
  XFile? _imagenSeleccionada;
  final _picker = ImagePicker();
  List<TemaInteres> _temasSeleccionados = [];
  List<TemaInteres> _temasDisponibles = TemaInteres.values;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final perfil = await PerfilService.obtenerPerfilActual();
    if (perfil != null) {
      _nombreCtrl.text = perfil['nombre'] ?? '';
      _apellidoCtrl.text = perfil['apellido'] ?? '';
    }

    // Cargar temas de interés
    final temas = await TemasInteresService.obtenerTemasActual();

    setState(() {
      _temasSeleccionados = temas;
      _cargando = false;
    });
  }
  Future<void> _seleccionarImagen() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (img != null) {
      setState(() => _imagenSeleccionada = img);
    }
  }


  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final error = await PerfilService.actualizarPerfil(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
    );

    setState(() => _guardando = false);

    if (!mounted) return;

    // Subir foto si fue seleccionada
    if (_imagenSeleccionada != null) {
      await PerfilService.subirFotoPerfil(_imagenSeleccionada!);
    }

    // Obtener temas actuales del usuario
    final temasActuales = await TemasInteresService.obtenerTemasActual();
    debugPrint('[EDITAR PERFIL] Temas actuales: $temasActuales');
    debugPrint('[EDITAR PERFIL] Temas seleccionados: $_temasSeleccionados');

    // Calcular qué temas agregar y cuáles eliminar
    final temasAEliminar = temasActuales
        .where((t) => !_temasSeleccionados.contains(t))
        .toList();
    final temasAAgregar = _temasSeleccionados
        .where((t) => !temasActuales.contains(t))
        .toList();

    debugPrint('[EDITAR PERFIL] Temas a eliminar: $temasAEliminar');
    debugPrint('[EDITAR PERFIL] Temas a agregar: $temasAAgregar');

    // Eliminar temas no seleccionados
    for (final tema in temasAEliminar) {
      final resultElim = await TemasInteresService.eliminarTema(tema);
      debugPrint('[EDITAR PERFIL] Eliminar $tema: $resultElim');
      if (resultElim != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $resultElim'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Agregar nuevos temas seleccionados
    for (final tema in temasAAgregar) {
      final resultAgreg = await TemasInteresService.agregarTema(tema);
      debugPrint('[EDITAR PERFIL] Agregar $tema: $resultAgreg');
      if (resultAgreg != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $resultAgreg'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
      Navigator.pop(context); // volver a la pantalla anterior
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _seleccionarImagen,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: _imagenSeleccionada != null
                        ? FileImage(File(_imagenSeleccionada!.path))
                        : null,
                    child: _imagenSeleccionada == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apellidoCtrl,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                const SizedBox(height: 24),

                // Sección de temas de interés
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Temas de interés',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _temasDisponibles.map((tema) {
                    final seleccionado = _temasSeleccionados.contains(tema);
                    return FilterChip(
                      label: Text(tema.nombre),
                      selected: seleccionado,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (!_temasSeleccionados.contains(tema)) {
                              _temasSeleccionados.add(tema);
                            }
                          } else {
                            _temasSeleccionados.remove(tema);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _guardando
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save),
                    label: Text(_guardando ? 'Guardando...' : 'Guardar'),
                    onPressed: _guardando ? null : _guardar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    super.dispose();
  }
}
