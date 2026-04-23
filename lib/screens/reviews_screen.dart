import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({Key? key}) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> reviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      final response = await supabase
          .from('reviews')
          .select('*, profiles(username, avatar_url)')
          .order('created_at', ascending: false);

      setState(() {
        reviews = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      debugPrint('ERRO REVIEWS: $e');
      setState(() => loading = false);
    }
  }

  String formatDate(String? date) {
    if (date == null) return '';
    final d = DateTime.parse(date).toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget buildStars(int count) {
    return Row(
      children: List.generate(
        count,
        (i) => const Icon(Icons.star,
            color: Color(0xFF39FF14), size: 16),
      ),
    );
  }

  Widget buildReview(Map<String, dynamic> review) {
    final profile = review['profiles'];
    final username = profile?['username'] ?? 'Usuário';
    final avatar = profile?['avatar_url'];

    final rating = (review['rating'] ?? 0).toInt();

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 HEADER (avatar + username)
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avatar != null
                      ? NetworkImage(
                          '${avatar}?t=${DateTime.now().millisecondsSinceEpoch}')
                      : const NetworkImage(
                          'https://i.imgur.com/3fJ1P4b.png'),
                ),
                const SizedBox(width: 10),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                          userId: review['user_id'],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    username,
                    style: const TextStyle(
                      color: Color(0xFF39FF14),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🎮 NOME DO JOGO
            Text(
              review['title'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // ⭐ ESTRELAS
            buildStars(rating),

            const SizedBox(height: 8),

            // 📝 TEXTO
            Text(
              review['body'] ?? '',
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 8),

            // 📅 DATA
            Text(
              formatDate(review['created_at']),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
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

    if (reviews.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Nenhum review ainda.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        children: reviews.map(buildReview).toList(),
      ),
    );
  }
}