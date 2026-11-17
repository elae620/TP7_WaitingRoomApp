import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'waiting_room_app.dart';
import 'local_database_factory.dart';
import 'providers/auth_provider.dart';

/// Point d'entrée de l'application **Waiting Room App** (TP5 Flutter).
///
/// Séquence d'initialisation :
/// 1. Charge les variables d'environnement depuis `.env`
///    ([SUPABASE_URL] et [SUPABASE_ANON_KEY])
/// 2. Initialise le client Supabase
/// 3. Initialise l'état de la session utilisateur
/// 4. Monte l'arbre de widgets avec [ChangeNotifierProvider] / [AuthProvider]
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeLocalDatabaseFactory();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(Supabase.instance.client)..initialize(),
      child: const WaitingRoomApp(),
    ),
  );
}
