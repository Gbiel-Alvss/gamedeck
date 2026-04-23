import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'game_details_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _popularGames = [];
  List<dynamic> _searchResults = [];

  bool _loadingPopular = false;
  bool _loadingSearch = false;

  static const String clientId = 'jgdf20fd7qeohlw4mn88flmgjoj3et';
  static const String clientSecret = 'ci7xu7t5icdzot1lh0ogu6fotzq0b2';

  @override
  void initState() {
    super.initState();
    fetchPopularGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🔑 TOKEN TWITCH
  Future<String?> _getTwitchAccessToken() async {
    try {
      final tokenResponse = await http.post(
        Uri.parse('https://id.twitch.tv/oauth2/token'),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'client_credentials',
        },
      );

      if (tokenResponse.statusCode != 200) {
        debugPrint('TOKEN ERROR: ${tokenResponse.body}');
        return null;
      }

      final tokenData = json.decode(tokenResponse.body);
      return tokenData['access_token'];
    } catch (e) {
      debugPrint('TOKEN ERROR: $e');
      return null;
    }
  }

  // 🎮 TWITCH IMAGE (EM ALTA)
  String _formatTwitchImageUrl(String rawUrl) {
    return rawUrl
        .replaceAll('{width}', '600')
        .replaceAll('{height}', '800');
  }

  // 🎮 IGDB IMAGE (BUSCA)
  String _formatIGDBImage(String url) {
    return 'https:${url.replaceAll('t_thumb', 't_cover_big')}';
  }

  // 🔥 JOGOS POPULARES (TWITCH)
  Future<void> fetchPopularGames() async {
    setState(() => _loadingPopular = true);

    try {
      final token = await _getTwitchAccessToken();
      if (token == null) throw Exception('Erro no token');

      final response = await http.get(
        Uri.parse('https://api.twitch.tv/helix/games/top'),
        headers: {
          'Client-ID': clientId,
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      setState(() {
        _popularGames = data['data'] ?? [];
      });
    } catch (e) {
      debugPrint('ERRO POPULAR: $e');
    } finally {
      setState(() => _loadingPopular = false);
    }
  }

  // 🔎 BUSCA IGDB
  Future<List<dynamic>> fetchGamesFromIGDB(String query) async {
    final token = await _getTwitchAccessToken();

    final response = await http.post(
      Uri.parse('https://api.igdb.com/v4/games'),
      headers: {
        'Client-ID': clientId,
        'Authorization': 'Bearer $token',
        'Content-Type': 'text/plain',
      },
      body: '''
        search "$query";
        fields id, name, cover.url;
        limit 30;
      ''',
    );

    if (response.statusCode != 200) {
      debugPrint(response.body);
      return [];
    }

    return json.decode(response.body);
  }

  Future<void> searchGames(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _loadingSearch = true);

    try {
      final data = await fetchGamesFromIGDB(query);

      setState(() {
        _searchResults = data;
      });
    } catch (e) {
      debugPrint('ERRO SEARCH: $e');
    } finally {
      setState(() => _loadingSearch = false);
    }
  }

  // 🎮 GRID
  Widget _buildGameGrid({
    required List<dynamic> games,
    required bool loading,
    required String emptyText,
  }) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF39FF14)),
        ),
      );
    }

    if (games.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final game = games[index];

        String imageUrl = '';
        int gameId = 0;
        String gameTitle = '';

        // 🔥 IGDB (busca)
        if (game['cover'] != null) {
          imageUrl = _formatIGDBImage(game['cover']['url']);
          gameId = game['id'];
          gameTitle = game['name'] ?? 'Sem nome';
        }
        // 🎮 TWITCH (em alta)
        else {
          final rawImage = (game['box_art_url'] ?? '').toString();
          imageUrl = rawImage.isNotEmpty
              ? _formatTwitchImageUrl(rawImage)
              : '';

          gameId = int.tryParse(game['id'].toString()) ?? 0;
          gameTitle = game['name'] ?? 'Sem nome';
        }

        return GestureDetector(
          onTap: () {
            if (gameId == 0) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailsScreen(
                  gameId: gameId,
                  gameTitle: gameTitle,
                  imageUrl: imageUrl,
                ),
              ),
            );
          },
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          )
                        : const Icon(
                            Icons.videogame_asset,
                            color: Colors.white54,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                gameTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showingSearch = _searchController.text.trim().isNotEmpty;

    return ListView(
      children: [
        const SizedBox(height: 16),

        const Center(
          child: Column(
            children: [
              Text(
                'PLAYBOXED',
                style: TextStyle(
                  color: Color(0xFF39FF14),
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              SizedBox(height: 8),
              Icon(Icons.search, color: Color(0xFF39FF14), size: 40),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onSubmitted: searchGames,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900],
              hintText: 'Buscar jogos...',
              hintStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF39FF14)),
            ),
          ),
        ),

        if (showingSearch) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Resultados da pesquisa',
              style: TextStyle(
                color: Color(0xFF39FF14),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          _buildGameGrid(
            games: _searchResults,
            loading: _loadingSearch,
            emptyText: 'Nenhum resultado encontrado.',
          ),
        ] else ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Em alta agora',
              style: TextStyle(
                color: Color(0xFF39FF14),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          _buildGameGrid(
            games: _popularGames,
            loading: _loadingPopular,
            emptyText: 'Nenhum jogo encontrado.',
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}