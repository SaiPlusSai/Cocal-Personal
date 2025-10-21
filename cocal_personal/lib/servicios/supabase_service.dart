import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const url = 'https://TU_URL_SUPABASE.supabase.co';
  static const anonKey = 'TU_ANON_KEY';

  static Future<void> inicializar() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get cliente => Supabase.instance.client;
}
