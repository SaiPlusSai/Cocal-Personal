import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BarraNavegacion extends StatelessWidget {
  final int indice;
  final Function(int) onTap;

  const BarraNavegacion({
    super.key,
    required this.indice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: indice,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.indigo,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.calendarDays),
          label: 'Calendario',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.users),
          label: 'Grupos',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.comments),
          label: 'Foro',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.user),
          label: 'Perfil',
        ),
      ],
    );
  }
}
