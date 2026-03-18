import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://islqrkomemcrvegbgdsi.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_e05eatpM8jfSkA362ca7xQ_upmTLkLK';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
