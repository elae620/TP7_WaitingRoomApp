import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../queue_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../services/connectivity_service.dart';
import '../waiting_room_app.dart';
import 'authentication_pages.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return switch (auth.status) {
          AuthStatus.loading => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          AuthStatus.signedOut => const SignInPage(),
          AuthStatus.pending => const AccountStatusPage(pending: true),
          AuthStatus.rejected => const AccountStatusPage(pending: false),
          AuthStatus.approved => const AuthenticatedWaitingRoom(),
          AuthStatus.error => ProfileErrorPage(message: auth.profileError),
        };
      },
    );
  }
}

class AuthenticatedWaitingRoom extends StatelessWidget {
  const AuthenticatedWaitingRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QueueProvider()..initialize()),
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(
            ConnectivityService(Supabase.instance.client),
          )..initialize(),
        ),
      ],
      child: const WaitingRoomPage(),
    );
  }
}
