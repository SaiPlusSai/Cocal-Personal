import 'package:flutter/material.dart';
import '../../servicios/autenticacion/autenticacion_service.dart';
import '../../servicios/supabase_service.dart';
import '../calendario/pantalla_calendarios.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key}); // 👈 ya no pide correo

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  String? correoUsuario;
  String? nombreUsuario;
  String? apellidoUsuario;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    try {
      final cliente = SupabaseService.cliente;
      final user = cliente.auth.currentUser;

      if (user == null || user.email == null) {
        debugPrint('No hay usuario logueado en Supabase Auth');
        setState(() => cargando = false);
        return;
      }

      final correo = user.email!;
      correoUsuario = correo; // lo guardamos para usarlo luego

      final res = await cliente
          .from('usuario')
          .select('nombre, apellido')
          .eq('correo', correo)
          .maybeSingle();

      if (res != null) {
        setState(() {
          nombreUsuario = res['nombre'] ?? 'Usuario';
          apellidoUsuario = res['apellido'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error al cargar usuario: $e');
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoCal - Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AutenticacionService.cerrarSesion();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Solicitudes',
            onPressed: () {
              Navigator.pushNamed(context, '/solicitudes');
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👋 ¡Hola, ${nombreUsuario ?? 'usuario'} ${apellidoUsuario ?? ''}!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _tarjetaAcceso(
                    icono: Icons.calendar_month,
                    titulo: 'Calendario',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaCalendarios(
                            correo: correoUsuario ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  _tarjetaAcceso(
                    icono: Icons.group,
                    titulo: 'Grupos',
                    color: Colors.green,
                    onTap: () => _mostrarSnack('Abrir grupos...'),
                  ),
                  _tarjetaAcceso(
                    icono: Icons.event,
                    titulo: 'Eventos',
                    color: Colors.purple,
                    onTap: () => _mostrarSnack('Abrir eventos...'),
                  ),
                  _tarjetaAcceso(
                    icono: Icons.settings,
                    titulo: 'Configuración',
                    color: Colors.orange,
                    onTap: () => _mostrarSnack('Abrir configuración...'),
                  ),
                  _tarjetaAcceso(
                    icono: Icons.search,
                    titulo: 'Usuarios',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/usuarios'),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAcceso({
    required IconData icono,
    required String titulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: color.withOpacity(0.15),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: color, size: 50),
              const SizedBox(height: 10),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarSnack(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}
