import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<dynamic> _games = []; // Lista para armazenar os jogos
  String _searchQuery = ""; // Texto da barra de busca

  @override
  void initState() {
    super.initState();
    _fetchGames(); // Buscar os jogos ao iniciar
  }

  // Função para buscar os jogos da API do Twitch
  Future<void> _fetchGames({String query = ""}) async {
    const clientId =
        'c4a91l5b2h3v7jfmnmmbnvusg00hps'; // Substitua pelo seu Client ID
    const clientSecret =
        'l0vxlxsnkwrzrtxjt4zttfjddrz6fx'; // Substitua pelo seu Client Secret

    // Obter o token de acesso
    final tokenResponse = await http.post(
      Uri.parse('https://id.twitch.tv/oauth2/token'),
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'client_credentials',
      },
    );

    final tokenData = json.decode(tokenResponse.body);
    final accessToken = tokenData['access_token'];

    // Buscar os jogos com base na consulta (query)
    final url = query.isEmpty
        ? 'https://api.twitch.tv/helix/games/top'
        : 'https://api.twitch.tv/helix/search/categories?query=$query';

    final gamesResponse = await http.get(
      Uri.parse(url),
      headers: {'Client-ID': clientId, 'Authorization': 'Bearer $accessToken'},
    );

    final gamesData = json.decode(gamesResponse.body);
    setState(() {
      _games = gamesData['data']; // Armazenar os jogos na lista
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Título do aplicativo
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              'GAMER LETTERBOX',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF107C10), // Verde Xbox
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          // Barra de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onSubmitted: (value) {
                _fetchGames(query: value); // Buscar jogos com base na pesquisa
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800], // Cinza escuro
                hintText: 'Buscar jogos...',
                hintStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          // Grade de jogos
          Expanded(child: _buildGamesGrid()),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF107C10), // Verde Xbox
        ),
        child: BottomNavigationBar(
          selectedItemColor: Colors.white, // Cor do texto e ícones selecionados
          unselectedItemColor:
              Colors.black, // Cor do texto e ícones não selecionados
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Busca'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: 'Estante',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          ],
        ),
      ),
    );
  }

  // Widget para exibir a grade de jogos
  Widget _buildGamesGrid() {
    if (_games.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF107C10),
        ), // Indicador de carregamento
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 jogos por linha
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];
        final imageUrl = game['box_art_url']
            .replaceAll('{width}', '200')
            .replaceAll('{height}', '300'); // Substituir placeholders no URL

        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(imageUrl, fit: BoxFit.cover),
        );
      },
    );
  }
}
