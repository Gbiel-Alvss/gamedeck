import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameDetailsScreen extends StatefulWidget {
  final int gameId;
  final String gameTitle;
  final String imageUrl;

  const GameDetailsScreen({
    Key? key,
    required this.gameId,
    required this.gameTitle,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final supabase = Supabase.instance.client;

  bool _loadingReviews = true;
  bool _savingAction = false;

  List<Map<String, dynamic>> _communityReviews = [];
  Map<String, String> _usernamesById = {};

  @override
  void initState() {
    super.initState();
    fetchCommunityReviews();
  }

  Future<void> fetchCommunityReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      final reviewsResponse = await supabase
          .from('reviews')
          .select()
          .eq('igdb_game_id', widget.gameId)
          .order('created_at', ascending: false);

      final reviews =
          List<Map<String, dynamic>>.from(reviewsResponse);

      final userIds = reviews
          .map((review) => review['user_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      Map<String, String> usernames = {};

      if (userIds.isNotEmpty) {
        final profilesResponse = await supabase
            .from('profiles')
            .select('id, username')
            .inFilter('id', userIds);

        for (final item in profilesResponse) {
          final map = Map<String, dynamic>.from(item);
          usernames[map['id'].toString()] =
              (map['username'] ?? 'usuário').toString();
        }
      }

      if (!mounted) return;

      setState(() {
        _communityReviews = reviews;
        _usernamesById = usernames;
      });
    } catch (e) {
      debugPrint('ERRO COMMUNITY REVIEWS: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar reviews: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingReviews = false;
        });
      }
    }
  }

  Future<void> addGameToLibrary(String status) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado.')),
      );
      return;
    }

    setState(() {
      _savingAction = true;
    });

    try {
      await supabase.from('user_games').upsert(
        {
          'user_id': user.id,
          'igdb_game_id': widget.gameId,
          'status': status,
          'game_name': widget.gameTitle,
          'image_url': widget.imageUrl,
        },
        onConflict: 'user_id,igdb_game_id',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'playing'
                ? 'Jogo adicionado em Jogando agora!'
                : 'Jogo adicionado ao backlog!',
          ),
        ),
      );
    } catch (e) {
      debugPrint('ERRO ADD GAME DETAILS: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar jogo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingAction = false;
        });
      }
    }
  }

  Future<void> saveReview({
    required int stars,
    required String reviewText,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado.')),
      );
      return;
    }

    setState(() {
      _savingAction = true;
    });

    try {
      await supabase.from('reviews').upsert(
        {
          'user_id': user.id,
          'igdb_game_id': widget.gameId,
          'title': widget.gameTitle,
          'body': reviewText,
          'rating': stars.toDouble(),
        },
        onConflict: 'user_id,igdb_game_id',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review salvo com sucesso!')),
      );

      await fetchCommunityReviews();
    } catch (e) {
      debugPrint('ERRO SAVE REVIEW DETAILS: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar review: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingAction = false;
        });
      }
    }
  }

  void openReviewDialog() {
    final TextEditingController reviewController = TextEditingController();
    final ValueNotifier<int> starsNotifier = ValueNotifier<int>(0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Review de ${widget.gameTitle}',
            style: const TextStyle(color: Color(0xFF39FF14)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 150,
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ValueListenableBuilder<int>(
                  valueListenable: starsNotifier,
                  builder: (context, stars, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return IconButton(
                          icon: Icon(
                            i < stars ? Icons.star : Icons.star_border,
                            color: const Color(0xFF39FF14),
                          ),
                          onPressed: () {
                            starsNotifier.value = i + 1;
                          },
                        );
                      }),
                    );
                  },
                ),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Escreva seu review...',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.black,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
              ),
              onPressed: () async {
                if (starsNotifier.value == 0 ||
                    reviewController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecione estrelas e escreva o review.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                await saveReview(
                  stars: starsNotifier.value,
                  reviewText: reviewController.text.trim(),
                );
              },
              child: const Text(
                'Salvar',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  String formatDate(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    } catch (_) {
      return '';
    }
  }

  Widget buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF39FF14),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _savingAction ? null : onTap,
        icon: Icon(icon),
        label: Text(
          label,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget buildReviewCard(Map<String, dynamic> review) {
    final rating = ((review['rating'] ?? 0) as num).toInt();
    final userId = review['user_id']?.toString() ?? '';
    final username = _usernamesById[userId] ?? 'usuário';
    final createdAt = formatDate(review['created_at']);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@$username',
              style: const TextStyle(
                color: Color(0xFF39FF14),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                createdAt,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                rating,
                (i) => const Icon(
                  Icons.star,
                  color: Color(0xFF39FF14),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              (review['body'] ?? '').toString(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final averageRating = _communityReviews.isEmpty
        ? null
        : _communityReviews
                .map((e) => (e['rating'] ?? 0) as num)
                .reduce((a, b) => a + b) /
            _communityReviews.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFF39FF14),
        elevation: 0,
        title: const Text('Detalhes do jogo'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 180,
                height: 260,
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.videogame_asset,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.gameTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF39FF14),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          if (averageRating != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Média da comunidade: ${averageRating.toStringAsFixed(1)} ★',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                buildActionButton(
                  icon: Icons.play_arrow,
                  label: 'Jogando agora',
                  onTap: () => addGameToLibrary('playing'),
                ),
                const SizedBox(width: 10),
                buildActionButton(
                  icon: Icons.bookmark,
                  label: 'Backlog',
                  onTap: () => addGameToLibrary('backlog'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _savingAction ? null : openReviewDialog,
              icon: const Icon(Icons.rate_review),
              label: const Text('Escrever review'),
            ),
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Reviews da comunidade',
              style: TextStyle(
                color: Color(0xFF39FF14),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingReviews)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF39FF14)),
              ),
            )
          else if (_communityReviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Ainda não há reviews para este jogo.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ..._communityReviews.map(buildReviewCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}