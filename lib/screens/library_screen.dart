import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final supabase = Supabase.instance.client;

  List<dynamic> games = [];
  bool isLoading = true;

  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('user_games')
        .select()
        .eq('user_id', user.id);

    setState(() {
      games = response;
      isLoading = false;
    });
  }

  // 🔥 FILTRO
  List<dynamic> get filteredGames {
    if (selectedFilter == 'all') return games;

    return games
        .where((game) => game['status'] == selectedFilter)
        .toList();
  }

  // 🔥 PEGAR NOME CORRETO
  String getGameName(Map game) {
    return game['name'] ??
        game['title'] ??
        game['game_name'] ??
        'Sem nome';
  }

  // 🎨 BOTÃO DE FILTRO
  Widget _buildFilter(String label, String value) {
    final isSelected = selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF39FF14) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF39FF14)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 🎮 CARD DO JOGO
  Widget buildGameCard(Map game) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 🎮 CAPA
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              game['image_url'] ?? '',
              width: 60,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 80,
                color: Colors.grey[800],
                child: const Icon(Icons.videogame_asset,
                    color: Colors.white),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 📝 NOME
          Expanded(
            child: Text(
              getGameName(game),
              style: const TextStyle(
                color: Color(0xFF39FF14),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ⚙️ MENU STATUS
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              updateStatus(game['id'], value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'playing',
                child: Text('Jogando'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Concluído'),
              ),
              const PopupMenuItem(
                value: 'dropped',
                child: Text('Abandonado'),
              ),
            ],
          )
        ],
      ),
    );
  }

  // 🔄 ATUALIZAR STATUS
  Future<void> updateStatus(String id, String status) async {
    await supabase
        .from('user_games')
        .update({'status': status})
        .eq('id', id);

    fetchGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),

                // 🔥 TÍTULO
                const Text(
                  'PLAYBOXED',
                  style: TextStyle(
                    color: Color(0xFF39FF14),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // 🎯 FILTROS (SEM BACKLOG)
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilter('Todos', 'all'),
                      _buildFilter('Jogando', 'playing'),
                      _buildFilter('Concluído', 'completed'),
                      _buildFilter('Abandonado', 'dropped'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 📋 LISTA DE JOGOS
                Expanded(
                  child: filteredGames.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum jogo encontrado',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredGames.length,
                          itemBuilder: (context, index) {
                            return buildGameCard(filteredGames[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}