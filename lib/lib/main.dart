import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'theme.dart';
import 'audio_controller.dart';

void main() {
  runApp(const ProviderScope(child: DualityApp()));
}

class DualityApp extends ConsumerWidget {
  const DualityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Duality Music',
      debugShowCheckedModeBanner: false,
      theme: activeTheme == AppThemeMode.dualityDark
          ? DualityThemes.dualityDark
          : DualityThemes.angelicLight,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(audioControllerProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            themeMode == AppThemeMode.dualityDark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 34,
              width: 34,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.music_note, size: 30),
            ),
            const SizedBox(width: 10),
            const Text(
              'DUALITY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) => controller.setSortOption(option),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.name,
                child: Text('Ordenar por Nome'),
              ),
              const PopupMenuItem(
                value: SortOption.date,
                child: Text('Ordenar por Data'),
              ),
              const PopupMenuItem(
                value: SortOption.size,
                child: Text('Ordenar por Tamanho'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Criar Playlist',
            onPressed: () => _showCreatePlaylistDialog(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Importar do YouTube',
            onPressed: () => _showImportDialog(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => controller.searchSongs(val),
              decoration: InputDecoration(
                hintText: 'Pesquisar músicas ou artistas...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: controller.songs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 80,
                          width: 80,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.music_off, size: 64, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Nenhuma música encontrada.",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Verifica as permissões de armazenamento do telemóvel.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: controller.songs.length,
                    itemBuilder: (context, index) {
                      final song = controller.songs[index];
                      final isSelected = controller.currentSong?.id == song.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.15),
                        leading: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          artworkBorder: BorderRadius.circular(8.0),
                          nullArtworkWidget: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          "${song.artist ?? 'Artista Desconhecido'} • ${(song.size / (1024 * 1024)).toStringAsFixed(1)} MB",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showAddToPlaylistMenu(context, controller, song),
                        ),
                        onTap: () => controller.playSong(song),
                      );
                    },
                  ),
          ),
          if (controller.currentSong != null) const MiniPlayer(),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, AudioController controller) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Playlist'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Nome da playlist'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                controller.createPlaylist(textController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistMenu(BuildContext context, AudioController controller, SongModel song) {
    if (controller.playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cria primeiro uma playlist para adicionar músicas.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: controller.playlists.keys.map((name) {
          return ListTile(
            leading: const Icon(Icons.playlist_add_check),
            title: Text(name),
            onTap: () {
              controller.addToPlaylist(name, song);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Adicionado a $name')),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  void _showImportDialog(BuildContext context, AudioController controller) {
    final urlController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar Playlist do YouTube'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Nome da Nova Playlist'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(hintText: 'URL da Playlist do YouTube'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              final name = nameController.text.trim();
              if (url.isNotEmpty && name.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A analisar playlist...')),
                );
                final count = await controller.importYouTubePlaylist(url, name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count músicas locais correspondidas e adicionadas!')),
                  );
                }
              }
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(audioControllerProvider);
    final song = controller.currentSong;

    if (song == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          QueryArtworkWidget(
            id: song.id,
            type: ArtworkType.AUDIO,
            artworkWidth: 50,
            artworkHeight: 50,
            artworkBorder: BorderRadius.circular(6.0),
            nullArtworkWidget: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Image.asset(
                'assets/logo.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: Theme.of(context).primaryColor,
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  song.artist ?? 'Artista Desconhecido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              controller.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            ),
            iconSize: 42,
            color: Theme.of(context).colorScheme.secondary,
            onPressed: () => controller.togglePlayPause(),
          ),
        ],
      ),
    );
  }
}