import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../providers/auth_provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isSubmitting = false;
  bool _canResendConfirmation = false;
  String? _message;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _message = null;
      _error = null;
      _canResendConfirmation = false;
    });

    try {
      final auth = context.read<AuthProvider>();
      if (_isRegistering) {
        final emailVerificationRequired = await auth.signUp(
          _emailController.text,
          _passwordController.text,
        );
        if (emailVerificationRequired && mounted) {
          setState(() {
            _message =
                'Compte créé. Vérifiez votre adresse e-mail, puis '
                'attendez la validation par un administrateur.';
            _isRegistering = false;
          });
        }
      } else {
        await auth.signIn(_emailController.text, _passwordController.text);
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _canResendConfirmation = error.code == 'email_not_confirmed';
          _error = _canResendConfirmation
              ? 'Votre adresse e-mail n’a pas encore été confirmée. Ouvrez '
                    'le lien reçu par e-mail ou demandez un nouvel envoi.'
              : error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        final details = error.toString().toLowerCase();
        final isDnsError =
            details.contains('failed host lookup') ||
            details.contains('no address associated with hostname');
        setState(
          () => _error = isDnsError
              ? 'Le serveur Supabase est introuvable. Vérifiez SUPABASE_URL '
                    'dans .env et la connexion Internet, puis relancez '
                    'l’application.'
              : 'Opération impossible : $error',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Saisissez une adresse e-mail valide.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _message = null;
    });
    try {
      await context.read<AuthProvider>().resendSignupConfirmation(email);
      if (mounted) {
        setState(
          () => _message =
              'Un nouveau lien de confirmation a été envoyé à $email.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Envoi impossible : $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.meeting_room, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _isRegistering ? 'Créer un compte' : 'Connexion',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Adresse e-mail',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Saisissez une adresse e-mail valide.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'Le mot de passe doit contenir au moins '
                                '6 caractères.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        if (_canResendConfirmation) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : _resendConfirmation,
                              icon: const Icon(Icons.mark_email_unread),
                              label: const Text(
                                'Renvoyer le lien de confirmation',
                              ),
                            ),
                          ),
                        ],
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _message!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isRegistering ? 'Créer mon compte' : 'Entrer',
                              ),
                      ),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() {
                                _isRegistering = !_isRegistering;
                                _error = null;
                                _message = null;
                              }),
                        child: Text(
                          _isRegistering
                              ? 'J’ai déjà un compte'
                              : 'Créer un compte',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountStatusPage extends StatelessWidget {
  const AccountStatusPage({required this.pending, super.key});

  final bool pending;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return _StatusScaffold(
      icon: pending ? Icons.hourglass_top : Icons.block,
      title: pending ? 'Compte en attente' : 'Compte refusé',
      message: pending
          ? 'Votre compte doit être validé par un administrateur avant '
                'd’accéder à la file d’attente.'
          : 'Votre demande d’accès a été refusée. Contactez un administrateur '
                'si vous pensez qu’il s’agit d’une erreur.',
      actions: [
        if (pending)
          OutlinedButton.icon(
            onPressed: auth.refreshProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Vérifier le statut'),
          ),
        TextButton.icon(
          onPressed: auth.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
        ),
      ],
    );
  }
}

class ProfileErrorPage extends StatelessWidget {
  const ProfileErrorPage({required this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return _StatusScaffold(
      icon: Icons.error_outline,
      title: 'Profil indisponible',
      message: message ?? 'Impossible de charger votre profil.',
      actions: [
        FilledButton.icon(
          onPressed: auth.refreshProfile,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
        TextButton(
          onPressed: auth.signOut,
          child: const Text('Se déconnecter'),
        ),
      ],
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late Future<List<UserProfile>> _pendingProfiles;
  String? _updatingId;

  @override
  void initState() {
    super.initState();
    _pendingProfiles = _loadPendingProfiles();
  }

  Future<List<UserProfile>> _loadPendingProfiles() async {
    final rows = await Supabase.instance.client
        .from('profiles')
        .select('id,email,role,status,created_at')
        .eq('status', 'pending')
        .order('created_at');
    return rows.map((row) => UserProfile.fromMap(row)).toList();
  }

  Future<void> _setApproval(UserProfile profile, String status) async {
    setState(() => _updatingId = profile.id);
    try {
      final updated = await Supabase.instance.client
          .from('profiles')
          .update({'status': status})
          .eq('id', profile.id)
          .eq('status', 'pending')
          .select('id');
      if (updated.isEmpty) {
        throw StateError('Ce compte a déjà été traité.');
      }
      if (!mounted) return;
      setState(() {
        _pendingProfiles = _loadPendingProfiles();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved' ? 'Compte approuvé.' : 'Demande refusée.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de modifier ce compte : $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de compte')),
      body: FutureBuilder<List<UserProfile>>(
        future: _pendingProfiles,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger les demandes.'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _pendingProfiles = _loadPendingProfiles();
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profiles = snapshot.data!;
          if (profiles.isEmpty) {
            return const Center(child: Text('Aucune demande en attente.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final isUpdating = _updatingId == profile.id;
              return Card(
                child: ListTile(
                  title: Text(profile.email ?? 'Adresse e-mail inconnue'),
                  subtitle: Text(
                    'Demande du ${profile.createdAt.toLocal().toString().split('.').first}',
                  ),
                  trailing: isUpdating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Approuver',
                              onPressed: () =>
                                  _setApproval(profile, 'approved'),
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refuser',
                              onPressed: () =>
                                  _setApproval(profile, 'rejected'),
                              icon: const Icon(Icons.cancel, color: Colors.red),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
