import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;

  String? username;
  String? avatarUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  // 🔄 BUSCAR PERFIL
  Future<void> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      setState(() {
        username = response['username'];
        avatarUrl = response['avatar_url'];
      });
    } catch (e) {
      debugPrint('ERRO PROFILE: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // 🚪 LOGOUT
  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Sair da conta',
          style: TextStyle(color: Color(0xFF39FF14)),
        ),
        content: const Text(
          'Você tem certeza que deseja sair?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // 👤 HEADER DO PERFIL
  Widget buildProfile() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39FF14)),
      );
    }

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : const NetworkImage(
                      'https://i.imgur.com/3fJ1P4b.png'),
            ),

            // ✏️ BOTÃO EDITAR
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        currentUsername: username ?? '',
                        currentAvatar: avatarUrl,
                      ),
                    ),
                  );

                  if (updated == true) {
                    fetchProfile(); // 🔄 atualiza após edição
                  }
                },
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF39FF14),
                  child: Icon(Icons.edit, size: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          username ?? 'Usuário',
          style: const TextStyle(
            color: Color(0xFF39FF14),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ⚙️ OPÇÃO (REUTILIZÁVEL)
  Widget buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF39FF14)),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFF39FF14),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // 👤 PERFIL
          buildProfile(),

          const SizedBox(height: 30),

          const Divider(color: Colors.white24),

          // 🚪 LOGOUT
          buildOption(
            icon: Icons.logout,
            title: 'Sair da conta',
            color: Colors.redAccent,
            onTap: logout,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}