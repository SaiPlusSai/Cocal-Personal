import 'package:flutter/material.dart';
import '../../servicios/autenticacion/autenticacion_service.dart';
import '../../servicios/supabase_service.dart';
import '../calendario/pantalla_calendario_general.dart';
import '../social/pantalla_grupos.dart';
import '../social/pantalla_usuarios.dart';
import '../../widgets/drawer_usuario.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  String? correoUsuario;
  String? nombreUsuario;
  String? apellidoUsuario;
  String? fotoUrlUsuario;
  bool cargando = true;

  int _indiceActual = 0; // 0 = Calendario, 1 = Buscar, 2 = Grupos

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
      correoUsuario = correo;

      final res = await cliente
          .from('usuario')
          .select('nombre, apellido, foto_url')
          .eq('correo', correo)
          .maybeSingle();

      if (res != null) {
        setState(() {
          nombreUsuario = res['nombre'] ?? 'Usuario';
          apellidoUsuario = res['apellido'] ?? '';
          fotoUrlUsuario = res['foto_url'];
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

  String _tituloActual() {
    switch (_indiceActual) {
      case 0:
        return 'Tu calendario';
      case 1:
        return 'Buscar usuarios';
      case 2:
        return 'Grupos';
      default:
        return 'CoCal';
    }
  }

  Widget _cuerpoActual() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_indiceActual) {
      case 0:
      // Vista calendario general del usuario (el propio)
        return PantallaCalendarioGeneral(
          correo: correoUsuario ?? '',
        );
      case 1:
      // Búsqueda de usuarios
        return const PantallaUsuarios();
      case 2:
      // Lista de grupos
        return const PantallaGrupos();
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _indiceActual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerUsuario(
        nombre: nombreUsuario ?? 'Usuario',
        apellido: apellidoUsuario ?? '',
        correo: correoUsuario ?? '',
        fotoUrl: fotoUrlUsuario,
      ),
      appBar: AppBar(
        title: Text(_tituloActual()),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Solicitudes',
            onPressed: () {
              Navigator.pushNamed(context, '/solicitudes');
            },
          ),
        ],
      ),
      body: _cuerpoActual(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: _onTabTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Grupos',
          ),
        ],
      ),
    );
  }
}
