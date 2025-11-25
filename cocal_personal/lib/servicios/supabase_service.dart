import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const url = 'https://zlpigthjcwywimqeykib.supabase.co';
  static const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpscGlndGhqY3d5d2ltcWV5a2liIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNTcyMzMsImV4cCI6MjA3NjYzMzIzM30.M04CSRPDKQVHIerk8nBPiywcLLAfdoGD9AtMTDHVYVo';

  static Future<void> inicializar() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true,
    );
  }

  static SupabaseClient get cliente => Supabase.instance.client;
}
