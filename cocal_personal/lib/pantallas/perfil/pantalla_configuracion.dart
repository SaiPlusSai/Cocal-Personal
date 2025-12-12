import 'package:cocal_personal/proveedores/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  bool notificaciones = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final headerColor = themeProvider.accentColor;

    return Scaffold(
      appBar: AppBar(title: Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: notificaciones,
            title: const Text('Notificaciones'),
            onChanged: (v) {
              setState(() => notificaciones = v);
            },
          ),
          // Light Theme Option
          _buildThemeOption(
            context,
            title: "Tema claro",
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (val) => themeProvider.setThemeMode(val!),
          ),

          // Dark Theme Option
          _buildThemeOption(
            context,
            title: "Tema oscuro",
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (val) => themeProvider.setThemeMode(val!),
          ),

          const SizedBox(height: 20),

          // Accent Color Picker Tile
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Color"),
            trailing: CircleAvatar(
              backgroundColor: themeProvider.accentColor,
              radius: 15,
            ),
            onTap: () {
              _showColorPickerDialog(context, themeProvider);
            },
          ),

          const Divider(height: 30),

          // --- TYPOGRAPHY ---
          Text("Tipografía", style: _headerStyle(headerColor)),
          const SizedBox(height: 10),

          // Font Family Dropdown
          ListTile(
            title: const Text("Fuente"),
            trailing: DropdownButton<String>(
              value: themeProvider.fontFamily,
              underline: const SizedBox(),
              items: themeProvider.availableFonts.map((String font) {
                return DropdownMenuItem<String>(
                  value: font,
                  child: Text(font, style: TextStyle(fontFamily: font)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  themeProvider.setFontFamily(newValue);
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action to save or go back
          Navigator.of(context).pop();
        },
        backgroundColor: themeProvider.accentColor,
        child: const Icon(Icons.check, color: Colors.black),
      ),
    );
  }

  // Helper to build Radio Tiles
  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required ThemeMode value,
    required ThemeMode groupValue,
    required Function(ThemeMode?) onChanged,
  }) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: Provider.of<ThemeProvider>(context).accentColor,
    );
  }

  // The Color Picker Dialog (Screenshot 2)
  void _showColorPickerDialog(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Accent color"),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 columns like the image
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: provider.availableColors.length,
              itemBuilder: (ctx, index) {
                final color = provider.availableColors[index];
                return GestureDetector(
                  onTap: () {
                    provider.setAccentColor(color);
                    Navigator.of(ctx).pop();
                  },
                  child: CircleAvatar(
                    backgroundColor: color,
                    child: provider.accentColor == color
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(color: provider.accentColor),
              ),
            ),
          ],
        );
      },
    );
  }

  TextStyle _headerStyle(Color color) {
    return TextStyle(
      color: color,
      fontWeight: FontWeight.bold,
      fontSize: 14,
      letterSpacing: 1.0,
    );
  }

  String _getFontSizeLabel(double factor) {
    if (factor <= 0.8) return "Small";
    if (factor == 1.0) return "Normal";
    if (factor == 1.2) return "Large";
    return "Extra Large";
  }
}
