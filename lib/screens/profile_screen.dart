import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  String? username;
  String? avatarUrl;
  List<Map<String, dynamic>> reviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      // 👤 perfil
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      // 📝 reviews
      final response = await supabase
          .from('reviews')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      setState(() {
        username = profile['username'];
        avatarUrl = profile['avatar_url'];
        reviews = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      debugPrint('ERRO PROFILE SCREEN: $e');
      setState(() => loading = false);
    }
  }

  String formatDate(String? date) {
    if (date == null) return '';
    final d = DateTime.parse(date).toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget buildHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: avatarUrl != null
              ? NetworkImage('${avatarUrl!}?t=${DateTime.now().millisecondsSinceEpoch}')
              : const NetworkImage('https://i.imgur.com/3fJ1P4b.png'),
        ),
        const SizedBox(height: 12),
        Text(
          username ?? 'Usuário',
          style: const TextStyle(
            color: Color(0xFF39FF14),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildReview(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0).toInt();

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          review['title'] ?? '',
          style: const TextStyle(color: Color(0xFF39FF14)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                rating,
                (i) => const Icon(Icons.star,
                    color: Color(0xFF39FF14), size: 16),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              review['body'] ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              formatDate(review['created_at']),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF39FF14)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFF39FF14),
        title: const Text('Perfil'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          buildHeader(),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Reviews',
              style: TextStyle(
                color: Color(0xFF39FF14),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          if (reviews.isEmpty)
            const Center(
              child: Text(
                'Nenhum review ainda.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ...reviews.map(buildReview),
        ],
      ),
    );
  }
}